import { Test } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import request from 'supertest';
import { HealthController } from '../src/modules/health/health.controller';
import { HealthService } from '../src/modules/health/health.service';

describe('Readiness dependencies', () => {
  async function createApp(overrides: Record<string, string> = {}) {
    const module = await Test.createTestingModule({
      controllers: [HealthController],
      providers: [
        HealthService,
        {
          provide: ConfigService,
          useValue: {
            get: (key: string) => overrides[key] ?? process.env[key],
          },
        },
      ],
    }).compile();
    const app = module.createNestApplication();
    await app.init();
    return app;
  }

  it('reports ready only when real PostgreSQL and Redis answer', async () => {
    const app = await createApp();
    try {
      const result = await request(app.getHttpServer())
        .get('/health/ready')
        .expect(200);
      expect(result.body).toEqual({
        status: 'ready',
        checks: { database: 'up', redis: 'up' },
      });
    } finally {
      await app.close();
    }
  });

  it.each([
    [{ DB_PORT: '1' }, { database: 'down', redis: 'up' }],
    [{ REDIS_PORT: '1' }, { database: 'up', redis: 'down' }],
  ])(
    'returns 503 without credentials when a dependency is unavailable (%j)',
    async (overrides, checks) => {
      const app = await createApp(overrides as Record<string, string>);
      try {
        const result = await request(app.getHttpServer())
          .get('/health/ready')
          .expect(503);
        expect(result.body).toEqual({ status: 'not_ready', checks });
        await request(app.getHttpServer()).get('/health').expect(200);
      } finally {
        await app.close();
      }
    },
  );
});
