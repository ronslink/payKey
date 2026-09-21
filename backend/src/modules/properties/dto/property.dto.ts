import {
  IsString,
  IsNumber,
  IsOptional,
  IsBoolean,
  Matches,
  Min,
  Max,
} from 'class-validator';

const WHAT3WORDS_PATTERN = /^(?:\/\/\/)?[a-zA-Z]+\.[a-zA-Z]+\.[a-zA-Z]+$/;

export class CreatePropertyDto {
  @IsString()
  name: string;

  @IsString()
  address: string;

  @IsNumber()
  @IsOptional()
  @Min(-90)
  @Max(90)
  latitude?: number;

  @IsNumber()
  @IsOptional()
  @Min(-180)
  @Max(180)
  longitude?: number;

  @IsNumber()
  @IsOptional()
  @Min(10) // Minimum 10 meters
  geofenceRadius?: number;

  @IsString()
  @IsOptional()
  @Matches(WHAT3WORDS_PATTERN, {
    message: 'what3words must be three words, for example filled.count.soap',
  })
  what3words?: string;
}

export class UpdatePropertyDto {
  @IsString()
  @IsOptional()
  name?: string;

  @IsString()
  @IsOptional()
  address?: string;

  @IsNumber()
  @IsOptional()
  @Min(-90)
  @Max(90)
  latitude?: number;

  @IsNumber()
  @IsOptional()
  @Min(-180)
  @Max(180)
  longitude?: number;

  @IsNumber()
  @IsOptional()
  @Min(10)
  geofenceRadius?: number;

  @IsBoolean()
  @IsOptional()
  isActive?: boolean;

  @IsString()
  @IsOptional()
  @Matches(WHAT3WORDS_PATTERN, {
    message: 'what3words must be three words, for example filled.count.soap',
  })
  what3words?: string;
}

export class PropertySummaryDto {
  id: string;
  name: string;
  address: string;
  workerCount: number;
  isActive: boolean;
}
