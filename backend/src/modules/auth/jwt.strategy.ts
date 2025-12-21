import { ExtractJwt, Strategy } from 'passport-jwt';
import { PassportStrategy } from '@nestjs/passport';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

interface JwtUser {
  userId: string;
  email: string;
  tier: string;
  role: string;
  employerId?: string; // For WORKER role: ID of the employer User
  workerId?: string;   // For WORKER role: ID of the Worker profile
}

interface JwtPayload {
  email: string;
  sub: string;
  tier: string;
  role: string;
  employerId?: string;
  workerId?: string;
  userId?: string; // Sometimes used redundantly
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(configService: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get<string>('JWT_SECRET') || 'supersecretkey',
    });
  }

  validate(payload: JwtPayload): JwtUser {
    return {
      userId: payload.sub, // 'sub' is standard, but we also put 'userId' in payload
      email: payload.email,
      tier: payload.tier,
      role: payload.role,
      employerId: payload.employerId,
      workerId: payload.workerId,
    };
  }
}
