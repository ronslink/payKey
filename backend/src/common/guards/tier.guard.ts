import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';

export const TIERS_KEY = 'tiers';
export const RequireTiers = (...tiers: string[]) => {
  return (target: any, key?: string, descriptor?: any) => {
    Reflect.defineMetadata(TIERS_KEY, tiers, descriptor?.value ?? target);
    return descriptor ?? target;
  };
};

@Injectable()
export class TierGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredTiers = this.reflector.get<string[]>(
      TIERS_KEY,
      context.getHandler(),
    );

    if (!requiredTiers?.length) {
      return true; // No tier requirement, allow access
    }

    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user?.tier) {
      throw new ForbiddenException('Subscription tier required');
    }

    const hasAccess = requiredTiers.includes(user.tier);

    if (!hasAccess) {
      throw new ForbiddenException(
        `This feature requires ${requiredTiers.join(' or ')} subscription`,
      );
    }

    return true;
  }
}
