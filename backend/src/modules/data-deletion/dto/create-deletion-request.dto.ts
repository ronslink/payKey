import { IsEmail, IsOptional, IsString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateDeletionRequestDto {
    @ApiProperty({
        description: 'Email address of the account to delete',
        example: 'user@example.com',
    })
    @IsEmail()
    email: string;

    @ApiPropertyOptional({
        description: 'Optional reason for account deletion',
        example: 'No longer using the service',
    })
    @IsOptional()
    @IsString()
    reason?: string;
}
