import { Transform } from 'class-transformer';
import {
  IsBoolean,
  IsEnum,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';
import { SubscribeDto } from './subscribe.dto';
import { RenewalMethod } from '../entities/subscription.entity';

export class MpesaSubscribeDto extends SubscribeDto {
  @IsString()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.replace(/\s+/g, '') : value,
  )
  @Matches(/^(?:\+?254|0)?[17]\d{8}$/)
  phoneNumber: string;
}

export class AutoRenewDto {
  @IsBoolean()
  enable: boolean;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  reason?: string;

  @IsOptional()
  @IsEnum(RenewalMethod)
  renewalMethod?: RenewalMethod;
}
