import { IsString, IsNotEmpty, IsNumber, IsOptional } from 'class-validator';

export class ClockInDto {
  @IsString()
  @IsNotEmpty()
  workerId: string;

  @IsNumber()
  @IsNotEmpty()
  latitude: number;

  @IsNumber()
  @IsNotEmpty()
  longitude: number;

  @IsString()
  @IsOptional()
  notes?: string;
}

export class ClockOutDto {
  @IsString()
  @IsNotEmpty()
  timeEntryId: string;

  @IsNumber()
  @IsNotEmpty()
  latitude: number;

  @IsNumber()
  @IsNotEmpty()
  longitude: number;

  @IsString()
  @IsOptional()
  notes?: string;
}
