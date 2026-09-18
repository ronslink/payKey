import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsIn,
  IsNumber,
  Min,
} from 'class-validator';

export class StripeTopupDto {
  @IsNumber({ allowInfinity: false, allowNaN: false, maxDecimalPlaces: 2 })
  @Min(0.01)
  amount: number;

  // An explicit currency prevents old clients' KES amounts being charged in EUR.
  @IsIn(['KES', 'EUR'])
  currency: 'KES' | 'EUR';

  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(1)
  @IsIn(['card'], { each: true })
  paymentMethodTypes: ['card'];
}
