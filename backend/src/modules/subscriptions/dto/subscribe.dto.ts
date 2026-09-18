import { Transform } from 'class-transformer';
import { IsIn, IsOptional, IsString, Length, MaxLength } from 'class-validator';

export class SubscribeDto {
  @IsString()
  @Length(1, 40)
  planId: string;

  @IsOptional()
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.toUpperCase() : value,
  )
  @IsIn(['STRIPE', 'BANK', 'WALLET'])
  paymentMethod?: string;

  @IsOptional()
  @IsIn(['monthly', 'yearly'])
  billingPeriod?: 'monthly' | 'yearly';

  @IsOptional()
  @IsString()
  @MaxLength(128)
  promoCode?: string;
}
