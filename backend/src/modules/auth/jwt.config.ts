import { ConfigService } from '@nestjs/config';
import type { JwtModuleOptions } from '@nestjs/jwt';

const DEVELOPMENT_JWT_SECRET = 'paykey-development-only-jwt-secret';

export function getJwtSecret(configService: ConfigService): string {
  const secret = configService.get<string>('JWT_SECRET');
  const isProduction =
    process.env.NODE_ENV === 'production' ||
    configService.get<string>('NODE_ENV') === 'production';

  if (
    isProduction &&
    (!secret?.trim() ||
      secret === 'supersecretkey' ||
      secret === DEVELOPMENT_JWT_SECRET)
  ) {
    throw new Error('A private JWT_SECRET must be configured in production');
  }

  return secret?.trim() ? secret : DEVELOPMENT_JWT_SECRET;
}

export function getJwtOptions(configService: ConfigService): JwtModuleOptions {
  return {
    secret: getJwtSecret(configService),
    signOptions: { expiresIn: '1d' },
  };
}
