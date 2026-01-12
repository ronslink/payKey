import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { TRIAL_PERIOD_DAYS, canImport } from './subscription-plans.config';

@Injectable()
export class ImportFeatureGuard implements CanActivate {
  constructor(private usersService: UsersService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user) {
      throw new ForbiddenException('User not authenticated');
    }

    const userDetails = await this.usersService.findOneById(user.userId);
    if (!userDetails) {
      throw new ForbiddenException('User not found');
    }

    // Check if user is in trial period - trial users can access import
    const userCreatedAt = userDetails.createdAt;
    const trialEndDate = new Date(userCreatedAt);
    trialEndDate.setDate(trialEndDate.getDate() + TRIAL_PERIOD_DAYS);
    const isInTrialPeriod = new Date() <= trialEndDate;

    if (isInTrialPeriod) {
      return true;
    }

    // Check if user's tier allows import
    const canImportWorkers = canImport(userDetails.tier);

    if (!canImportWorkers) {
      throw new ForbiddenException(
        'The import feature is available for paid plans only. Please upgrade to BASIC, GOLD, or PLATINUM to import workers from Excel.',
      );
    }

    return true;
  }
}
