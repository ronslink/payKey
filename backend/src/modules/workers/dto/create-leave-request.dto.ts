import {
  IsEnum,
  IsDateString,
  IsOptional,
  IsString,
  IsBoolean,
  IsNumber,
} from 'class-validator';
import { LeaveType } from '../entities/leave-request.entity';

export class CreateLeaveRequestDto {
  @IsEnum(LeaveType)
  leaveType: LeaveType;

  @IsDateString()
  startDate: string;

  @IsDateString()
  endDate: string;

  @IsOptional()
  @IsString()
  reason?: string;

  @IsOptional()
  @IsBoolean()
  paidLeave?: boolean;

  @IsOptional()
  @IsNumber()
  dailyPayRate?: number;

  @IsOptional()
  @IsString()
  emergencyContact?: string;

  @IsOptional()
  @IsString()
  emergencyPhone?: string;
}

export class ApproveLeaveRequestDto {
  @IsBoolean()
  approved: boolean;

  @IsOptional()
  @IsString()
  rejectionReason?: string;
}

export class UpdateLeaveRequestDto {
  @IsOptional()
  @IsEnum(LeaveType)
  leaveType?: LeaveType;

  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;

  @IsOptional()
  @IsString()
  reason?: string;

  @IsOptional()
  @IsBoolean()
  paidLeave?: boolean;

  @IsOptional()
  @IsNumber()
  dailyPayRate?: number;

  @IsOptional()
  @IsString()
  emergencyContact?: string;

  @IsOptional()
  @IsString()
  emergencyPhone?: string;
}
