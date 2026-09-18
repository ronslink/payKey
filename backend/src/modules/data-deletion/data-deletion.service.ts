import {
  Injectable,
  Logger,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource, QueryRunner, Not, IsNull } from 'typeorm';
import {
  DeletionRequest,
  DeletionStatus,
} from './entities/deletion-request.entity';
import { CreateDeletionRequestDto } from './dto/create-deletion-request.dto';
import { User } from '../users/entities/user.entity';
import { Worker } from '../workers/entities/worker.entity';
import { PayPeriod } from '../payroll/entities/pay-period.entity';
import { PayrollRecord } from '../payroll/entities/payroll-record.entity';
import { TimeEntry } from '../time-tracking/entities/time-entry.entity';
import { LeaveRequest } from '../workers/entities/leave-request.entity';
import { Property } from '../properties/entities/property.entity';
import { Transaction } from '../payments/entities/transaction.entity';
import {
  Subscription,
  SubscriptionStatus,
} from '../subscriptions/entities/subscription.entity';
import { Activity } from '../activities/entities/activity.entity';
import * as bcrypt from 'bcrypt';

@Injectable()
export class DataDeletionService {
  private readonly logger = new Logger(DataDeletionService.name);

  constructor(
    @InjectRepository(DeletionRequest)
    private deletionRequestRepository: Repository<DeletionRequest>,
    @InjectRepository(User)
    private userRepository: Repository<User>,
    @InjectRepository(Worker)
    private workerRepository: Repository<Worker>,
    @InjectRepository(PayPeriod)
    private payPeriodRepository: Repository<PayPeriod>,
    @InjectRepository(PayrollRecord)
    private payrollRecordRepository: Repository<PayrollRecord>,
    @InjectRepository(TimeEntry)
    private timeEntryRepository: Repository<TimeEntry>,
    @InjectRepository(LeaveRequest)
    private leaveRequestRepository: Repository<LeaveRequest>,
    @InjectRepository(Property)
    private propertyRepository: Repository<Property>,
    @InjectRepository(Transaction)
    private transactionRepository: Repository<Transaction>,
    @InjectRepository(Subscription)
    private subscriptionRepository: Repository<Subscription>,
    private dataSource: DataSource,
  ) {}

  /**
   * Create a new deletion request
   */
  async createRequest(
    dto: CreateDeletionRequestDto,
    authenticatedUserId?: string,
  ): Promise<DeletionRequest> {
    // Check if user exists
    const user = await this.userRepository.findOne({
      where: { email: dto.email.toLowerCase() },
    });

    if (!user) {
      throw new UnauthorizedException('Invalid email or password.');
    }

    if (!user.passwordHash && authenticatedUserId !== user.id) {
      throw new UnauthorizedException(
        'Sign in to request deletion of this account.',
      );
    }
    if (authenticatedUserId && authenticatedUserId !== user.id) {
      throw new UnauthorizedException(
        'Account does not belong to the signed-in user.',
      );
    }

    if (user.passwordHash) {
      if (!dto.password) {
        throw new BadRequestException(
          'Password is required to confirm deletion.',
        );
      }
      const isPasswordValid = await bcrypt.compare(
        dto.password,
        user.passwordHash,
      );
      if (!isPasswordValid) {
        throw new UnauthorizedException('Invalid email or password.');
      }
    }

    const recurringSubscription = await this.subscriptionRepository.findOne({
      where: {
        userId: user.id,
        stripeSubscriptionId: Not(IsNull()),
        status: Not(SubscriptionStatus.CANCELLED),
      },
    });
    if (recurringSubscription) {
      throw new BadRequestException(
        'Cancel the recurring subscription before deleting this account.',
      );
    }

    const request = this.deletionRequestRepository.create({
      email: dto.email.toLowerCase(),
      reason: dto.reason,
      status: DeletionStatus.PENDING,
      userId: user.id,
    });

    await this.deletionRequestRepository.save(request);

    this.logger.log(`Deletion request created for email: ${dto.email}`);
    return request;
  }

  /**
   * Get request status by ID
   */
  async getRequestStatus(id: string): Promise<DeletionRequest | null> {
    return this.deletionRequestRepository.findOne({ where: { id } });
  }

  /**
   * Process all pending deletion requests
   * Called by the scheduler
   */
  async processPendingRequests(): Promise<void> {
    const pendingRequests = await this.deletionRequestRepository.find({
      where: { status: DeletionStatus.PENDING },
    });

    this.logger.log(
      `Processing ${pendingRequests.length} pending deletion requests`,
    );

    for (const request of pendingRequests) {
      await this.processRequest(request);
    }
  }

  /**
   * Process a single deletion request
   */
  private async processRequest(request: DeletionRequest): Promise<void> {
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // Update status to processing
      request.status = DeletionStatus.PROCESSING;
      await this.deletionRequestRepository.save(request);

      // Find user by email
      const user = await this.userRepository.findOne({
        where: { email: request.email },
      });

      if (!user) {
        // User doesn't exist, mark as completed
        request.status = DeletionStatus.COMPLETED;
        request.processedAt = new Date();
        request.errorMessage = 'User not found - no data to delete';
        await this.deletionRequestRepository.save(request);
        this.logger.log(`No user found for email: ${request.email}`);
        await queryRunner.commitTransaction();
        return;
      }

      // Delete all user data in order (respecting foreign key constraints)
      await this.deleteUserData(user.id, queryRunner);

      // Mark request as completed
      request.status = DeletionStatus.COMPLETED;
      request.processedAt = new Date();
      await queryRunner.manager.save(request);

      await queryRunner.commitTransaction();
      this.logger.log(`Successfully deleted all data for user: ${user.id}`);
    } catch (error) {
      await queryRunner.rollbackTransaction();

      request.status = DeletionStatus.FAILED;
      request.errorMessage = error.message;
      await this.deletionRequestRepository.save(request);

      this.logger.error(`Failed to process deletion request: ${error.message}`);
    } finally {
      await queryRunner.release();
    }
  }

  /**
   * Delete all data associated with a user
   */
  private async deleteUserData(
    userId: string,
    queryRunner: QueryRunner,
  ): Promise<void> {
    // Do not orphan a recurring contract that could keep charging after deletion.
    await queryRunner.manager.query(
      'SELECT pg_advisory_xact_lock(hashtext($1))',
      [`stripe-billing:${userId}`],
    );
    const recurringSubscription = await queryRunner.manager.findOne(
      Subscription,
      {
        where: {
          userId,
          stripeSubscriptionId: Not(IsNull()),
          status: Not(SubscriptionStatus.CANCELLED),
        },
      },
    );
    if (recurringSubscription) {
      throw new BadRequestException(
        'Cancel the recurring subscription before deleting this account.',
      );
    }
    // Get all workers for this user
    const workers = await this.workerRepository.find({ where: { userId } });
    const workerIds = workers.map((w) => w.id);

    if (workerIds.length > 0) {
      // Delete time entries for workers
      for (const workerId of workerIds) {
        await queryRunner.manager.delete(TimeEntry, { workerId });
      }

      // Delete leave requests for workers
      for (const workerId of workerIds) {
        await queryRunner.manager.delete(LeaveRequest, { workerId });
      }

      // Delete payroll records for workers
      for (const workerId of workerIds) {
        await queryRunner.manager.delete(PayrollRecord, { workerId });
      }
    }

    // Delete pay periods
    await queryRunner.manager.delete(PayPeriod, { userId });

    // Delete workers
    await queryRunner.manager.delete(Worker, { userId });

    // Delete properties
    await queryRunner.manager.delete(Property, { userId });

    // Delete transactions
    await queryRunner.manager.delete(Transaction, { userId });

    // Delete subscriptions
    await queryRunner.manager.delete(Subscription, { userId });

    // Finally, delete the user
    await queryRunner.manager.delete(Activity, { userId });
    await queryRunner.manager.delete(User, { id: userId });
  }
}
