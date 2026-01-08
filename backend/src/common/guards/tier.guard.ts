import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Inject,
  forwardRef,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UsersService } from '../../modules/users/users.service';

export const TIERS_KEY = 'tiers';
export const RequireTiers = (...tiers: string[]) => {
  return (target: any, key?: string, descriptor?: any) => {
    Reflect.defineMetadata(TIERS_KEY, tiers, descriptor?.value ?? target);
    return descriptor ?? target;
  };
};

@Injectable()
export class TierGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    @Inject(forwardRef(() => UsersService))
    private usersService: UsersService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requiredTiers = this.reflector.get<string[]>(
      TIERS_KEY,
      context.getHandler(),
    );

    if (!requiredTiers?.length) {
      return true; // No tier requirement, allow access
    }

    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user?.userId) {
      throw new ForbiddenException('Authentication required');
    }

    // FETCH FRESH TIER FROM DATABASE (not from cached JWT)
    const freshUser = await this.usersService.findOneById(user.userId);
    const currentTier = freshUser?.tier || 'FREE';

    const hasAccess = requiredTiers.includes(currentTier);

    if (!hasAccess) {
      throw new ForbiddenException(
        `This feature requires ${requiredTiers.join(' or ')} subscription`,
      );
    }

    // Update request.user.tier for downstream use
    request.user.tier = currentTier;

    return true;
  }
}
