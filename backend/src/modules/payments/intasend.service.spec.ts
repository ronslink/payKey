import * as crypto from 'crypto';
import { ConfigService } from '@nestjs/config';
import { HttpService } from '@nestjs/axios';
import { IntaSendService } from './intasend.service';

describe('IntaSendService webhook verification', () => {
  const values: Record<string, string> = {
    NODE_ENV: 'test',
    INTASEND_IS_LIVE: 'false',
    INTASEND_PUBLISHABLE_KEY_TEST: 'test-publishable-key',
    INTASEND_SECRET_KEY_TEST: 'test-secret-key',
    INTASEND_WEBHOOK_SECRET: 'webhook-secret-for-test',
    INTASEND_CHALLENGE: 'challenge-for-test',
  };

  const configService = {
    get: jest.fn((key: string) => values[key]),
  } as unknown as ConfigService;

  const service = new IntaSendService(configService, {} as HttpService);

  it('accepts the configured webhook challenge', () => {
    expect(
      service.verifyWebhookSignature(
        '',
        Buffer.from('{}'),
        values.INTASEND_CHALLENGE,
      ),
    ).toBe(true);
  });

  it('rejects an incorrect webhook challenge', () => {
    expect(
      service.verifyWebhookSignature('', Buffer.from('{}'), 'wrong-challenge'),
    ).toBe(false);
  });

  it('accepts a valid HMAC signature', () => {
    const body = Buffer.from('{"state":"COMPLETE"}');
    const signature = crypto
      .createHmac('sha256', values.INTASEND_WEBHOOK_SECRET)
      .update(body)
      .digest('hex');

    expect(service.verifyWebhookSignature(signature, body)).toBe(true);
  });

  it('rejects an invalid HMAC signature', () => {
    expect(
      service.verifyWebhookSignature('invalid-signature', Buffer.from('{}')),
    ).toBe(false);
  });

  it('rejects attacker-computable HMACs when no verification key exists', () => {
    const unconfigured = new IntaSendService(
      new ConfigService({ NODE_ENV: 'test' }),
      {} as HttpService,
    );
    const body = Buffer.from('{}');
    const signature = crypto
      .createHmac('sha256', '')
      .update(body)
      .digest('hex');
    expect(unconfigured.verifyWebhookSignature(signature, body)).toBe(false);
  });

  it('rejects malformed authentication fields without throwing', () => {
    expect(
      service.verifyWebhookSignature('', Buffer.from('{}'), {} as string),
    ).toBe(false);
  });

  it('fails live startup with missing provider credentials', () => {
    expect(
      () =>
        new IntaSendService(
          new ConfigService({ NODE_ENV: 'production' }),
          {} as HttpService,
        ),
    ).toThrow('Live IntaSend credentials');
  });
});
