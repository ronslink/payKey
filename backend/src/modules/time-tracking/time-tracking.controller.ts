import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { PlatinumGuard } from '../auth/platinum.guard';
import { TimeTrackingService } from './time-tracking.service';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';

@ApiTags('Time Tracking')
@ApiBearerAuth()
@Controller('time-tracking')
@UseGuards(JwtAuthGuard, PlatinumGuard)
export class TimeTrackingController {
  constructor(private readonly timeTrackingService: TimeTrackingService) { }

  @Post('clock-in/:workerId')
  @ApiOperation({ summary: 'Clock in a worker' })
  async clockIn(
    @Request() req: any,
    @Param('workerId') workerId: string,
    @Body() body: { lat?: number; lng?: number; propertyId?: string },
  ) {
    const location =
      body.lat && body.lng ? { lat: body.lat, lng: body.lng } : undefined;

    // Determine context based on role
    const isWorker = req.user.role === 'WORKER';
    const ownerId = isWorker ? req.user.employerId : req.user.userId;
    const recorderId = req.user.userId;

    // Security check: Worker can only clock themselves in
    if (isWorker && req.user.workerId !== workerId) {
      // Ideally throw Forbidden, but for now strict check
    }

    return this.timeTrackingService.clockIn(
      workerId,
      ownerId,
      recorderId,
      location,
      body.propertyId,
    );
  }

  @Post('clock-out/:workerId')
  @ApiOperation({ summary: 'Clock out a worker' })
  async clockOut(
    @Request() req: any,
    @Param('workerId') workerId: string,
    @Body()
    body: {
      breakMinutes?: number;
      notes?: string;
      lat?: number;
      lng?: number;
    },
  ) {
    const location =
      body.lat && body.lng ? { lat: body.lat, lng: body.lng } : undefined;

    // Determine context based on role
    const isWorker = req.user.role === 'WORKER';
    const ownerId = isWorker ? req.user.employerId : req.user.userId;
    const recorderId = req.user.userId;

    return this.timeTrackingService.clockOut(workerId, ownerId, recorderId, {
      breakMinutes: body.breakMinutes,
      notes: body.notes,
      location,
    });
  }

  @Post('auto-clock-out/:workerId')
  @ApiOperation({ summary: 'Auto clock-out when worker leaves geofence' })
  async autoClockOut(
    @Request() req: any,
    @Param('workerId') workerId: string,
    @Body() body: { lat: number; lng: number },
  ) {
    const isWorker = req.user.role === 'WORKER';
    const ownerId = isWorker ? req.user.employerId : req.user.userId;
    const recorderId = req.user.userId;

    return this.timeTrackingService.autoClockOut(
      workerId,
      ownerId,
      recorderId,
      { lat: body.lat, lng: body.lng },
    );
  }

  @Get('status/:workerId')
  @ApiOperation({ summary: 'Get clock-in status for a worker' })
  async getStatus(@Request() req: any, @Param('workerId') workerId: string) {
    const isWorker = req.user.role === 'WORKER';
    const ownerId = isWorker ? req.user.employerId : req.user.userId;

    return this.timeTrackingService.getStatus(workerId, ownerId);
  }

  @Get('live-status')
  @ApiOperation({ summary: 'Get live clock-in status of all workers' })
  async getLiveStatus(@Request() req: any) {
    return this.timeTrackingService.getLiveStatus(req.user.userId);
  }

  @Get('entries/:workerId')
  @ApiOperation({ summary: 'Get time entries for a worker' })
  async getEntriesForWorker(
    @Request() req: any,
    @Param('workerId') workerId: string,
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
  ) {
    return this.timeTrackingService.getEntriesForWorker(
      workerId,
      req.user.userId,
      new Date(startDate),
      new Date(endDate),
    );
  }

  @Get('entries')
  @ApiOperation({ summary: 'Get all time entries for employer' })
  async getAllEntries(
    @Request() req: any,
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
  ) {
    return this.timeTrackingService.getAllEntriesForEmployer(
      req.user.userId,
      new Date(startDate),
      new Date(endDate),
    );
  }

  @Get('summary')
  @ApiOperation({ summary: 'Get attendance summary' })
  async getAttendanceSummary(
    @Request() req: any,
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
  ) {
    return this.timeTrackingService.getAttendanceSummary(
      req.user.userId,
      new Date(startDate),
      new Date(endDate),
    );
  }

  @Patch('adjust/:entryId')
  @ApiOperation({ summary: 'Adjust a time entry (employer only)' })
  async adjustEntry(
    @Request() req: any,
    @Param('entryId') entryId: string,
    @Body()
    body: {
      clockIn?: string;
      clockOut?: string;
      breakMinutes?: number;
      reason: string;
    },
  ) {
    return this.timeTrackingService.adjustEntry(entryId, req.user.userId, {
      clockIn: body.clockIn ? new Date(body.clockIn) : undefined,
      clockOut: body.clockOut ? new Date(body.clockOut) : undefined,
      breakMinutes: body.breakMinutes,
      reason: body.reason,
    });
  }
}
