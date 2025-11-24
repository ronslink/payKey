import {
  IsString,
  IsNumber,
  IsOptional,
  IsBoolean,
  Min,
  Max,
} from 'class-validator';

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
}

export class PropertySummaryDto {
  id: string;
  name: string;
  address: string;
  workerCount: number;
  isActive: boolean;
}
