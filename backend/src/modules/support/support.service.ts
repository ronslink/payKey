import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SupportTicket, TicketStatus, TicketCategory, TicketPriority } from './entities/support-ticket.entity';
import { SupportMessage, SenderRole } from './entities/support-message.entity';

@Injectable()
export class SupportService {
    constructor(
        @InjectRepository(SupportTicket)
        private readonly ticketRepo: Repository<SupportTicket>,
        @InjectRepository(SupportMessage)
        private readonly messageRepo: Repository<SupportMessage>,
    ) { }

    // ─── User-facing ─────────────────────────────────────────────────────────

    async createTicket(userId: string, data: {
        subject: string;
        description: string;
        category?: TicketCategory;
    }): Promise<SupportTicket> {
        const ticket = this.ticketRepo.create({
            userId,
            subject: data.subject,
            description: data.description,
            category: data.category || TicketCategory.GENERAL,
            status: TicketStatus.OPEN,
        });
        const saved = await this.ticketRepo.save(ticket);

        // Create initial message from the user's description
        await this.messageRepo.save(
            this.messageRepo.create({
                ticketId: saved.id,
                senderId: userId,
                senderRole: SenderRole.USER,
                message: data.description,
            }),
        );

        return this.getTicketWithMessages(saved.id, userId);
    }

    async getUserTickets(userId: string): Promise<SupportTicket[]> {
        return this.ticketRepo.find({
            where: { userId },
            order: { updatedAt: 'DESC' },
        });
    }

    async getTicketWithMessages(ticketId: string, userId?: string): Promise<SupportTicket> {
        const ticket = await this.ticketRepo.findOne({
            where: { id: ticketId },
            relations: ['messages'],
            order: { messages: { createdAt: 'ASC' } } as any,
        });

        if (!ticket) throw new NotFoundException('Ticket not found');
        if (userId && ticket.userId !== userId) throw new ForbiddenException('Access denied');

        return ticket;
    }

    async addUserMessage(ticketId: string, userId: string, message: string): Promise<SupportMessage> {
        const ticket = await this.ticketRepo.findOne({ where: { id: ticketId } });
        if (!ticket) throw new NotFoundException('Ticket not found');
        if (ticket.userId !== userId) throw new ForbiddenException('Access denied');
        if (ticket.status === TicketStatus.CLOSED) throw new ForbiddenException('Cannot reply to a closed ticket');

        // Re-open resolved tickets when user replies
        if (ticket.status === TicketStatus.RESOLVED) {
            await this.ticketRepo.update(ticketId, { status: TicketStatus.OPEN });
        }

        return this.messageRepo.save(
            this.messageRepo.create({
                ticketId,
                senderId: userId,
                senderRole: SenderRole.USER,
                message,
            }),
        );
    }

    // ─── Admin ────────────────────────────────────────────────────────────────

    async getAllTickets(filters: {
        status?: TicketStatus;
        category?: TicketCategory;
        priority?: TicketPriority;
        search?: string;
        page?: number;
        limit?: number;
    }) {
        const { status, category, priority, search, page = 1, limit = 20 } = filters;

        const qb = this.ticketRepo.createQueryBuilder('ticket')
            .leftJoinAndSelect('ticket.messages', 'messages')
            .leftJoinAndMapOne('ticket.user', 'users', 'u', 'u.id = ticket.userId')
            .orderBy('ticket.updatedAt', 'DESC')
            .take(limit)
            .skip((page - 1) * limit);

        if (status) qb.andWhere('ticket.status = :status', { status });
        if (category) qb.andWhere('ticket.category = :category', { category });
        if (priority) qb.andWhere('ticket.priority = :priority', { priority });
        if (search) {
            qb.andWhere('(ticket.subject ILIKE :search OR u.email ILIKE :search)', {
                search: `%${search}%`,
            });
        }

        const [data, total] = await qb.getManyAndCount();
        return { data, total, page, limit };
    }

    async updateTicket(ticketId: string, updates: {
        status?: TicketStatus;
        priority?: TicketPriority;
        adminNotes?: string;
    }): Promise<SupportTicket> {
        await this.ticketRepo.update(ticketId, updates);
        return this.getTicketWithMessages(ticketId);
    }

    async addAdminReply(ticketId: string, adminId: string, message: string): Promise<SupportMessage> {
        const ticket = await this.ticketRepo.findOne({ where: { id: ticketId } });
        if (!ticket) throw new NotFoundException('Ticket not found');

        // Auto-set to IN_PROGRESS on first admin reply
        if (ticket.status === TicketStatus.OPEN) {
            await this.ticketRepo.update(ticketId, { status: TicketStatus.IN_PROGRESS });
        }

        return this.messageRepo.save(
            this.messageRepo.create({
                ticketId,
                senderId: adminId,
                senderRole: SenderRole.ADMIN,
                message,
            }),
        );
    }
}
