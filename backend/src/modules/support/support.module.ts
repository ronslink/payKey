import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SupportTicket } from './entities/support-ticket.entity';
import { SupportMessage } from './entities/support-message.entity';
import { SupportController } from './support.controller';
import { SupportService } from './support.service';
import { AdminSupportController } from './admin-support.controller';

@Module({
    imports: [TypeOrmModule.forFeature([SupportTicket, SupportMessage])],
    controllers: [SupportController, AdminSupportController],
    providers: [SupportService],
    exports: [SupportService],
})
export class SupportModule { }
