import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { User } from '../users/entities/user.entity';
export declare class AuthService {
    private usersService;
    private jwtService;
    constructor(usersService: UsersService, jwtService: JwtService);
    validateUser(email: string, password: string): Promise<Omit<User, 'passwordHash'> | null>;
    login(user: Omit<User, 'passwordHash'>): Promise<{
        access_token: string;
        user: {
            id: string;
            email: string;
            firstName: string;
            lastName: string;
            tier: import("../users/entities/user.entity").UserTier;
            role: import("../users/entities/user.entity").UserRole;
            isOnboardingCompleted: boolean;
        };
    }>;
    register(createUserDto: CreateUserDto): Promise<{
        access_token: string;
        user: {
            id: string;
            email: string;
            firstName: string;
            lastName: string;
            tier: import("../users/entities/user.entity").UserTier;
            role: import("../users/entities/user.entity").UserRole;
            isOnboardingCompleted: boolean;
        };
    }>;
}
