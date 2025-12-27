import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  UseGuards,
  Request,
  Res,
  Delete,
} from '@nestjs/common';
import { WorkersService } from './workers.service';
import { CreateWorkerDto } from './dto/create-worker.dto';
import { CreateTerminationDto } from './dto/termination.dto';
import {
  CreateLeaveRequestDto,
  ApproveLeaveRequestDto,
  UpdateLeaveRequestDto,
} from './dto/create-leave-request.dto';
import { TerminationService } from './services/termination.service';
import { LeaveManagementService } from './services/leave-management.service';
import type { AuthenticatedRequest } from '../../common/interfaces/user.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { SubscriptionGuard } from '../subscriptions/subscription.guard';
import { PlatinumGuard } from '../auth/platinum.guard'; // Import
import type { Response } from 'express';

@Controller('workers')
@UseGuards(JwtAuthGuard)
export class WorkersController {
  constructor(
    private readonly workersService: WorkersService,
    private readonly terminationService: TerminationService,
    private readonly leaveManagementService: LeaveManagementService,
  ) { }

  // ======================================================================================
  // STATIC ROUTES (MUST BE BEFORE DYNAMIC ROUTES)
  // ======================================================================================

  @Get()
  async findAll(@Request() req: AuthenticatedRequest, @Res() res: Response) {
    const workers = await this.workersService.findAll(req.user.userId);

    // Explicitly prevent caching to avoid 304 responses
    res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
    res.setHeader('Pragma', 'no-cache');
    res.setHeader('Expires', '0');
    res.setHeader('ETag', `"workers-${Date.now()}-${workers.length}"`);
    res.setHeader('Last-Modified', new Date().toUTCString());

    return res.json(workers);
  }

  @Post()
  @UseGuards(SubscriptionGuard)
  create(
    @Request() req: AuthenticatedRequest,
    @Body() createWorkerDto: CreateWorkerDto,
  ) {
    return this.workersService.create(req.user.userId, createWorkerDto);
  }

  @Get('stats')
  getStats(@Request() req: AuthenticatedRequest) {
    return this.workersService.getWorkerStats(req.user.userId);
  }

  @Get('terminated/history')
  getTerminationHistory(@Request() req: AuthenticatedRequest) {
    return this.terminationService.getTerminationHistory(req.user.userId);
  }

  // --- Leave Management Static Routes ---

  @Get('leave-requests')
  @UseGuards(SubscriptionGuard, PlatinumGuard)
  getLeaveRequests(@Request() req: AuthenticatedRequest) {
    return this.leaveManagementService.getLeaveRequestsForUser(req.user.userId);
  }

  @Patch('leave-requests/:requestId/approve')
  @UseGuards(SubscriptionGuard, PlatinumGuard)
  approveLeaveRequest(
    @Request() req: AuthenticatedRequest,
    @Param('requestId') requestId: string,
    @Body() approveLeaveRequestDto: ApproveLeaveRequestDto,
  ) {
    return this.leaveManagementService.approveLeaveRequest(
      req.user.userId,
      requestId,
      approveLeaveRequestDto,
    );
  }

  @Patch('leave-requests/:requestId')
  @UseGuards(SubscriptionGuard, PlatinumGuard)
  updateLeaveRequest(
    @Request() req: AuthenticatedRequest,
    @Param('requestId') requestId: string,
    @Body() updateLeaveRequestDto: UpdateLeaveRequestDto,
  ) {
    return this.leaveManagementService.updateLeaveRequest(
      req.user.userId,
      requestId,
      updateLeaveRequestDto,
    );
  }

  @Delete('leave-requests/:requestId')
  @UseGuards(SubscriptionGuard, PlatinumGuard)
  deleteLeaveRequest(
    @Request() req: AuthenticatedRequest,
    @Param('requestId') requestId: string,
  ) {
    return this.leaveManagementService.cancelLeaveRequest(
      req.user.userId,
      requestId,
    );
  }

  // ======================================================================================
  // DYNAMIC ROUTES (WITH :id PARAMETER) - MUST BE AFTER STATIC ROUTES
  // ======================================================================================

  @Get(':id')
  findOne(@Request() req: AuthenticatedRequest, @Param('id') id: string) {
    return this.workersService.findOne(id, req.user.userId);
  }

  @Patch(':id')
  update(
    @Request() req: AuthenticatedRequest,
    @Param('id') id: string,
    @Body() updateWorkerDto: Partial<CreateWorkerDto>,
  ) {
    return this.workersService.update(id, req.user.userId, updateWorkerDto);
  }

  @Delete(':id')
  remove(@Request() req: AuthenticatedRequest, @Param('id') id: string) {
    return this.workersService.remove(id, req.user.userId);
  }

  @Post(':id/calculate-final-payment')
  calculateFinalPayment(
    @Request() req: AuthenticatedRequest,
    @Param('id') id: string,
    @Body('terminationDate') terminationDate: string,
  ) {
    return this.terminationService.calculateFinalPayment(
      id,
      req.user.userId,
      new Date(terminationDate),
    );
  }

  @Post(':id/terminate')
  async terminateWorker(
    @Request() req: AuthenticatedRequest,
    @Param('id') id: string,
    @Body() dto: CreateTerminationDto,
  ) {
    console.log('=== Termination Request Debug ===');
    console.log('Worker ID:', id);
    console.log('User ID:', req.user?.userId);
    console.log('DTO:', JSON.stringify(dto, null, 2));
    console.log('================================');

    try {
      const result = await this.terminationService.terminateWorker(id, req.user.userId, dto);
      return result;
    } catch (error: any) {
      console.error('=== Termination Error ===');
      console.error('Message:', error.message);
      console.error('Stack:', error.stack);
      console.error('==========================');
      throw error;
    }
  }

  @Post(':id/leave-requests')
  @UseGuards(SubscriptionGuard, PlatinumGuard)
  createLeaveRequest(
    @Request() req: AuthenticatedRequest,
    @Param('id') workerId: string,
    @Body() createLeaveRequestDto: CreateLeaveRequestDto,
  ) {
    return this.leaveManagementService.createLeaveRequest(
      req.user.userId,
      workerId,
      createLeaveRequestDto,
    );
  }

  @Get(':id/leave-requests')
  @UseGuards(SubscriptionGuard, PlatinumGuard)
  getWorkerLeaveRequests(
    @Request() req: AuthenticatedRequest,
    @Param('id') workerId: string,
  ) {
    return this.leaveManagementService.getLeaveRequestsForWorker(
      req.user.userId,
      workerId,
    );
  }

  @Get(':id/leave-balance')
  @UseGuards(SubscriptionGuard, PlatinumGuard)
  getLeaveBalance(
    @Request() req: AuthenticatedRequest,
    @Param('id') workerId: string,
  ) {
    return this.leaveManagementService.getLeaveBalance(
      workerId,
      req.user.userId,
    );
  }
}
