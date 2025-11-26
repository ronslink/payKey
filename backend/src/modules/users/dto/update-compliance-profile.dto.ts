import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  ValidateIf,
} from 'class-validator';
import { IdType } from '../entities/user.entity';

export class UpdateComplianceProfileDto {
  @IsString()
  @Matches(/^[A-Z]\d{9}[A-Z]$/, {
    message: 'KRA PIN must be in the format A123456789Z',
  })
  kraPin: string;

  @IsString()
  @IsNotEmpty()
  nssfNumber: string;

  @IsString()
  @IsNotEmpty()
  nhifNumber: string;

  @IsEnum(IdType)
  idType: IdType;

  @IsString()
  @ValidateIf((o) => o.idType === IdType.NATIONAL_ID)
  @Matches(/^\d{7,8}$/, {
    message: 'National ID must be 7 or 8 digits',
  })
  @ValidateIf(
    (o) => o.idType === IdType.ALIEN_ID || o.idType === IdType.PASSPORT,
  )
  @IsNotEmpty()
  idNumber: string;

  @IsString()
  @ValidateIf(
    (o) => o.idType === IdType.ALIEN_ID || o.idType === IdType.PASSPORT,
  )
  @IsNotEmpty({
    message: 'Nationality is required for Expats (Passport/Alien ID)',
  })
  @IsOptional()
  nationalityId?: string;

  @IsString()
  @IsNotEmpty()
  address: string;

  @IsString()
  @IsNotEmpty()
  city: string;

  @IsString()
  @IsNotEmpty()
  countryId: string;
}
