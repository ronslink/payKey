import {
  Controller,
  Get,
  Post,
  Put,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';
import { SupportService } from './support.service';
import {
  TicketStatus,
  TicketCategory,
  TicketPriority,
} from './entities/support-ticket.entity';

@Controller('api/admin/support')
@UseGuards(JwtAuthGuard, AdminGuard, RolesGuard)
export class AdminSupportController {
  constructor(private readonly supportService: SupportService) {}

  @Get('tickets')
  getAllTickets(
    @Query('status') status?: TicketStatus,
    @Query('category') category?: TicketCategory,
    @Query('priority') priority?: TicketPriority,
    @Query('search') search?: string,
    @Query('page') page = '1',
    @Query('limit') limit = '20',
  ) {
    return this.supportService.getAllTickets({
      status,
      category,
      priority,
      search,
      page: parseInt(page),
      limit: parseInt(limit),
    });
  }

  @Get('tickets/:id')
  getTicket(@Param('id') id: string) {
    return this.supportService.getTicketWithMessages(id);
  }

  @Put('tickets/:id')
  @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
  updateTicket(
    @Param('id') id: string,
    @Body()
    body: {
      status?: TicketStatus;
      priority?: TicketPriority;
      adminNotes?: string;
    },
  ) {
    return this.supportService.updateTicket(id, body);
  }

  @Post('tickets/:id/messages')
  @Roles(UserRole.SUPER_ADMIN, UserRole.ADMIN)
  addReply(
    @Request() req: any,
    @Param('id') id: string,
    @Body() body: { message: string },
  ) {
    return this.supportService.addAdminReply(id, req.user.id, body.message);
  }
}
