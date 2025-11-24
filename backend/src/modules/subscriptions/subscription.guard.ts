import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UsersService } from '../users/users.service';
import { WorkersService } from '../workers/workers.service';
import { SUBSCRIPTION_PLANS, canAddWorker } from './subscription-plans.config';

@Injectable()
export class SubscriptionGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private usersService: UsersService,
    private workersService: WorkersService,
  ) {}

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

    // If user is in trial period, allow unlimited workers
    if (isInTrialPeriod) {
      return true;
    }

    // Check if user can add more workers based on subscription tier
    const currentWorkerCount = await this.workersService.getWorkerCount(
      user.userId,
    );
    const canAdd = canAddWorker(userDetails.tier, currentWorkerCount);

    if (!canAdd) {
      throw new ForbiddenException(
        `Your ${userDetails.tier} subscription allows up to ${
          SUBSCRIPTION_PLANS.find((p) => p.tier === userDetails.tier)
            ?.workerLimit
        } workers. Please upgrade to add more workers.`,
      );
    }

    return true;
  }
}
