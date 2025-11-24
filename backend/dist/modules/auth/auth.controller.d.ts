import { AuthService } from './auth.service';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { LoginDto } from './dto/login.dto';
export declare class AuthController {
    private authService;
    constructor(authService: AuthService);
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
    login(loginDto: LoginDto): Promise<{
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
