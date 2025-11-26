import { CanActivate, ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UsersService } from '../users/users.service';
import { WorkersService } from '../workers/workers.service';
export declare class SubscriptionGuard implements CanActivate {
    private reflector;
    private usersService;
    private workersService;
    constructor(reflector: Reflector, usersService: UsersService, workersService: WorkersService);
    canActivate(context: ExecutionContext): Promise<boolean>;
}
