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
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { PlatinumGuard } from '../auth/platinum.guard';
import { TimeTrackingService } from './time-tracking.service';
import { TimeEntryPayrollDecision } from './entities/time-entry.entity';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';

/** The JWT payload the auth guard attaches to the request. */
interface AuthenticatedRequest {
  user: {
    userId: string;
    role: string;
    employerId?: string;
    workerId?: string;
    tier?: string;
  };
}

@ApiTags('Time Tracking')
@ApiBearerAuth()
@Controller('time-tracking')
@UseGuards(JwtAuthGuard, PlatinumGuard)
export class TimeTrackingController {
  constructor(private readonly timeTrackingService: TimeTrackingService) {}

  private assertWorkerCanAccess(req: AuthenticatedRequest, workerId: string) {
    if (req.user.role === 'WORKER' && req.user.workerId !== workerId) {
      throw new ForbiddenException(
        'Workers can only access their own time tracking',
      );
    }
  }

  /**
   * Attendance is evidence of where the employee actually was, so only the
   * employee's own device may start or stop their clock. An employer records
   * hours with `POST /time-tracking/entries` and corrects them with
   * `PATCH /time-tracking/adjust/:entryId` instead.
   */
  private assertOwnDevice(req: AuthenticatedRequest) {
    if (req.user.role !== 'WORKER') {
      throw new ForbiddenException(
        'Only the employee can clock themselves in or out. Record hours with an employer time entry instead.',
      );
    }
  }

  /**
   * Manual entries and corrections are the employer's record of hours; an
   * employee records theirs by clocking in and out.
   */
  private assertEmployer(req: AuthenticatedRequest) {
    if (req.user.role === 'WORKER') {
      throw new ForbiddenException(
        'Employees record their own hours by clocking in and out.',
      );
    }
  }

  private parseLocation(body: { lat?: number; lng?: number }) {
    return typeof body.lat === 'number' && typeof body.lng === 'number'
      ? { lat: body.lat, lng: body.lng }
      : undefined;
  }

  /**
   * A worker's records belong to their employer, and the token must say which
   * employer that is.
   */
  private employerIdFor(req: AuthenticatedRequest): string {
    const employerId = req.user.employerId;
    if (!employerId) {
      throw new ForbiddenException(
        'This employee account is not linked to an employer',
      );
    }
    return employerId;
  }

  private ownerIdFor(req: AuthenticatedRequest): string {
    return req.user.role === 'WORKER'
      ? this.employerIdFor(req)
      : req.user.userId;
  }

  @Post('clock-in/:workerId')
  @ApiOperation({ summary: 'Clock in a worker' })
  async clockIn(
    @Request() req: AuthenticatedRequest,
    @Param('workerId') workerId: string,
    @Body() body: { lat?: number; lng?: number; propertyId?: string },
  ) {
    const location = this.parseLocation(body);

    this.assertOwnDevice(req);
    this.assertWorkerCanAccess(req, workerId);

    // A worker always records against their own employer; there is no other
    // role that may reach this route.
    const ownerId = this.employerIdFor(req);
    const recorderId = req.user.userId;

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
    @Request() req: AuthenticatedRequest,
    @Param('workerId') workerId: string,
    @Body()
    body: {
      breakMinutes?: number;
      notes?: string;
      lat?: number;
      lng?: number;
    },
  ) {
    const location = this.parseLocation(body);

    this.assertOwnDevice(req);
    this.assertWorkerCanAccess(req, workerId);

    const ownerId = this.employerIdFor(req);
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
    @Request() req: AuthenticatedRequest,
    @Param('workerId') workerId: string,
    @Body() body: { lat: number; lng: number },
  ) {
    this.assertOwnDevice(req);
    this.assertWorkerCanAccess(req, workerId);

    const ownerId = this.employerIdFor(req);
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
  async getStatus(
    @Request() req: AuthenticatedRequest,
    @Param('workerId') workerId: string,
  ) {
    const ownerId = this.ownerIdFor(req);

    this.assertWorkerCanAccess(req, workerId);

    return this.timeTrackingService.getStatus(workerId, ownerId);
  }

  @Get('live-status')
  @ApiOperation({ summary: 'Get live clock-in status of all workers' })
  async getLiveStatus(@Request() req: AuthenticatedRequest) {
    return this.timeTrackingService.getLiveStatus(req.user.userId);
  }

  @Get('entries/:workerId')
  @ApiOperation({ summary: 'Get time entries for a worker' })
  async getEntriesForWorker(
    @Request() req: AuthenticatedRequest,
    @Param('workerId') workerId: string,
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
  ) {
    const ownerId = this.ownerIdFor(req);

    this.assertWorkerCanAccess(req, workerId);

    return this.timeTrackingService.getEntriesForWorker(
      workerId,
      ownerId,
      new Date(startDate),
      new Date(endDate),
    );
  }

  @Get('entries')
  @ApiOperation({ summary: 'Get all time entries for employer' })
  async getAllEntries(
    @Request() req: AuthenticatedRequest,
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
    @Request() req: AuthenticatedRequest,
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
  ) {
    return this.timeTrackingService.getAttendanceSummary(
      req.user.userId,
      new Date(startDate),
      new Date(endDate),
    );
  }

  @Get('payroll-review')
  @ApiOperation({
    summary: 'Hours by source and the entries awaiting a payroll decision',
  })
  async getPayrollReview(
    @Request() req: AuthenticatedRequest,
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
  ) {
    this.assertEmployer(req);

    return this.timeTrackingService.getPayrollReview(
      req.user.userId,
      new Date(startDate),
      new Date(endDate),
    );
  }

  @Post('payroll-review/decision')
  @ApiOperation({
    summary: 'Include or exclude time entries from payroll (employer only)',
  })
  async decidePayroll(
    @Request() req: AuthenticatedRequest,
    @Body() body: { entryIds: string[]; decision: string },
  ) {
    this.assertEmployer(req);

    const requested = (body.decision ?? '').toUpperCase();
    const allowed: string[] = Object.values(TimeEntryPayrollDecision);
    if (!allowed.includes(requested)) {
      throw new BadRequestException(
        `Decision must be one of ${allowed.join(', ')}`,
      );
    }

    return this.timeTrackingService.decideEntries(
      req.user.userId,
      body.entryIds,
      requested as TimeEntryPayrollDecision,
    );
  }

  @Post('entries')
  @ApiOperation({ summary: 'Record time for a worker (employer only)' })
  async createEntry(
    @Request() req: AuthenticatedRequest,
    @Body()
    body: {
      workerId: string;
      clockIn: string;
      clockOut: string;
      breakMinutes?: number;
      notes?: string;
      propertyId?: string;
    },
  ) {
    this.assertEmployer(req);

    return this.timeTrackingService.createEntry(
      req.user.userId,
      req.user.userId,
      {
        workerId: body.workerId,
        clockIn: new Date(body.clockIn),
        clockOut: new Date(body.clockOut),
        breakMinutes: body.breakMinutes,
        notes: body.notes,
        propertyId: body.propertyId,
      },
    );
  }

  @Patch('adjust/:entryId')
  @ApiOperation({ summary: 'Adjust a time entry (employer only)' })
  async adjustEntry(
    @Request() req: AuthenticatedRequest,
    @Param('entryId') entryId: string,
    @Body()
    body: {
      clockIn?: string;
      clockOut?: string;
      breakMinutes?: number;
      reason: string;
    },
  ) {
    this.assertEmployer(req);

    return this.timeTrackingService.adjustEntry(entryId, req.user.userId, {
      clockIn: body.clockIn ? new Date(body.clockIn) : undefined,
      clockOut: body.clockOut ? new Date(body.clockOut) : undefined,
      breakMinutes: body.breakMinutes,
      reason: body.reason,
    });
  }
}
