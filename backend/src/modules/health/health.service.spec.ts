import { ConfigService } from '@nestjs/config';
import { Pool } from 'pg';
import Redis from 'ioredis';
import { HealthService } from './health.service';
import { HealthController } from './health.controller';

jest.mock('pg');
jest.mock('ioredis');

describe('dependency readiness', () => {
  let service: HealthService;
  let query: jest.Mock;
  let ping: jest.Mock;

  beforeEach(() => {
    query = jest.fn().mockResolvedValue({ rows: [{ '?column?': 1 }] });
    ping = jest.fn().mockResolvedValue('PONG');
    (Pool as unknown as jest.Mock).mockImplementation(() => ({
      query,
      on: jest.fn(),
      end: jest.fn(),
    }));
    (Redis as unknown as jest.Mock).mockImplementation(() => ({
      status: 'ready',
      ping,
      on: jest.fn(),
      disconnect: jest.fn(),
    }));
    service = new HealthService(
      new ConfigService({ NODE_ENV: 'test', DB_PASSWORD: 'test' }),
    );
  });

  it('requires both PostgreSQL and Redis', async () => {
    await expect(new HealthController(service).ready()).resolves.toEqual({
      status: 'ready',
      checks: { database: 'up', redis: 'up' },
    });
    expect(query).toHaveBeenCalledWith('SELECT 1');
    expect(ping).toHaveBeenCalled();
  });

  it.each(['database', 'redis'])(
    'returns 503 for %s failure without leaking diagnostics',
    async (dependency) => {
      (dependency === 'database' ? query : ping).mockRejectedValue(
        new Error('secret connection details'),
      );
      try {
        await new HealthController(service).ready();
        throw new Error('Expected readiness failure');
      } catch (error) {
        expect(error.getStatus()).toBe(503);
        expect(JSON.stringify(error.getResponse())).not.toContain('secret');
        expect(error.getResponse().checks[dependency]).toBe('down');
      }
    },
  );

  it('coalesces concurrent checks', async () => {
    await Promise.all([service.check(), service.check(), service.check()]);
    expect(query).toHaveBeenCalledTimes(1);
    expect(ping).toHaveBeenCalledTimes(1);
  });
});
