import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Activity, ActivityType } from './entities/activity.entity';

@Injectable()
export class ActivitiesService {
  constructor(
    @InjectRepository(Activity)
    private activityRepository: Repository<Activity>,
  ) {}

  async logActivity(
    userId: string,
    type: ActivityType,
    title: string,
    description: string,
    metadata?: any,
  ): Promise<Activity> {
    const activity = this.activityRepository.create({
      userId,
      type,
      title,
      description,
      metadata,
      timestamp: new Date(),
    });

    return this.activityRepository.save(activity);
  }

  async getRecentActivities(
    userId: string,
    limit: number = 10,
  ): Promise<Activity[]> {
    return this.activityRepository.find({
      where: { userId },
      order: { timestamp: 'DESC' },
      take: limit,
    });
  }

  async getActivitiesByType(
    userId: string,
    type: ActivityType,
    limit: number = 10,
  ): Promise<Activity[]> {
    return this.activityRepository.find({
      where: { userId, type },
      order: { timestamp: 'DESC' },
      take: limit,
    });
  }

  async deleteOldActivities(
    userId: string,
    daysToKeep: number = 90,
  ): Promise<void> {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysToKeep);

    await this.activityRepository
      .createQueryBuilder()
      .delete()
      .where('userId = :userId', { userId })
      .andWhere('timestamp < :cutoffDate', { cutoffDate })
      .execute();
  }
}
