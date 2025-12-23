import { Module, Global, Logger } from '@nestjs/common';
import { CacheModule } from '@nestjs/cache-manager';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { redisStore } from 'cache-manager-ioredis-yet';

const logger = new Logger('AppCacheModule');

@Global()
@Module({
  imports: [
    CacheModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: async (configService: ConfigService) => {
        const redisHost = configService.get('REDIS_HOST');
        const redisPort = configService.get('REDIS_PORT', '6379');

        // If no REDIS_HOST configured, use in-memory cache
        if (!redisHost) {
          logger.log('Redis not configured, using in-memory cache');
          return {
            ttl: 60 * 1000, // 60 seconds default TTL
          };
        }

        try {
          const store = await redisStore({
            host: redisHost,
            port: parseInt(redisPort, 10),
            password: configService.get('REDIS_PASSWORD'),
            ttl: 60, // seconds
          });

          logger.log(`Connected to Redis at ${redisHost}:${redisPort}`);

          return {
            store,
            ttl: 60 * 1000, // milliseconds for cache-manager
          };
        } catch (error) {
          logger.warn(
            `Failed to connect to Redis: ${error}. Falling back to in-memory cache.`,
          );
          return {
            ttl: 60 * 1000,
          };
        }
      },
    }),
  ],
  exports: [CacheModule],
})
export class AppCacheModule {}
