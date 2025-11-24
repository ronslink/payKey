import {
  IsEnum,
  IsDateString,
  IsOptional,
  IsInt,
  Min,
  IsString,
  IsNumber,
} from 'class-validator';
import { TerminationReason } from '../entities/termination.entity';

export class CreateTerminationDto {
  @IsEnum(TerminationReason)
  reason: TerminationReason;

  @IsDateString()
  terminationDate: string;

  @IsDateString()
  @IsOptional()
  lastWorkingDate?: string;

  @IsInt()
  @Min(0)
  @IsOptional()
  noticePeriodDays?: number;

  @IsString()
  @IsOptional()
  notes?: string;

  @IsNumber()
  @IsOptional()
  @Min(0)
  severancePay?: number;

  @IsNumber()
  @IsOptional()
  @Min(0)
  outstandingPayments?: number;
}

export class FinalPaymentCalculationDto {
  proratedSalary: number;
  unusedLeavePayout: number;
  severancePay: number;
  totalGross: number;
  taxDeductions: {
    nssf: number;
    nhif: number;
    housingLevy: number;
    paye: number;
    total: number;
  };
  totalNet: number;
  breakdown: {
    daysWorked: number;
    totalDaysInMonth: number;
    dailyRate: number;
    unusedLeaveDays: number;
    leavePayoutRate: number;
  };
}
