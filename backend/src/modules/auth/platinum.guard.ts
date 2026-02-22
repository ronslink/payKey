import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { UserTier } from '../users/entities/user.entity';

@Injectable()
export class PlatinumGuard implements CanActivate {
  private readonly logger = new Logger(PlatinumGuard.name);

  constructor(private usersService: UsersService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const user = request.user;

    this.logger.debug(`PlatinumGuard check: user=${user?.email}, userId=${user?.userId}, role=${user?.role}, tier=${user?.tier}`);

    if (!user) {
      throw new ForbiddenException('User not authenticated');
    }

    // Identify userId based on role (Workers might access under their employer's tier?)
    // Requirement is GATED FEATURE for Employer.
    // If WORKER is accessing, it depends on their EMPLOYER'S tier.
    let targetUserId = user.userId;

    if (user.role === 'WORKER') {
      targetUserId = user.employerId;
    }

    // Get user with current subscription details
    const userDetails = await this.usersService.findOneById(targetUserId);

    this.logger.debug(`PlatinumGuard: targetUserId=${targetUserId}, foundUser=${userDetails?.email}, userTier=${userDetails?.tier}`);

    if (!userDetails) {
      throw new ForbiddenException('User not found');
    }

    // Check tier
    if (userDetails.tier !== UserTier.PLATINUM) {
      this.logger.warn(`PlatinumGuard: Access denied for ${userDetails.email} - tier is ${userDetails.tier}, not PLATINUM`);
      throw new ForbiddenException(
        'This feature is available only for PLATINUM users. Please upgrade to access.',
      );
    }

    this.logger.debug(`PlatinumGuard: Access granted for ${userDetails.email} - tier is PLATINUM`);

    return true;
  }
}
