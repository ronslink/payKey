import {
  IsEnum,
  IsInt,
  IsNumber,
  IsDateString,
  IsOptional,
  IsString,
  Min,
  Max,
} from 'class-validator';
import { TaxType } from '../../tax-config/entities/tax-config.entity';
import { PaymentMethod } from '../entities/tax-payment.entity';

export class CreateTaxPaymentDto {
  @IsEnum(TaxType)
  taxType: TaxType;

  @IsInt()
  @Min(2020)
  @Max(2100)
  paymentYear: number;

  @IsInt()
  @Min(1)
  @Max(12)
  paymentMonth: number;

  @IsNumber()
  @Min(0)
  amount: number;

  @IsDateString()
  @IsOptional()
  paymentDate?: string;

  @IsEnum(PaymentMethod)
  @IsOptional()
  paymentMethod?: PaymentMethod;

  @IsString()
  @IsOptional()
  receiptNumber?: string;

  @IsString()
  @IsOptional()
  notes?: string;
}

export class TaxSummaryDto {
  taxType: TaxType;
  amount: number;
  status: string;
  dueDate: string;
}

export class MonthlyTaxSummaryDto {
  year: number;
  month: number;
  totalDue: number;
  totalPaid: number;
  taxes: TaxSummaryDto[];
  paymentInstructions: {
    mpesa: {
      paybill: string;
      accountNumber: string;
    };
    bank: string;
    deadline: string;
  };
}
