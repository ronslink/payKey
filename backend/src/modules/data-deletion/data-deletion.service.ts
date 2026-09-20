import {
  Injectable,
  Logger,
  UnauthorizedException,
  BadRequestException,
  NotFoundException,
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
import {
  Subscription,
  SubscriptionStatus,
} from '../subscriptions/entities/subscription.entity';
import * as bcrypt from 'bcrypt';

/** A column that can hold an owning user or worker id. */
interface OwnershipColumn {
  table_name: string;
  column_name: string;
  data_type: string;
}

/**
 * Tables whose rows are retained deliberately and are therefore exempt from the
 * residual check:
 *   admin_audit_logs  - compliance records about the acting administrator.
 *   deletion_requests - the audit trail of the deletion itself.
 */
const RETAINED_TABLES = new Set(['admin_audit_logs', 'deletion_requests']);

@Injectable()
export class DataDeletionService {
  private readonly logger = new Logger(DataDeletionService.name);

  /** Monotonic counter so SAVEPOINT names stay unique within a transaction. */
  private savepointCounter = 0;

  constructor(
    @InjectRepository(DeletionRequest)
    private deletionRequestRepository: Repository<DeletionRequest>,
    @InjectRepository(User)
    private userRepository: Repository<User>,
    @InjectRepository(Worker)
    private workerRepository: Repository<Worker>,
    @InjectRepository(Subscription)
    private subscriptionRepository: Repository<Subscription>,
    private dataSource: DataSource,
  ) {}

  /**
   * Create a new deletion request.
   *
   * `adminOverride` is set only by the SUPER_ADMIN admin endpoint, which has
   * already authenticated and authorised the caller and records an audit entry.
   * It skips the account-ownership and password checks, which exist to prove that
   * a self-service caller owns the account being deleted.
   */
  async createRequest(
    dto: CreateDeletionRequestDto,
    authenticatedUserId?: string,
    options?: { adminOverride?: boolean },
  ): Promise<DeletionRequest> {
    const user = await this.userRepository.findOne({
      where: { email: dto.email.toLowerCase() },
    });

    if (!user) {
      if (options?.adminOverride) {
        throw new NotFoundException(`No account exists for ${dto.email}.`);
      }
      throw new UnauthorizedException('Invalid email or password.');
    }

    if (!options?.adminOverride) {
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
    }

    // Applies to every caller, including administrators: an active recurring
    // contract must be cancelled first so it cannot keep charging after deletion.
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
   * Process one request immediately and report the outcome, so an administrator
   * sees the real result instead of a queued request that fails silently on the
   * next scheduled run.
   */
  async processRequestById(id: string): Promise<DeletionRequest> {
    const request = await this.deletionRequestRepository.findOne({
      where: { id },
    });
    if (!request) {
      throw new NotFoundException(`Deletion request ${id} was not found`);
    }
    if (
      request.status !== DeletionStatus.PENDING &&
      request.status !== DeletionStatus.FAILED
    ) {
      return request;
    }
    return this.processRequest(request);
  }

  /**
   * Process a single deletion request
   */
  private async processRequest(
    request: DeletionRequest,
  ): Promise<DeletionRequest> {
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
        return request;
      }

      await this.deleteUserData(
        user.id,
        queryRunner,
        request.email,
        request.id,
      );

      // Mark request as completed
      request.status = DeletionStatus.COMPLETED;
      request.processedAt = new Date();
      request.errorMessage = '';
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

    return request;
  }

  /**
   * Delete every row owned by an employer: their own rows, their workers' rows,
   * and any worker-portal accounts that claimed one of those workers.
   *
   * Ownership is discovered from information_schema by column NAME rather than by
   * data type. Production stores some `userId` columns as varchar and others as
   * uuid, so a type-filtered discovery silently skips tables and reports success
   * while leaving rows behind.
   */
  private async deleteUserData(
    userId: string,
    queryRunner: QueryRunner,
    email: string,
    keepDeletionRequestId?: string,
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

    // A worker portal login is a second `users` row reached through
    // workers."linkedUserId". No `userId` column covers it, so it is collected
    // here and purged alongside the employer.
    const workers = await this.workerRepository.find({
      where: { userId },
      select: ['id', 'linkedUserId'],
    });
    const workerIds = workers.map((w) => w.id);
    const portalUserIds = workers
      .map((w) => w.linkedUserId)
      .filter((id): id is string => typeof id === 'string' && id.length > 0);
    const subjectUserIds = [userId, ...portalUserIds];

    const ownershipColumns = (await this.queryRows(
      queryRunner,
      `SELECT table_name, column_name, data_type
         FROM information_schema.columns
        WHERE table_schema = 'public'
          AND column_name IN ('userId', 'workerId')
          AND data_type IN ('uuid', 'character varying', 'text')`,
    )) as OwnershipColumn[];

    const userColumns = ownershipColumns.filter(
      (c) => c.column_name === 'userId' && c.table_name !== 'users',
    );
    const workerColumns = ownershipColumns.filter(
      (c) => c.column_name === 'workerId',
    );

    // Deleting a parent before its children raises a foreign key error. Repeat the
    // sweep until a pass makes no progress, instead of hardcoding an order that
    // schema drift would invalidate.
    const maxPasses = 12;
    let deletedRows = 0;
    for (let pass = 0; pass < maxPasses; pass++) {
      const userSweep = await this.sweep(
        userColumns,
        subjectUserIds,
        queryRunner,
      );
      const workerSweep = await this.sweep(
        workerColumns,
        workerIds,
        queryRunner,
      );
      deletedRows += userSweep.deleted + workerSweep.deleted;
      if (
        userSweep.deleted + workerSweep.deleted === 0 &&
        userSweep.fkBlocked + workerSweep.fkBlocked === 0
      ) {
        break;
      }
    }

    // Deletion history for this account, keeping the in-flight request row: it is
    // the audit record for this deletion and is updated after the transaction.
    const deletionHistoryParams: unknown[] = [subjectUserIds, email];
    let deletionHistorySql = `DELETE FROM deletion_requests
         WHERE (("userId" IS NOT NULL AND "userId"::text = ANY($1::text[]))
            OR lower(email) = lower($2))`;
    if (keepDeletionRequestId) {
      deletionHistorySql += ' AND id <> $3::uuid';
      deletionHistoryParams.push(keepDeletionRequestId);
    }
    await queryRunner.manager.query(deletionHistorySql, deletionHistoryParams);

    if (portalUserIds.length > 0) {
      const removedPortals = await this.queryRows(
        queryRunner,
        'DELETE FROM users WHERE id = ANY($1::uuid[]) RETURNING id',
        [portalUserIds],
      );
      this.logger.log(
        `Deleted ${removedPortals.length} worker portal account(s) with the employer`,
      );
    }

    const removedUsers = await this.queryRows(
      queryRunner,
      'DELETE FROM users WHERE id = $1::uuid RETURNING id',
      [userId],
    );
    deletedRows += removedUsers.length;

    await this.assertNoResidualData(
      subjectUserIds,
      queryRunner,
      keepDeletionRequestId,
    );

    this.logger.log(
      `Deleted ${deletedRows} row(s) for employer ${userId}${
        portalUserIds.length
          ? ` and ${portalUserIds.length} portal login(s)`
          : ''
      }`,
    );
  }

  /**
   * Delete rows owned by any of `ids` from the given columns.
   *
   * The parameter is cast rather than the column, so uuid comparisons stay
   * index-backed. Each statement runs inside its own SAVEPOINT: a foreign key
   * error means a parent was reached before its child, and PostgreSQL aborts the
   * entire transaction on any error, so the savepoint is what makes it possible
   * to roll that one statement back and retry the sweep on the next pass.
   */
  private async sweep(
    columns: OwnershipColumn[],
    ids: string[],
    queryRunner: QueryRunner,
  ): Promise<{ deleted: number; fkBlocked: number }> {
    let deleted = 0;
    let fkBlocked = 0;
    if (ids.length === 0) {
      return { deleted, fkBlocked };
    }

    for (const { table_name, column_name, data_type } of columns) {
      const cast = data_type === 'uuid' ? 'uuid[]' : 'text[]';
      const savepoint = `delete_sweep_${this.savepointCounter++}`;
      await queryRunner.manager.query(`SAVEPOINT ${savepoint}`);
      try {
        const rows = await this.queryRows(
          queryRunner,
          `DELETE FROM "${table_name}" WHERE "${column_name}" = ANY($1::${cast}) RETURNING 1`,
          [ids],
        );
        await queryRunner.manager.query(`RELEASE SAVEPOINT ${savepoint}`);
        deleted += rows.length;
      } catch (error) {
        await queryRunner.manager.query(`ROLLBACK TO SAVEPOINT ${savepoint}`);
        await queryRunner.manager.query(`RELEASE SAVEPOINT ${savepoint}`);
        const message = error instanceof Error ? error.message : String(error);
        if (/foreign key/i.test(message)) {
          fkBlocked += 1;
          continue;
        }
        throw error;
      }
    }

    return { deleted, fkBlocked };
  }

  /**
   * Fail loudly if anything still references the deleted account.
   *
   * The scan is deliberately independent of the ownership sweep: it inspects every
   * text-like column in the schema, so a column the sweep cannot see — for example
   * a `recordedById` that is not named `userId` — is reported instead of the
   * deletion being recorded as successful.
   */
  private async assertNoResidualData(
    subjectUserIds: string[],
    queryRunner: QueryRunner,
    keepDeletionRequestId?: string,
  ): Promise<void> {
    const ids = subjectUserIds.filter((id) => typeof id === 'string' && id);
    if (ids.length === 0) {
      return;
    }

    const columns = (await this.queryRows(
      queryRunner,
      `SELECT table_name, column_name
         FROM information_schema.columns
        WHERE table_schema = 'public'
          AND data_type IN ('uuid', 'character varying', 'text')`,
    )) as Array<{ table_name: string; column_name: string }>;

    const residuals: string[] = [];
    for (const { table_name, column_name } of columns) {
      if (RETAINED_TABLES.has(table_name)) {
        continue;
      }
      // Only uuid/varchar/text columns reach this point, so ::text is always
      // valid. A failure must surface rather than be swallowed: any error aborts
      // the surrounding transaction, which would mask the real cause.
      const rows = await this.queryRows(
        queryRunner,
        `SELECT count(*)::int AS n FROM "${table_name}"
          WHERE "${column_name}"::text = ANY($1::text[])`,
        [ids],
      );
      const count = Number((rows[0] as { n?: number } | undefined)?.n ?? 0);
      if (count > 0) {
        residuals.push(`${table_name}.${column_name} (${count})`);
      }
    }

    if (residuals.length > 0) {
      throw new Error(
        `Deletion incomplete: ${residuals.length} column(s) still reference this account: ${residuals.join(', ')}`,
      );
    }

    // deletion_requests is retained, but no row other than the in-flight request
    // may still point at this account.
    if (keepDeletionRequestId) {
      const staleRows = await this.queryRows(
        queryRunner,
        `SELECT count(*)::int AS n FROM deletion_requests
          WHERE "userId"::text = ANY($1::text[]) AND id <> $2::uuid`,
        [ids, keepDeletionRequestId],
      );
      const staleCount = Number(
        (staleRows[0] as { n?: number } | undefined)?.n ?? 0,
      );
      if (staleCount > 0) {
        throw new Error(
          `Deletion incomplete: ${staleCount} older deletion request row(s) still reference this account`,
        );
      }
    }
  }

  /**
   * Run raw SQL and return the rows, without leaking the driver's `any` type.
   * Driver results differ by version, so both an array and a `{ rows }` wrapper
   * are accepted.
   */
  private async queryRows(
    queryRunner: QueryRunner,
    sql: string,
    params: unknown[] = [],
  ): Promise<unknown[]> {
    const result: unknown = await queryRunner.manager.query(sql, params);
    if (Array.isArray(result)) {
      return result as unknown[];
    }
    const rows = (result as { rows?: unknown })?.rows;
    return Array.isArray(rows) ? (rows as unknown[]) : [];
  }
}
