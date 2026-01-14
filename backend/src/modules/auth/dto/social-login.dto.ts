import { IsEmail, IsEnum, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export enum SocialProvider {
    GOOGLE = 'GOOGLE',
    APPLE = 'APPLE',
}

export class SocialLoginDto {
    @IsEnum(SocialProvider)
    provider: SocialProvider;

    @IsNotEmpty()
    @IsString()
    token: string; // ID Token from Google/Apple

    @IsNotEmpty()
    @IsString()
    email: string;

    @IsOptional()
    @IsString()
    firstName?: string;

    @IsOptional()
    @IsString()
    lastName?: string;

    @IsOptional()
    @IsString()
    photoUrl?: string;
}
