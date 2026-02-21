import {
  IsEnum,
  IsDateString,
  IsOptional,
  IsInt,
  Min,
  IsString,
  IsNumber,
} from 'class-validator';
import { Transform } from 'class-transformer';
import { TerminationReason } from '../entities/termination.entity';

export class CreateTerminationDto {
  @IsEnum(TerminationReason)
  reason: TerminationReason;

  @IsDateString()
  terminationDate: string;

  @IsDateString()
  @IsOptional()
  // Treat explicit null the same as absent
  @Transform(({ value }) => value ?? undefined)
  lastWorkingDate?: string;

  @IsInt()
  @Min(0)
  @IsOptional()
  // Mobile sends this as a number; coerce floats to int just in case
  @Transform(({ value }) => (value != null ? Math.floor(Number(value)) : undefined))
  noticePeriodDays?: number;

  @IsString()
  @IsOptional()
  // Treat explicit null as absent so @IsString() is not triggered
  @Transform(({ value }) => value ?? undefined)
  notes?: string;

  @IsNumber()
  @IsOptional()
  @Min(0)
  @Transform(({ value }) => (value != null ? Number(value) : undefined))
  severancePay?: number;

  @IsNumber()
  @IsOptional()
  @Min(0)
  @Transform(({ value }) => (value != null ? Number(value) : undefined))
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
