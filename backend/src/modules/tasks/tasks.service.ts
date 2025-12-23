import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThanOrEqual } from 'typeorm';
import {
  PayPeriod,
  PayPeriodStatus,
} from '../payroll/entities/pay-period.entity';
import {
  LeaveRequest,
  LeaveStatus,
} from '../workers/entities/leave-request.entity';
import { TaxesService } from '../taxes/taxes.service';
import { TaskDto, TaskPriority } from './dto/task.dto';

@Injectable()
export class TasksService {
  constructor(
    @InjectRepository(PayPeriod)
    private payPeriodRepository: Repository<PayPeriod>,
    @InjectRepository(LeaveRequest)
    private leaveRequestRepository: Repository<LeaveRequest>,
    private taxesService: TaxesService,
  ) {}

  async getTasks(userId: string): Promise<TaskDto[]> {
    const tasks: TaskDto[] = [];

    // 1. Payroll Tasks
    const pendingPayrolls = await this.payPeriodRepository.find({
      where: {
        userId,
        status: PayPeriodStatus.DRAFT,
      },
      order: { endDate: 'ASC' },
    });

    for (const payroll of pendingPayrolls) {
      const daysUntilDue = this.getDaysDifference(new Date(), payroll.endDate);
      let priority = TaskPriority.LOW;

      if (daysUntilDue <= 3) priority = TaskPriority.HIGH;
      else if (daysUntilDue <= 7) priority = TaskPriority.MEDIUM;

      tasks.push({
        id: `payroll-${payroll.id}`,
        title: `Process Payroll: ${payroll.name}`,
        description: `Payroll for ${payroll.name} is due`,
        dueDate: payroll.endDate,
        priority,
        actionUrl: `/payroll/process/${payroll.id}`,
        type: 'payroll',
      });
    }

    // 2. Leave Request Tasks
    const pendingLeaves = await this.leaveRequestRepository.find({
      where: {
        // We need to filter by userId of the employer, but LeaveRequest links to Worker.
        // We can join with worker to filter by userId.
        worker: { userId },
        status: LeaveStatus.PENDING,
      },
      relations: ['worker'],
      order: { startDate: 'ASC' },
    });

    for (const leave of pendingLeaves) {
      const daysUntilStart = this.getDaysDifference(
        new Date(),
        leave.startDate,
      );
      let priority = TaskPriority.LOW;

      if (daysUntilStart <= 2) priority = TaskPriority.HIGH;
      else if (daysUntilStart <= 5) priority = TaskPriority.MEDIUM;

      tasks.push({
        id: `leave-${leave.id}`,
        title: `Leave Request: ${leave.worker.name}`,
        description: `${leave.leaveType} leave request needs approval`,
        dueDate: leave.startDate,
        priority,
        actionUrl: `/workers/leave-requests`, // Or specific request ID
        type: 'leave',
      });
    }

    // 3. Tax Tasks
    const taxDeadlines = this.taxesService.getUpcomingDeadlines();
    // Filter deadlines that are close (e.g., within 14 days)
    const upcomingTaxDeadlines = taxDeadlines.filter((d) => {
      const diff = this.getDaysDifference(new Date(), d.dueDate);
      return diff >= 0 && diff <= 14;
    });

    for (const deadline of upcomingTaxDeadlines) {
      const daysUntilDue = this.getDaysDifference(new Date(), deadline.dueDate);
      let priority = TaskPriority.LOW;

      if (daysUntilDue <= 3) priority = TaskPriority.HIGH;
      else if (daysUntilDue <= 7) priority = TaskPriority.MEDIUM;

      tasks.push({
        id: `tax-${deadline.title.replace(/\s+/g, '-').toLowerCase()}`,
        title: deadline.title,
        description: deadline.description,
        dueDate: deadline.dueDate,
        priority,
        actionUrl: '/taxes',
        type: 'tax',
      });
    }

    // Sort by priority (High > Medium > Low) and then by due date
    return tasks.sort((a, b) => {
      const priorityOrder = {
        [TaskPriority.HIGH]: 0,
        [TaskPriority.MEDIUM]: 1,
        [TaskPriority.LOW]: 2,
      };
      if (priorityOrder[a.priority] !== priorityOrder[b.priority]) {
        return priorityOrder[a.priority] - priorityOrder[b.priority];
      }
      return new Date(a.dueDate).getTime() - new Date(b.dueDate).getTime();
    });
  }

  private getDaysDifference(date1: Date, date2: Date): number {
    const oneDay = 24 * 60 * 60 * 1000;
    return Math.ceil(
      (new Date(date2).getTime() - new Date(date1).getTime()) / oneDay,
    );
  }
}
