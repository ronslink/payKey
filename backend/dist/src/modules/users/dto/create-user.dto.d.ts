import { UserTier } from '../entities/user.entity';
export declare class CreateUserDto {
    email: string;
    password: string;
    firstName?: string;
    lastName?: string;
    tier?: UserTier;
}
