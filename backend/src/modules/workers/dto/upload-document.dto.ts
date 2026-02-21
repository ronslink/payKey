import { IsEnum, IsOptional, IsString, IsDateString } from 'class-validator';
import { DocumentType } from '../entities/worker-document.entity';

export class UploadDocumentDto {
  @IsEnum(DocumentType)
  @IsOptional()
  type?: DocumentType = DocumentType.OTHER;

  @IsString()
  @IsOptional()
  notes?: string;

  @IsDateString()
  @IsOptional()
  expiresAt?: string;
}
