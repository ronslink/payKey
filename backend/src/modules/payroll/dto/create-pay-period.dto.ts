import {
  IsString,
  IsDateString,
  IsEnum,
  IsOptional,
  IsObject,
} from 'class-validator';
import { PayPeriodFrequency } from '../entities/pay-period.entity';

export class CreatePayPeriodDto {
  @IsString()
  name: string;

  @IsDateString()
  startDate: string;

  @IsDateString()
  endDate: string;

  @IsOptional()
  @IsDateString()
  payDate?: string;

  @IsEnum(PayPeriodFrequency)
  frequency: PayPeriodFrequency;

  @IsOptional()
  @IsObject()
  notes?: Record<string, any>;

  @IsOptional()
  @IsString()
  createdBy?: string;
}
