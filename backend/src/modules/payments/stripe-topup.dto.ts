import {
  ArrayNotEmpty,
  Equals,
  IsArray,
  IsIn,
  IsNumber,
  IsOptional,
  Min,
} from 'class-validator';

export class StripeTopupDto {
  @IsNumber({ allowInfinity: false, allowNaN: false, maxDecimalPlaces: 2 })
  @Min(0.5)
  amount: number;

  // An explicit currency prevents old clients' KES amounts being charged in EUR.
  @Equals('EUR')
  currency: 'EUR';

  @IsOptional()
  @IsArray()
  @ArrayNotEmpty()
  @IsIn(['card', 'sepa_debit'], { each: true })
  paymentMethodTypes?: string[];
}
