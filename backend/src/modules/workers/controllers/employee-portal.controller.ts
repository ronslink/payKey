import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  UseGuards,
  Request,
  ForbiddenException,
} from '@nestjs/common';
import { JwtAuthGuard } from '../../auth/jwt-auth.guard';
import { EmployeePortalService } from '../services/employee-portal.service';
import { LeaveManagementService } from '../services/leave-management.service';
import { FeatureAccessService } from '../../subscriptions/feature-access.service';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';

@ApiTags('Employee Portal')
@Controller('employee-portal')
export class EmployeePortalController {
  constructor(
    private readonly employeePortalService: EmployeePortalService,
    private readonly leaveManagementService: LeaveManagementService,
    private readonly featureAccessService: FeatureAccessService,
  ) {}

  private async assertFullFeatureAccess(
    userId: string,
    featureKey: string,
    message: string,
  ) {
    const featureAccess = await this.featureAccessService.checkFeatureAccess(
      userId,
      featureKey,
    );

    if (!featureAccess.hasAccess || featureAccess.isPreview) {
      throw new ForbiddenException(message);
    }
  }

  // ============================================================
  // PUBLIC ENDPOINTS (No Auth Required)
  // ============================================================

  @Post('claim-account')
  @ApiOperation({
    summary: 'Employee claims their account with phone + invite code',
  })
  async claimAccount(
    @Body() body: { phoneNumber: string; inviteCode: string; pin: string },
  ) {
    return this.employeePortalService.claimAccount(
      body.phoneNumber,
      body.inviteCode,
      body.pin,
    );
  }

  @Post('login')
  @ApiOperation({ summary: 'Employee login with phone + PIN' })
  async employeeLogin(@Body() body: { phoneNumber: string; pin: string }) {
    return this.employeePortalService.employeeLogin(body.phoneNumber, body.pin);
  }

  // ============================================================
  // EMPLOYER ENDPOINTS (Authenticated as Employer)
  // ============================================================

  @Post('invite/:workerId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Generate invite code for a worker' })
  async generateInvite(
    @Request() req: any,
    @Param('workerId') workerId: string,
  ) {
    await this.assertFullFeatureAccess(
      req.user.userId,
      'employee_portal',
      'Employee portal invitations require a Platinum subscription.',
    );

    return this.employeePortalService.generateInviteCode(
      workerId,
      req.user.userId,
    );
  }

  @Get('invite-status/:workerId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Check if worker has been invited or has account' })
  async checkInviteStatus(
    @Request() req: any,
    @Param('workerId') workerId: string,
  ) {
    await this.assertFullFeatureAccess(
      req.user.userId,
      'employee_portal',
      'Employee portal requires a Platinum subscription.',
    );

    return this.employeePortalService.checkInviteStatus(
      workerId,
      req.user.userId,
    );
  }

  // ============================================================
  // EMPLOYEE ENDPOINTS (Authenticated as Employee)
  // ============================================================

  @Get('my-profile')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get employee profile and worker info' })
  async getMyProfile(@Request() req: any) {
    await this.assertFullFeatureAccess(
      req.user.employerId,
      'employee_portal',
      'Employee portal access requires your employer to have a Platinum subscription.',
    );

    const worker = await this.employeePortalService.getWorkerProfile(
      req.user.workerId,
    );
    return {
      userId: req.user.userId,
      role: req.user.role,
      // Map worker details explicitly to prevent collisions
      workerId: worker.id,
      employerId: worker.userId,
      name: worker.name,
      email: worker.email,
      phoneNumber: worker.phoneNumber,
      paymentMethod: worker.paymentMethod,
      bankName: worker.bankName,
      bankCode: worker.bankCode,
      bankAccount: worker.bankAccount,
      mpesaNumber: worker.mpesaNumber,
    };
  }

  @Get('my-property')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Get worker assigned property (Platinum only)',
  })
  async getMyProperty(@Request() req: any) {
    await this.assertFullFeatureAccess(
      req.user.employerId,
      'employee_portal',
      'Employee portal access requires your employer to have a Platinum subscription.',
    );

    await this.assertFullFeatureAccess(
      req.user.employerId,
      'geofencing',
      'Property details require your employer to have a Platinum subscription.',
    );

    return this.employeePortalService.getWorkerProperty(req.user.workerId);
  }

  @Get('employer-properties')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Get all employer properties for clock-in selection (Platinum only)',
  })
  async getEmployerProperties(@Request() req: any) {
    await this.assertFullFeatureAccess(
      req.user.employerId,
      'employee_portal',
      'Employee portal access requires your employer to have a Platinum subscription.',
    );

    await this.assertFullFeatureAccess(
      req.user.employerId,
      'geofencing',
      'Multi-property selection requires your employer to have a Platinum subscription.',
    );

    return this.employeePortalService.getEmployerProperties(
      req.user.employerId,
    );
  }

  @Get('my-leave-balance')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get employee leave balance' })
  async getMyLeaveBalance(@Request() req: any) {
    await this.assertFullFeatureAccess(
      req.user.employerId,
      'employee_portal',
      'Employee portal access requires your employer to have a Platinum subscription.',
    );

    // Employee can only see their own balance
    return this.leaveManagementService.getLeaveBalance(
      req.user.workerId,
      req.user.employerId,
    );
  }

  @Get('my-leave-requests')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get employee leave requests' })
  async getMyLeaveRequests(@Request() req: any) {
    await this.assertFullFeatureAccess(
      req.user.employerId,
      'employee_portal',
      'Employee portal access requires your employer to have a Platinum subscription.',
    );

    return this.leaveManagementService.getLeaveRequestsForWorker(
      req.user.employerId,
      req.user.workerId,
    );
  }

  @Post('request-leave')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Employee requests leave' })
  async requestLeave(
    @Request() req: any,
    @Body()
    body: {
      leaveType: string;
      startDate: string;
      endDate: string;
      reason?: string;
    },
  ) {
    await this.assertFullFeatureAccess(
      req.user.employerId,
      'employee_portal',
      'Employee portal access requires your employer to have a Platinum subscription.',
    );

    return this.leaveManagementService.createLeaveRequest(
      req.user.employerId, // Employer's userId for ownership
      req.user.workerId, // Employee's workerId
      {
        leaveType: body.leaveType as any,
        startDate: body.startDate,
        endDate: body.endDate,
        reason: body.reason,
        paidLeave: true, // Default to paid leave
        origin: 'WORKER' as any, // Mark as employee-initiated
      },
    );
  }

  @Post('cancel-leave/:requestId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Employee cancels their leave request' })
  async cancelLeaveRequest(
    @Request() req: any,
    @Param('requestId') requestId: string,
  ) {
    await this.assertFullFeatureAccess(
      req.user.employerId,
      'employee_portal',
      'Employee portal access requires your employer to have a Platinum subscription.',
    );

    return this.leaveManagementService.cancelLeaveRequest(
      req.user.employerId,
      requestId,
    );
  }

  @Patch('my-payment-details')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update employee payment details' })
  async updatePaymentDetails(
    @Request() req: any,
    @Body()
    body: {
      paymentMethod: string;
      bankName?: string;
      bankCode?: string;
      bankAccount?: string;
      mpesaNumber?: string;
    },
  ) {
    await this.assertFullFeatureAccess(
      req.user.employerId,
      'employee_portal',
      'Employee portal access requires your employer to have a Platinum subscription.',
    );

    return this.employeePortalService.updatePaymentDetails(
      req.user.workerId,
      body,
    );
  }
}
