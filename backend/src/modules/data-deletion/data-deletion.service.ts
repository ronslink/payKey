import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
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
import { Subscription } from '../subscriptions/entities/subscription.entity';

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
    ) { }

    /**
     * Create a new deletion request
     */
    async createRequest(dto: CreateDeletionRequestDto): Promise<DeletionRequest> {
        // Check if user exists
        const user = await this.userRepository.findOne({
            where: { email: dto.email.toLowerCase() },
        });

        const request = this.deletionRequestRepository.create({
            email: dto.email.toLowerCase(),
            reason: dto.reason,
            status: DeletionStatus.PENDING,
            userId: user?.id,
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

        this.logger.log(`Processing ${pendingRequests.length} pending deletion requests`);

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
    private async deleteUserData(userId: string, queryRunner: any): Promise<void> {
        // Get all workers for this user
        const workers = await this.workerRepository.find({ where: { userId } });
        const workerIds = workers.map((w) => w.id);

        if (workerIds.length > 0) {
            // Delete time entries for workers
            await queryRunner.manager.delete(TimeEntry, { workerId: { $in: workerIds } });

            // Delete leave requests for workers
            await queryRunner.manager.delete(LeaveRequest, { workerId: { $in: workerIds } });

            // Delete payroll records for workers
            await queryRunner.manager.delete(PayrollRecord, { workerId: { $in: workerIds } });
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
        await queryRunner.manager.delete(User, { id: userId });
    }
}
