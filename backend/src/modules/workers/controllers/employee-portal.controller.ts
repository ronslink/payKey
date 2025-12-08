import {
    Controller,
    Get,
    Post,
    Body,
    Param,
    UseGuards,
    Request,
} from '@nestjs/common';
import { JwtAuthGuard } from '../../auth/jwt-auth.guard';
import { EmployeePortalService } from '../services/employee-portal.service';
import { LeaveManagementService } from '../services/leave-management.service';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';

@ApiTags('Employee Portal')
@Controller('employee-portal')
export class EmployeePortalController {
    constructor(
        private readonly employeePortalService: EmployeePortalService,
        private readonly leaveManagementService: LeaveManagementService,
    ) { }

    // ============================================================
    // PUBLIC ENDPOINTS (No Auth Required)
    // ============================================================

    @Post('claim-account')
    @ApiOperation({ summary: 'Employee claims their account with phone + invite code' })
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
    async employeeLogin(
        @Body() body: { phoneNumber: string; pin: string },
    ) {
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
        return this.employeePortalService.generateInviteCode(workerId, req.user.userId);
    }

    @Get('invite-status/:workerId')
    @UseGuards(JwtAuthGuard)
    @ApiBearerAuth()
    @ApiOperation({ summary: 'Check if worker has been invited or has account' })
    async checkInviteStatus(
        @Request() req: any,
        @Param('workerId') workerId: string,
    ) {
        return this.employeePortalService.checkInviteStatus(workerId, req.user.userId);
    }

    // ============================================================
    // EMPLOYEE ENDPOINTS (Authenticated as Employee)
    // ============================================================

    @Get('my-profile')
    @UseGuards(JwtAuthGuard)
    @ApiBearerAuth()
    @ApiOperation({ summary: 'Get employee profile and worker info' })
    async getMyProfile(@Request() req: any) {
        // req.user contains workerId and employerId from JWT
        return {
            userId: req.user.userId,
            workerId: req.user.workerId,
            employerId: req.user.employerId,
            role: req.user.role,
        };
    }

    @Get('my-leave-balance')
    @UseGuards(JwtAuthGuard)
    @ApiBearerAuth()
    @ApiOperation({ summary: 'Get employee leave balance' })
    async getMyLeaveBalance(@Request() req: any) {
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
        @Body() body: {
            leaveType: string;
            startDate: string;
            endDate: string;
            reason?: string;
        },
    ) {
        return this.leaveManagementService.createLeaveRequest(
            req.user.employerId, // Employer's userId for ownership
            req.user.workerId,   // Employee's workerId
            {
                leaveType: body.leaveType as any,
                startDate: body.startDate,
                endDate: body.endDate,
                reason: body.reason,
                paidLeave: true, // Default to paid leave
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
        return this.leaveManagementService.cancelLeaveRequest(
            req.user.employerId,
            requestId,
        );
    }
}
