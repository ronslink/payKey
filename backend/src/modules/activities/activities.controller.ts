import { Controller, Get, Query, UseGuards, Request } from '@nestjs/common';
import { ActivitiesService } from './activities.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ActivityType } from './entities/activity.entity';

@Controller('activities')
@UseGuards(JwtAuthGuard)
export class ActivitiesController {
  constructor(private readonly activitiesService: ActivitiesService) {}

  @Get('recent')
  async getRecentActivities(
    @Request() req: any,
    @Query('limit') limit?: string,
  ) {
    const userId = req.user.userId;
    const limitNum = limit ? parseInt(limit, 10) : 10;

    const activities = await this.activitiesService.getRecentActivities(
      userId,
      limitNum,
    );

    return {
      activities,
      count: activities.length,
    };
  }

  @Get('by-type')
  async getActivitiesByType(
    @Request() req: any,
    @Query('type') type: ActivityType,
    @Query('limit') limit?: string,
  ) {
    const userId = req.user.userId;
    const limitNum = limit ? parseInt(limit, 10) : 10;

    const activities = await this.activitiesService.getActivitiesByType(
      userId,
      type,
      limitNum,
    );

    return {
      activities,
      count: activities.length,
      type,
    };
  }
}
