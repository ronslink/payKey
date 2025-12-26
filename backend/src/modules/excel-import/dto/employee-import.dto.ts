import { IsString, IsNumber, IsOptional, IsDateString } from 'class-validator';

export class EmployeeImportRowDto {
  @IsString()
  name: string; // Required

  @IsString()
  phoneNumber: string; // Required

  @IsNumber()
  salaryGross: number; // Required

  @IsOptional()
  @IsString()
  idNumber?: string;

  @IsOptional()
  @IsString()
  kraPin?: string;

  @IsOptional()
  @IsString()
  nssfNumber?: string;

  @IsOptional()
  @IsString()
  nhifNumber?: string;

  @IsOptional()
  @IsString()
  jobTitle?: string;

  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  dateOfBirth?: string;
}

export class EmployeeImportResultDto {
  success: boolean;
  totalRows: number;
  importedCount: number;
  errorCount: number;
  errors: { row: number; field: string; message: string }[];
  importedEmployees: { name: string; id: string }[];
}

// Required columns marked with asterisk in template
export const REQUIRED_COLUMNS = [
  'name*',
  'phoneNumber*',
  'salaryGross*',
] as const;
export const OPTIONAL_COLUMNS = [
  'idNumber',
  'kraPin',
  'nssfNumber',
  'nhifNumber',
  'jobTitle',
  'startDate',
  'dateOfBirth',
] as const;

export const ALL_COLUMNS = [
  ...REQUIRED_COLUMNS.map((c) => c.replace('*', '')),
  ...OPTIONAL_COLUMNS,
];
