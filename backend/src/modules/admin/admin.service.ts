import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource, In } from 'typeorm';
import Redis from 'ioredis';
import * as os from 'os';
import { exec } from 'child_process';
import { promisify } from 'util';
import { ConfigService } from '@nestjs/config';

import { User } from '../users/entities/user.entity';
import { Worker } from '../workers/entities/worker.entity';
import { Transaction, TransactionStatus, TransactionType } from '../payments/entities/transaction.entity';
import { Subscription } from '../subscriptions/entities/subscription.entity';
import { PayPeriod } from '../payroll/entities/pay-period.entity';
import { PayrollRecord } from '../payroll/entities/payroll-record.entity';
import { SupportTicket } from '../support/entities/support-ticket.entity';
import { AdminAuditLog } from './entities/audit-log.entity';

const execAsync = promisify(exec);

@Injectable()
export class AdminService {
    private readonly logger = new Logger(AdminService.name);

    constructor(
        @InjectRepository(User)
        private readonly userRepo: Repository<User>,
        @InjectRepository(Worker)
        private readonly workerRepo: Repository<Worker>,
        @InjectRepository(Transaction)
        private readonly transactionRepo: Repository<Transaction>,
        @InjectRepository(Subscription)
        private readonly subscriptionRepo: Repository<Subscription>,
        @InjectRepository(PayPeriod)
        private readonly payPeriodRepo: Repository<PayPeriod>,
        @InjectRepository(PayrollRecord)
        private readonly payrollRecordRepo: Repository<PayrollRecord>,
        @InjectRepository(SupportTicket)
        private readonly supportTicketRepo: Repository<SupportTicket>,
        @InjectRepository(AdminAuditLog)
        private readonly auditLogRepo: Repository<AdminAuditLog>,
        private readonly dataSource: DataSource,
        private readonly configService: ConfigService,
    ) { }

    // ─── Analytics Dashboard ───────────────────────────────────────────────────

    async getDashboardMetrics() {
        const [
            totalUsers,
            activeUsers30d,
            totalWorkers,
            activeWorkers,
            totalRevenue,
            monthlyRevenue,
            subscriptionBreakdown,
            payrollsProcessed,
            totalPayrollVolume,
            openSupportTickets,
        ] = await Promise.all([
            // Total registered employers
            this.userRepo.count({ where: { role: In(['EMPLOYER', 'USER']) as any } }),

            // Active users in last 30 days (have a transaction or payroll in 30d)
            this.dataSource.query(`
        SELECT COUNT(DISTINCT u.id)
        FROM users u
        WHERE u.role IN ('EMPLOYER', 'USER')
          AND u."updatedAt" > NOW() - INTERVAL '30 days'
      `).then(r => parseInt(r[0]?.count || '0')),

            // Total workers
            this.workerRepo.count(),

            // Active workers
            this.workerRepo.count({ where: { isActive: true } }),

            // All-time revenue from successful subscription payments
            this.dataSource.query(`
        SELECT COALESCE(SUM(t.amount), 0) as total
        FROM transactions t
        WHERE t.type = 'SUBSCRIPTION' AND t.status = 'SUCCESS'
      `).then(r => parseFloat(r[0]?.total || '0')),

            // Revenue this month
            this.dataSource.query(`
        SELECT COALESCE(SUM(t.amount), 0) as total
        FROM transactions t
        WHERE t.type = 'SUBSCRIPTION' AND t.status = 'SUCCESS'
          AND t."createdAt" >= DATE_TRUNC('month', NOW())
      `).then(r => parseFloat(r[0]?.total || '0')),

            // Subscription tier distribution
            this.dataSource.query(`
        SELECT s.tier, COUNT(*) as count
        FROM subscriptions s
        WHERE s.status = 'ACTIVE'
        GROUP BY s.tier
        ORDER BY count DESC
      `),

            // Payrolls processed (pay periods that have been paid)
            this.payPeriodRepo.count({ where: { status: 'COMPLETED' as any } }),

            // Total payroll volume (sum of net pay from paid payroll records)
            this.dataSource.query(`
        SELECT COALESCE(SUM(pr."netSalary"), 0) as total
        FROM payroll_records pr
        WHERE pr.status IN ('paid', 'finalized')
      `).then(r => parseFloat(r[0]?.total || '0')),

            // Open support tickets
            this.supportTicketRepo.count({ where: { status: 'OPEN' as any } }),
        ]);

        // Revenue chart — last 12 months
        const revenueChart = await this.dataSource.query(`
      SELECT
        TO_CHAR(DATE_TRUNC('month', t."createdAt"), 'Mon YYYY') as month,
        DATE_TRUNC('month', t."createdAt") as month_date,
        COALESCE(SUM(t.amount), 0) as revenue
      FROM transactions t
      WHERE t.type = 'SUBSCRIPTION' AND t.status = 'SUCCESS'
        AND t."createdAt" >= NOW() - INTERVAL '12 months'
      GROUP BY DATE_TRUNC('month', t."createdAt")
      ORDER BY month_date ASC
    `);

        // Payroll volume chart — last 12 months
        const payrollChart = await this.dataSource.query(`
      SELECT
        TO_CHAR(DATE_TRUNC('month', pp."startDate"), 'Mon YYYY') as month,
        DATE_TRUNC('month', pp."startDate") as month_date,
        COUNT(*) as payrolls,
        COALESCE(SUM(pr."netSalary"), 0) as volume
      FROM pay_periods pp
      LEFT JOIN payroll_records pr ON pr."payPeriodId" = pp.id AND pr.status IN ('paid', 'finalized')
      WHERE pp.status IN ('COMPLETED', 'CLOSED')
        AND pp."startDate" >= NOW() - INTERVAL '12 months'
      GROUP BY DATE_TRUNC('month', pp."startDate")
      ORDER BY month_date ASC
    `);

        return {
            summary: {
                totalUsers,
                activeUsers30d,
                totalWorkers,
                activeWorkers,
                totalRevenue,
                monthlyRevenue,
                payrollsProcessed,
                totalPayrollVolume,
                openSupportTickets,
            },
            charts: {
                revenueByMonth: revenueChart.map((r: any) => ({
                    month: r.month,
                    revenue: parseFloat(r.revenue),
                })),
                payrollByMonth: payrollChart.map((r: any) => ({
                    month: r.month,
                    payrolls: parseInt(r.payrolls),
                    volume: parseFloat(r.volume),
                })),
                subscriptionBreakdown: subscriptionBreakdown.map((r: any) => ({
                    tier: r.tier,
                    count: parseInt(r.count),
                })),
            },
        };
    }

    // ─── Infrastructure Health ─────────────────────────────────────────────────

    async getInfraHealth() {
        const [dbHealth, diskInfo, memInfo] = await Promise.all([
            this.getDbHealth(),
            this.getDiskInfo(),
            this.getMemoryInfo(),
        ]);

        const redisInfo = await this.getRedisInfo();
        const dockerInfo = await this.getDockerInfo();

        return {
            database: dbHealth,
            disk: diskInfo,
            memory: memInfo,
            redis: redisInfo,
            docker: dockerInfo,
            timestamp: new Date().toISOString(),
        };
    }

    private async getDbHealth() {
        try {
            const [sizeResult, connResult, tableStats] = await Promise.all([
                this.dataSource.query(`
          SELECT pg_size_pretty(pg_database_size(current_database())) as size,
                 pg_database_size(current_database()) as size_bytes
        `),
                this.dataSource.query(`
          SELECT COUNT(*) as active_connections,
                 MAX(EXTRACT(EPOCH FROM (NOW() - query_start))) as longest_query_seconds
          FROM pg_stat_activity
          WHERE state = 'active' AND pid <> pg_backend_pid()
        `),
                this.dataSource.query(`
          SELECT relname as table_name, n_live_tup as row_count
          FROM pg_stat_user_tables
          ORDER BY n_live_tup DESC
          LIMIT 10
        `),
            ]);

            return {
                status: 'healthy',
                size: sizeResult[0]?.size,
                sizeBytes: parseInt(sizeResult[0]?.size_bytes || '0'),
                activeConnections: parseInt(connResult[0]?.active_connections || '0'),
                longestQuerySeconds: parseFloat(connResult[0]?.longest_query_seconds || '0'),
                topTables: tableStats.map((t: any) => ({
                    table: t.table_name,
                    rows: parseInt(t.row_count),
                })),
            };
        } catch (error) {
            this.logger.error('DB health check failed', error);
            return { status: 'unhealthy', error: error.message };
        }
    }

    private async getDiskInfo() {
        try {
            const { stdout } = await execAsync("df -h / | tail -1 | awk '{print $2,$3,$4,$5}'");
            const parts = stdout.trim().split(/\s+/);
            return {
                total: parts[0] || 'unknown',
                used: parts[1] || 'unknown',
                available: parts[2] || 'unknown',
                usedPercent: parts[3] || 'unknown',
            };
        } catch {
            // Fallback for Windows dev environments
            return { total: 'N/A', used: 'N/A', available: 'N/A', usedPercent: 'N/A' };
        }
    }

    private getMemoryInfo() {
        const totalMem = os.totalmem();
        const freeMem = os.freemem();
        const usedMem = totalMem - freeMem;
        const processMemMB = Math.round(process.memoryUsage().rss / 1024 / 1024);

        return {
            totalMB: Math.round(totalMem / 1024 / 1024),
            usedMB: Math.round(usedMem / 1024 / 1024),
            freeMB: Math.round(freeMem / 1024 / 1024),
            usedPercent: Math.round((usedMem / totalMem) * 100),
            processRssMB: processMemMB,
        };
    }

    private async getRedisInfo() {
        try {
            // Use raw Redis connection from datasource config
            const host = this.configService.get('REDIS_HOST', 'localhost');
            const port = parseInt(this.configService.get('REDIS_PORT', '6379'));
            const tempClient = new Redis({ host, port, lazyConnect: true });
            await tempClient.connect();
            const info = await tempClient.info('all');
            await tempClient.quit();

            const parse = (key: string): string => {
                const match = info.match(new RegExp(`${key}:(.*?)\\r\\n`));
                return match ? match[1].trim() : 'N/A';
            };

            return {
                status: 'healthy',
                version: parse('redis_version'),
                usedMemoryHuman: parse('used_memory_human'),
                connectedClients: parse('connected_clients'),
                uptimeSeconds: parseInt(parse('uptime_in_seconds') || '0'),
                totalCommandsProcessed: parse('total_commands_processed'),
            };
        } catch (error) {
            return { status: 'unhealthy', error: error.message };
        }
    }

    private async getDockerInfo() {
        try {
            const { stdout } = await execAsync(
                "docker ps --format '{{.Names}}|{{.Status}}|{{.Image}}' 2>/dev/null || echo ''"
            );

            if (!stdout.trim()) return { status: 'unavailable', containers: [] };

            const containers = stdout.trim().split('\n').map(line => {
                const [name, status, image] = line.split('|');
                return {
                    name: name?.trim(),
                    status: status?.trim(),
                    image: image?.trim(),
                    healthy: status?.toLowerCase().includes('up'),
                };
            }).filter(c => c.name);

            return { status: 'ok', containers };
        } catch {
            return { status: 'unavailable', containers: [] };
        }
    }

    // ─── Users ──────────────────────────────────────────────────────────────────

    async getUsers(search?: string, page = 1, limit = 20) {
        const query = this.dataSource.query(`
      SELECT
        u.id,
        u.email,
        u."firstName",
        u."lastName",
        u."businessName",
        u.role,
        u.tier,
        u."walletBalance",
        u."createdAt",
        s.status as subscription_status,
        s.tier as subscription_tier,
        COUNT(DISTINCT w.id) as worker_count
      FROM users u
      LEFT JOIN subscriptions s ON s."userId" = u.id AND s.status = 'ACTIVE'
      LEFT JOIN workers w ON w."userId" = u.id AND w."isActive" = true
      WHERE u.role IN ('EMPLOYER', 'USER')
        ${search ? `AND (u.email ILIKE $1 OR u."firstName" ILIKE $1 OR u."lastName" ILIKE $1 OR u."businessName" ILIKE $1)` : ''}
      GROUP BY u.id, s.status, s.tier
      ORDER BY u."createdAt" DESC
      LIMIT ${limit} OFFSET ${(page - 1) * limit}
    `, search ? [`%${search}%`] : []);

        const countQuery = this.dataSource.query(`
      SELECT COUNT(*) as total FROM users u
      WHERE u.role IN ('EMPLOYER', 'USER')
        ${search ? `AND (u.email ILIKE $1 OR u."firstName" ILIKE $1 OR u."lastName" ILIKE $1 OR u."businessName" ILIKE $1)` : ''}
    `, search ? [`%${search}%`] : []);

        const [users, countResult] = await Promise.all([query, countQuery]);

        return {
            data: users.map((u: any) => ({
                ...u,
                workerCount: parseInt(u.worker_count),
                displayName: u.businessName || `${u.firstName || ''} ${u.lastName || ''}`.trim() || u.email,
            })),
            total: parseInt(countResult[0]?.total || '0'),
            page,
            limit,
        };
    }

    async getUserDetail(userId: string) {
        const [user, workers, recentTransactions, subscription, payPeriods] = await Promise.all([
            this.userRepo.findOne({ where: { id: userId } }),
            this.workerRepo.find({ where: { userId }, order: { createdAt: 'DESC' } }),
            this.transactionRepo.find({
                where: { userId },
                order: { createdAt: 'DESC' },
                take: 20,
            }),
            this.subscriptionRepo.findOne({ where: { userId, status: 'ACTIVE' as any } }),
            this.payPeriodRepo.find({
                where: { userId },
                order: { createdAt: 'DESC' } as any,
                take: 10,
            }),
        ]);

        return { user, workers, recentTransactions, subscription, payPeriods };
    }

    // ─── Workers ────────────────────────────────────────────────────────────────

    async getWorkers(search?: string, page = 1, limit = 20) {
        const query = await this.dataSource.query(`
      SELECT
        w.id,
        w.name as worker_name,
        w."phoneNumber",
        w."salaryGross",
        w."isActive",
        w."paymentMethod",
        w."createdAt",
        u.id as employer_id,
        u.email as employer_email,
        COALESCE(u."businessName", CONCAT(u."firstName", ' ', u."lastName"), u.email) as employer_name
      FROM workers w
      JOIN users u ON u.id = w."userId"
      WHERE 1=1
        ${search ? `AND (w.name ILIKE $1 OR u.email ILIKE $1 OR u."businessName" ILIKE $1)` : ''}
      ORDER BY w."createdAt" DESC
      LIMIT ${limit} OFFSET ${(page - 1) * limit}
    `, search ? [`%${search}%`] : []);

        const countResult = await this.dataSource.query(`
      SELECT COUNT(*) as total FROM workers w
      JOIN users u ON u.id = w."userId"
      WHERE 1=1
        ${search ? `AND (w.name ILIKE $1 OR u.email ILIKE $1 OR u."businessName" ILIKE $1)` : ''}
    `, search ? [`%${search}%`] : []);

        return {
            data: query,
            total: parseInt(countResult[0]?.total || '0'),
            page,
            limit,
        };
    }

    // ─── Transactions ───────────────────────────────────────────────────────────

    async getTransactions(filters: {
        search?: string;
        status?: string;
        type?: string;
        page?: number;
        limit?: number;
    }) {
        const { search, status, type, page = 1, limit = 20 } = filters;

        const conditions: string[] = [];
        const params: any[] = [];
        let paramIdx = 1;

        if (search) {
            conditions.push(`(
        COALESCE(u."businessName", CONCAT(u."firstName", ' ', u."lastName")) ILIKE $${paramIdx}
        OR u.email ILIKE $${paramIdx}
        OR w.name ILIKE $${paramIdx}
        OR t."providerRef" ILIKE $${paramIdx}
      )`);
            params.push(`%${search}%`);
            paramIdx++;
        }
        if (status) {
            conditions.push(`t.status = $${paramIdx}`);
            params.push(status);
            paramIdx++;
        }
        if (type) {
            conditions.push(`t.type = $${paramIdx}`);
            params.push(type);
            paramIdx++;
        }

        const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

        const [transactions, countResult] = await Promise.all([
            this.dataSource.query(`
        SELECT
          t.id,
          t.amount,
          t.currency,
          t.type,
          t.status,
          t."providerRef",
          t."paymentMethod",
          t."createdAt",
          COALESCE(u."businessName", CONCAT(u."firstName", ' ', u."lastName"), u.email) as employer_name,
          u.email as employer_email,
          u.id as employer_id,
          w.name as worker_name,
          w.id as worker_id
        FROM transactions t
        JOIN users u ON u.id = t."userId"
        LEFT JOIN workers w ON w.id = t."workerId"
        ${whereClause}
        ORDER BY t."createdAt" DESC
        LIMIT ${limit} OFFSET ${(page - 1) * limit}
      `, params),
            this.dataSource.query(`
        SELECT COUNT(*) as total
        FROM transactions t
        JOIN users u ON u.id = t."userId"
        LEFT JOIN workers w ON w.id = t."workerId"
        ${whereClause}
      `, params),
        ]);

        return {
            data: transactions,
            total: parseInt(countResult[0]?.total || '0'),
            page,
            limit,
        };
    }

    // ─── Payroll ────────────────────────────────────────────────────────────────

    async getPayrollDashboard() {
        const [
            totalPeriods,
            successfulPeriods,
            totalVolume,
            recentPeriods
        ] = await Promise.all([
            // Total Pay Periods
            this.payPeriodRepo.count(),
            // Successful Pay Periods
            this.payPeriodRepo.count({ where: { status: 'COMPLETED' as any } }),
            // Total net pay volume for all finalized/paid records
            this.dataSource.query(`
                SELECT COALESCE(SUM(pr."netSalary"), 0) as total
                FROM payroll_records pr
                WHERE pr.status IN ('paid', 'finalized')
            `).then(r => parseFloat(r[0]?.total || '0')),
            // 5 most recent pay periods for a quick view
            this.dataSource.query(`
                SELECT
                    pp.id,
                    pp.status,
                    pp."startDate",
                    pp."endDate",
                    pp."createdAt",
                    COALESCE(u."businessName", CONCAT(u."firstName", ' ', u."lastName"), u.email) as employer_name,
                    COUNT(pr.id) as record_count,
                    COALESCE(SUM(pr."netSalary"), 0) as total_net_pay
                FROM pay_periods pp
                JOIN users u ON u.id = pp."userId"
                LEFT JOIN payroll_records pr ON pr."payPeriodId" = pp.id
                GROUP BY pp.id, u.id
                ORDER BY pp."createdAt" DESC
                LIMIT 5
            `)
        ]);

        return {
            summary: {
                totalPeriods,
                successfulPeriods,
                totalVolume,
            },
            recentPeriods: recentPeriods.map((p: any) => ({
                ...p,
                recordCount: parseInt(p.record_count),
                totalNetPay: parseFloat(p.total_net_pay),
            }))
        };
    }

    async getPayPeriods(search?: string, page = 1, limit = 20) {
        const [payPeriods, countResult] = await Promise.all([
            this.dataSource.query(`
        SELECT
          pp.id,
          pp.status,
          pp."startDate",
          pp."endDate",
          pp."createdAt",
          COALESCE(u."businessName", CONCAT(u."firstName", ' ', u."lastName"), u.email) as employer_name,
          u.email as employer_email,
          u.id as employer_id,
          COUNT(pr.id) as record_count,
          COALESCE(SUM(pr."netSalary"), 0) as total_net_pay
        FROM pay_periods pp
        JOIN users u ON u.id = pp."userId"
        LEFT JOIN payroll_records pr ON pr."payPeriodId" = pp.id
        ${search ? `WHERE COALESCE(u."businessName", CONCAT(u."firstName", ' ', u."lastName")) ILIKE $1 OR u.email ILIKE $1` : ''}
        GROUP BY pp.id, u.id
        ORDER BY pp."createdAt" DESC
        LIMIT ${limit} OFFSET ${(page - 1) * limit}
      `, search ? [`%${search}%`] : []),
            this.dataSource.query(`
        SELECT COUNT(*) as total FROM pay_periods pp
        JOIN users u ON u.id = pp."userId"
        ${search ? `WHERE COALESCE(u."businessName", CONCAT(u."firstName", ' ', u."lastName")) ILIKE $1 OR u.email ILIKE $1` : ''}
      `, search ? [`%${search}%`] : []),
        ]);

        return {
            data: payPeriods.map((p: any) => ({
                ...p,
                recordCount: parseInt(p.record_count),
                totalNetPay: parseFloat(p.total_net_pay),
            })),
            total: parseInt(countResult[0]?.total || '0'),
            page,
            limit,
        };
    }

    async getPayrollRecords(payPeriodId: string) {
        return this.dataSource.query(`
      SELECT
        pr.id,
        pr.status,
        pr."grossSalary",
        pr."netSalary" as "netPay",
        pr."taxAmount" as "payeTax",
        pr."otherDeductions",
        pr."createdAt",
        w.name as worker_name,
        w."phoneNumber" as worker_phone,
        w."paymentMethod"
      FROM payroll_records pr
      JOIN workers w ON w.id = pr."workerId"
      WHERE pr."payPeriodId" = $1
      ORDER BY w.name ASC
    `, [payPeriodId]);
    }

    // ─── Audit Logs ─────────────────────────────────────────────────────────────

    async logAction(data: {
        adminUserId: string;
        action: string;
        entityType: string;
        entityId?: string;
        oldValues?: any;
        newValues?: any;
        ipAddress?: string;
        userAgent?: string;
    }) {
        try {
            const log = this.auditLogRepo.create(data);
            await this.auditLogRepo.save(log);
        } catch (error) {
            this.logger.error(`Failed to create audit log for ${data.action} on ${data.entityType}`, error);
        }
    }

    async getAuditLogs(filters: { page?: number; limit?: number; entityType?: string; action?: string }) {
        const { page = 1, limit = 20, entityType, action } = filters;

        const qb = this.auditLogRepo.createQueryBuilder('log')
            .leftJoinAndSelect('log.adminUser', 'adminUser')
            .orderBy('log.createdAt', 'DESC')
            .skip((page - 1) * limit)
            .take(limit);

        if (entityType) {
            qb.andWhere('log.entityType = :entityType', { entityType });
        }
        if (action) {
            qb.andWhere('log.action = :action', { action });
        }

        const [data, total] = await qb.getManyAndCount();

        return {
            data: data.map(log => ({
                ...log,
                adminEmail: log.adminUser?.email,
            })),
            total,
            page,
            limit,
        };
    }
}
