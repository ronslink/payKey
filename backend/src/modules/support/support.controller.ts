import {
  Controller,
  Get,
  Post,
  Put,
  Body,
  Param,
  UseGuards,
  Request,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { SupportService } from './support.service';
import { TicketCategory } from './entities/support-ticket.entity';

@Controller('support')
@UseGuards(JwtAuthGuard)
export class SupportController {
  constructor(private readonly supportService: SupportService) {}

  @Post('tickets')
  createTicket(
    @Request() req: any,
    @Body()
    body: { subject: string; description: string; category?: TicketCategory },
  ) {
    return this.supportService.createTicket(req.user.userId, body);
  }

  @Get('tickets')
  getMyTickets(@Request() req: any) {
    return this.supportService.getUserTickets(req.user.userId);
  }

  @Get('tickets/:id')
  getTicket(@Request() req: any, @Param('id') id: string) {
    return this.supportService.getTicketWithMessages(id, req.user.userId);
  }

  @Post('tickets/:id/messages')
  addMessage(
    @Request() req: any,
    @Param('id') id: string,
    @Body() body: { message: string },
  ) {
    return this.supportService.addUserMessage(id, req.user.userId, body.message);
  }
}
