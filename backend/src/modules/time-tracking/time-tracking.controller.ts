import {
  Controller,
  Post,
  Get,
  Body,
  UseGuards,
  Request,
  Query,
} from '@nestjs/common';
import { TimeTrackingService } from './time-tracking.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ClockInDto, ClockOutDto } from './dto/time-tracking.dto';

@Controller('time-tracking')
@UseGuards(JwtAuthGuard)
export class TimeTrackingController {
  constructor(private readonly timeTrackingService: TimeTrackingService) {}

  @Post('clock-in')
  async clockIn(@Request() req: any, @Body() dto: ClockInDto) {
    return this.timeTrackingService.clockIn(req.user.userId, dto);
  }

  @Post('clock-out')
  async clockOut(@Request() req: any, @Body() dto: ClockOutDto) {
    return this.timeTrackingService.clockOut(req.user.userId, dto);
  }

  @Get('active')
  async getActiveEntry(
    @Request() req: any,
    @Query('workerId') workerId: string,
  ) {
    return this.timeTrackingService.getActiveEntry(req.user.userId, workerId);
  }

  @Get('entries')
  async getTimeEntries(
    @Request() req: any,
    @Query('workerId') workerId?: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    const start = startDate ? new Date(startDate) : undefined;
    const end = endDate ? new Date(endDate) : undefined;
    return this.timeTrackingService.getTimeEntries(
      req.user.userId,
      workerId,
      start,
      end,
    );
  }
}
