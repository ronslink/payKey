import { UsersService } from './users.service';
import { UpdateComplianceProfileDto } from './dto/update-compliance-profile.dto';
export declare class UsersController {
    private readonly usersService;
    constructor(usersService: UsersService);
    getProfile(req: any): Promise<import("./entities/user.entity").User | null>;
    updateProfile(req: any, updateUserDto: any): Promise<import("./entities/user.entity").User>;
    updateCompliance(req: any, updateComplianceDto: UpdateComplianceProfileDto): Promise<import("./entities/user.entity").User>;
}
