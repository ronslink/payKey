import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UsersService } from '../users/users.service';
import { SUBSCRIPTION_PLANS } from './subscription-plans.config';

@Injectable()
export class SubscriptionGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private usersService: UsersService,
  ) { }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user) {
      throw new ForbiddenException('User not authenticated');
    }

    // Get user with current subscription details
    const userDetails = await this.usersService.findOneById(user.userId);
    if (!userDetails) {
      throw new ForbiddenException('User not found');
    }

    // Check if user is within 14-day trial period
    const userCreatedAt = userDetails.createdAt;
    const trialEndDate = new Date(userCreatedAt);
    trialEndDate.setDate(trialEndDate.getDate() + 14); // 14-day trial
    const isInTrialPeriod = new Date() <= trialEndDate;

    // If user is in trial period, allow access
    if (isInTrialPeriod) {
      return true;
    }

    // Logic for worker limits is now handled in WorkersService.create()
    // This guard can be extended to checks specific subscription statuses if needed
    // For now, it ensures the user exists and data is fresh.

    return true;
  }
}
