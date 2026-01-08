import {
  IsEnum,
  IsOptional,
  IsString,
  IsDate,
  IsBoolean,
} from 'class-validator';
import { PayPeriodStatus } from '../entities/pay-period.entity';

export class UpdatePayPeriodDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  startDate?: string;

  @IsOptional()
  @IsString()
  endDate?: string;

  @IsOptional()
  @IsString()
  payDate?: string;

  @IsOptional()
  @IsEnum(PayPeriodStatus)
  status?: PayPeriodStatus;

  @IsOptional()
  @IsString()
  approvedBy?: string;

  @IsOptional()
  @IsDate()
  approvedAt?: Date;

  @IsOptional()
  isOffCycle?: boolean;
}
