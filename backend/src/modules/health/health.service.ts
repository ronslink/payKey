import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Pool } from 'pg';
import Redis from 'ioredis';
import { getDatabaseConnection } from '../../config/database-connection';

@Injectable()
export class HealthService implements OnModuleDestroy {
  private readonly database: Pool;
  private readonly redis: Redis;
  private pending?: Promise<{ status: string; checks: Record<string, string> }>;

  constructor(config: ConfigService) {
    const connection = getDatabaseConnection((key) => config.get<string>(key));
    this.database = new Pool({
      host: connection.host,
      port: connection.port,
      user: connection.username,
      password: connection.password,
      database: connection.database,
      ssl: connection.ssl,
      max: 1,
      connectionTimeoutMillis: 2500,
      idleTimeoutMillis: 10000,
      statement_timeout: 2500,
      query_timeout: 3000,
      application_name: 'paykey-readiness',
    });
    this.database.on('error', () => {});
    this.redis = new Redis({
      host: config.get<string>('REDIS_HOST') || 'localhost',
      port: Number(config.get<string>('REDIS_PORT') || 6379),
      password: config.get<string>('REDIS_PASSWORD'),
      lazyConnect: true,
      enableOfflineQueue: false,
      connectTimeout: 2500,
      commandTimeout: 2500,
      maxRetriesPerRequest: 0,
      retryStrategy: () => null,
    });
    this.redis.on('error', () => {});
  }

  check() {
    // Concurrent probes share one bounded check rather than filling DB pools.
    this.pending ??= this.checkDependencies().finally(() => {
      this.pending = undefined;
    });
    return this.pending;
  }

  private async checkDependencies() {
    const results = await Promise.allSettled([
      this.database.query('SELECT 1'),
      this.pingRedis(),
    ]);
    const checks = {
      database: results[0].status === 'fulfilled' ? 'up' : 'down',
      redis: results[1].status === 'fulfilled' ? 'up' : 'down',
    };
    return {
      status: Object.values(checks).every((value) => value === 'up')
        ? 'ready'
        : 'not_ready',
      checks,
    };
  }

  private async pingRedis() {
    if (this.redis.status === 'wait' || this.redis.status === 'end')
      await this.redis.connect();
    if ((await this.redis.ping()) !== 'PONG')
      throw new Error('Redis unavailable');
  }

  async onModuleDestroy() {
    this.redis.disconnect();
    await this.database.end();
  }
}
