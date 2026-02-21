import { Injectable, Logger, Inject } from '@nestjs/common';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import type { Cache } from 'cache-manager';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource, In } from 'typeorm';
import Redis from 'ioredis';
import * as os from 'os';
import { exec } from 'child_process';
import { promisify } from 'util';
import { ConfigService } from '@nestjs/config';
import Dockerode from 'dockerode';

import { User } from '../users/entities/user.entity';
import { Worker } from '../workers/entities/worker.entity';
import { Transaction, TransactionStatus, TransactionType } from '../payments/entities/transaction.entity';
import { Subscription } from '../subscriptions/entities/subscription.entity';
import { PayPeriod } from '../payroll/entities/pay-period.entity';
import { PayrollRecord } from '../payroll/entities/payroll-record.entity';
import { SupportTicket } from '../support/entities/support-ticket.entity';
import { AdminAuditLog } from './entities/audit-log.entity';

const execAsync = promisify(exec);

// Docker client using dockerode - connects via Docker socket
const docker = new Dockerode({ socketPath: '/var/run/docker.sock' });

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
        @Inject(CACHE_MANAGER) private cacheManager: Cache,
    ) { }

    // ─── Analytics Dashboard ───────────────────────────────────────────────────

    async getDashboardMetrics() {
        const cacheKey = 'admin_dashboard_metrics';
        const cached = await this.cacheManager.get(cacheKey);
        if (cached) {
            return cached;
        }

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
            totalPortalLinks,
            pendingPortalInvites,
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

            // Employee Portal Connections
            this.dataSource.query(`
                SELECT COUNT(*) as count 
                FROM workers WHERE "linkedUserId" IS NOT NULL
            `).then(r => parseInt(r[0]?.count || '0')),

            // Pending Portal Invites
            this.dataSource.query(`
                SELECT COUNT(*) as count 
                FROM workers WHERE "inviteCode" IS NOT NULL AND "linkedUserId" IS NULL
            `).then(r => parseInt(r[0]?.count || '0')),
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

        const result = {
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
                totalPortalLinks,
                pendingPortalInvites,
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

        // Cache for 15 minutes (900000 milliseconds)
        await this.cacheManager.set(cacheKey, result, 900000);
        return result;
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
            const password = this.configService.get('REDIS_PASSWORD');
            const tempClient = new Redis({ host, port, password, lazyConnect: true });
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
            const containers = await docker.listContainers({ all: true });
            
            const containerList = containers.map(c => ({
                name: c.Names[0]?.replace(/^\//, ''),
                status: c.Status,
                image: c.Image,
                healthy: c.State === 'running',
            }));

            return { status: 'ok', containers: containerList };
        } catch {
            return { status: 'unavailable', containers: [] };
        }
    }

    // ─── Container Logs ─────────────────────────────────────────────────

    async getContainers() {
        try {
            const containers = await docker.listContainers({ all: true });
            
            const data = containers.map(c => ({
                name: c.Names[0]?.replace(/^\//, ''),
                status: c.Status,
                image: c.Image,
                healthy: c.State === 'running',
            }));

            return { data };
        } catch (error: any) {
            return { data: [], error: error.message };
        }
    }

    async getContainerLogs(container?: string, lines = 100) {
        try {
            const safeLines = Math.min(lines, 1000);
            let logs: string;

            if (container) {
                // Get logs for specific container using dockerode
                const containerObj = docker.getContainer(container);
                const logStream = await containerObj.logs({
                    stdout: true,
                    stderr: true,
                    tail: safeLines,
                    timestamps: true,
                });
                // Convert buffer to string
                logs = logStream.toString('utf8');
            } else {
                // Get logs from all running containers
                const containers = await docker.listContainers({ all: false });
                const logParts: string[] = [];
                
                for (const c of containers.slice(0, 5)) {
                    const containerObj = docker.getContainer(c.Id);
                    try {
                        const logStream = await containerObj.logs({
                            stdout: true,
                            stderr: true,
                            tail: Math.floor(safeLines / 5),
                            timestamps: true,
                        });
                        logParts.push(`[${c.Names[0]?.replace(/^\//, '')}]\n${logStream.toString('utf8')}`);
                    } catch (e) {
                        // Skip containers that can't be accessed
                    }
                }
                logs = logParts.join('\n');
            }

            // Parse logs - each line: timestamp level message
            const logLines = logs
                .split('\n')
                .filter(line => line.trim())
                .slice(-safeLines)
                .reverse()
                .map(line => {
                    // Try to parse structured log (JSON)
                    try {
                        const parsed = JSON.parse(line);
                        return {
                            timestamp: parsed.timestamp || parsed.time || parsed.ts || new Date().toISOString(),
                            level: parsed.level || parsed.severity || 'LOG',
                            message: parsed.message || parsed.msg || line,
                            raw: line,
                        };
                    } catch {
                        // Plain text log - try to detect level
                        const upperLine = line.toUpperCase();
                        let level = 'LOG';
                        if (upperLine.includes('ERROR') || upperLine.includes('ERR')) level = 'ERROR';
                        else if (upperLine.includes('WARN')) level = 'WARN';
                        else if (upperLine.includes('DEBUG')) level = 'DEBUG';
                        else if (upperLine.includes('INFO')) level = 'INFO';

                        // Try to extract timestamp
                        const timestampMatch = line.match(/^(\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2})/);

                        return {
                            timestamp: timestampMatch ? timestampMatch[1] : new Date().toISOString(),
                            level,
                            message: line,
                            raw: line,
                        };
                    }
                });

            return {
                data: logLines,
                container: container || 'all',
                lines: safeLines,
                total: logLines.length,
            };
        } catch (error) {
            return {
                data: [],
                error: error.message,
                container: container || 'all',
            };
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
        w."linkedUserId",
        w."inviteCode",
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
            recentPeriods,
            topupMethods,
            payoutMethods
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
            `),
            // Top-up Methods (from transactions where type = 'TOPUP' and status = 'COMPLETED')
            this.dataSource.query(`
                SELECT "paymentMethod" as method, COUNT(*) as count, COALESCE(SUM(amount), 0) as volume
                FROM transactions
                WHERE type = 'TOPUP' AND status = 'COMPLETED'
                GROUP BY "paymentMethod"
                ORDER BY volume DESC
            `),
            // Payout Methods (from workers linked to finalized/paid payroll records)
            this.dataSource.query(`
                SELECT w."paymentMethod" as method, COUNT(pr.id) as count, COALESCE(SUM(pr."netSalary"), 0) as volume
                FROM payroll_records pr
                JOIN workers w ON w.id = pr."workerId"
                WHERE pr.status IN ('paid', 'finalized')
                GROUP BY w."paymentMethod"
                ORDER BY volume DESC
            `)
        ]);

        return {
            summary: {
                totalPeriods,
                successfulPeriods,
                totalVolume,
                topupBreakdown: topupMethods.map((m: any) => ({
                    method: m.method || 'Unknown',
                    count: parseInt(m.count),
                    volume: parseFloat(m.volume)
                })),
                payoutBreakdown: payoutMethods.map((m: any) => ({
                    method: m.method || 'Unknown',
                    count: parseInt(m.count),
                    volume: parseFloat(m.volume)
                })),
            },
            recentPeriods: recentPeriods.map((p: any) => ({
                ...p,
                recordCount: parseInt(p.record_count),
                totalNetPay: parseFloat(p.total_net_pay),
            }))
        };
    }

    async getPayPeriods(search?: string, page = 1, limit = 20) {
        // Step 1: Paginate over Employers who have pay periods.
        const [employers, countResult] = await Promise.all([
            this.dataSource.query(`
                SELECT
                    u.id as employer_id,
                    u.email as employer_email,
                    COALESCE(u."businessName", CONCAT(u."firstName", ' ', u."lastName"), u.email) as employer_name,
                    COUNT(DISTINCT pp.id) as total_pay_periods,
                    COALESCE(SUM(pr."netSalary"), 0) as lifetime_net_pay
                FROM users u
                JOIN pay_periods pp ON pp."userId" = u.id
                LEFT JOIN payroll_records pr ON pr."payPeriodId" = pp.id
                ${search ? `WHERE COALESCE(u."businessName", CONCAT(u."firstName", ' ', u."lastName")) ILIKE $1 OR u.email ILIKE $1` : ''}
                GROUP BY u.id
                ORDER BY total_pay_periods DESC
                LIMIT ${limit} OFFSET ${(page - 1) * limit}
            `, search ? [`%${search}%`] : []),
            this.dataSource.query(`
                SELECT COUNT(DISTINCT u.id) as total 
                FROM users u
                JOIN pay_periods pp ON pp."userId" = u.id
                ${search ? `WHERE COALESCE(u."businessName", CONCAT(u."firstName", ' ', u."lastName")) ILIKE $1 OR u.email ILIKE $1` : ''}
            `, search ? [`%${search}%`] : []),
        ]);

        if (employers.length === 0) {
            return { data: [], total: 0, page, limit };
        }

        // Step 2: Fetch the top 3 pay periods for each employer
        const employerIds = employers.map((e: any) => e.employer_id);
        const placeholders = employerIds.map((_: any, i: number) => `$${i + 1}`).join(',');

        const recentPayPeriods = await this.dataSource.query(`
            WITH RankedPeriods AS (
                SELECT 
                    pp.id,
                    pp."userId" as employer_id,
                    pp.status,
                    pp."startDate",
                    pp."endDate",
                    pp."createdAt",
                    ROW_NUMBER() OVER(PARTITION BY pp."userId" ORDER BY pp."createdAt" DESC) as rn
                FROM pay_periods pp
                WHERE pp."userId" IN (${placeholders})
            )
            SELECT 
                rp.*,
                COUNT(pr.id) as record_count,
                COALESCE(SUM(pr."netSalary"), 0) as total_net_pay
            FROM RankedPeriods rp
            LEFT JOIN payroll_records pr ON pr."payPeriodId" = rp.id
            WHERE rp.rn <= 3
            GROUP BY rp.id, rp.employer_id, rp.status, rp."startDate", rp."endDate", rp."createdAt", rp.rn
            ORDER BY rp.employer_id, rp.rn ASC
        `, employerIds);

        // Map periods to employers
        const formattedData = employers.map((emp: any) => ({
            ...emp,
            totalPayPeriods: parseInt(emp.total_pay_periods),
            lifetimeNetPay: parseFloat(emp.lifetime_net_pay),
            recentPeriods: recentPayPeriods
                .filter((pp: any) => pp.employer_id === emp.employer_id)
                .map((pp: any) => ({
                    id: pp.id,
                    status: pp.status,
                    startDate: pp.startDate,
                    endDate: pp.endDate,
                    createdAt: pp.createdAt,
                    recordCount: parseInt(pp.record_count),
                    totalNetPay: parseFloat(pp.total_net_pay),
                }))
        }));

        return {
            data: formattedData,
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

    async getAuditLogs(filters: {
        page?: number;
        limit?: number;
        entityType?: string;
        action?: string;
        adminEmail?: string;
        startDate?: string;
        endDate?: string;
    }) {
        const { page = 1, limit = 20 } = filters;
        const offset = (page - 1) * limit;

        const query = this.auditLogRepo.createQueryBuilder('log')
            .leftJoin('users', 'u', 'u.id = log."adminUserId"')
            .select([
                'log.id as id',
                'log.action as action',
                'log."entityType" as "entityType"',
                'log."entityId" as "entityId"',
                'log."oldValues" as "oldValues"',
                'log."newValues" as "newValues"',
                'log."ipAddress" as "ipAddress"',
                'log."createdAt" as "createdAt"',
                'u.email as "adminEmail"'
            ]);

        if (filters.entityType) {
            query.andWhere('log."entityType" = :entityType', { entityType: filters.entityType });
        }
        if (filters.action) {
            query.andWhere('log.action = :action', { action: filters.action });
        }
        if (filters.adminEmail) {
            query.andWhere('u.email ILIKE :adminEmail', { adminEmail: `%${filters.adminEmail}%` });
        }
        if (filters.startDate) {
            query.andWhere('log."createdAt" >= :startDate', { startDate: filters.startDate });
        }
        if (filters.endDate) {
            query.andWhere('log."createdAt" <= :endDate', { endDate: filters.endDate });
        }

        query.orderBy('log."createdAt"', 'DESC')
            .offset(offset)
            .limit(limit);

        const logs = await query.getRawMany();
        const total = await query.getCount();

        return {
            data: logs,
            total,
            page,
            limit,
        };
    }
}
