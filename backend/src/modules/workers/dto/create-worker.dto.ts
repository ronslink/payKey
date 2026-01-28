import {
  IsString,
  IsNotEmpty,
  IsNumber,
  IsDateString,
  IsOptional,
  IsEnum,
  Min,
  Max,
  Length,
} from 'class-validator';
import { Transform } from 'class-transformer';
import {
  EmploymentType,
  PaymentFrequency,
  PaymentMethod,
} from '../entities/worker.entity';

export class CreateWorkerDto {
  @IsString()
  @IsNotEmpty()
  @Length(2, 100)
  @Transform(({ value }) => typeof value === 'string' ? value.replace(/<[^>]*>?/gm, '') : value)
  name: string;

  @IsString()
  @IsNotEmpty()
  @Length(7, 20)
  phoneNumber: string;

  @IsString()
  @IsOptional()
  idNumber?: string;

  @IsString()
  @IsOptional()
  kraPin?: string;

  @IsNumber()
  @IsNotEmpty()
  @Min(0)
  @Max(10000000)
  salaryGross: number;

  @IsEnum(EmploymentType)
  @IsOptional()
  employmentType?: EmploymentType;

  @IsNumber()
  @IsOptional()
  hourlyRate?: number;

  @IsDateString()
  @IsNotEmpty()
  startDate: string;

  @IsDateString()
  @IsOptional()
  dateOfBirth?: string;

  @IsString()
  @IsOptional()
  email?: string;

  @IsString()
  @IsOptional()
  nssfNumber?: string;

  @IsString()
  @IsOptional()
  nhifNumber?: string;

  @IsString()
  @IsOptional()
  jobTitle?: string;

  @IsNumber()
  @IsOptional()
  housingAllowance?: number;

  @IsNumber()
  @IsOptional()
  transportAllowance?: number;

  @IsEnum(PaymentFrequency)
  @IsOptional()
  paymentFrequency?: PaymentFrequency;

  @IsEnum(PaymentMethod)
  @IsOptional()
  paymentMethod?: PaymentMethod;

  @IsString()
  @IsOptional()
  mpesaNumber?: string;

  @IsString()
  @IsOptional()
  bankName?: string;

  @IsString()
  @IsOptional()
  bankAccount?: string;

  @IsString()
  @IsOptional()
  notes?: string;

  @IsString()
  @IsOptional()
  emergencyContactName?: string;

  @IsString()
  @IsOptional()
  emergencyContactPhone?: string;

  @IsString()
  @IsOptional()
  emergencyContactRelationship?: string;

  @IsString()
  @IsOptional()
  propertyId?: string;

  @IsString()
  @IsOptional()
  photoUrl?: string;
}
