import { Controller, Get, Request, UseGuards } from '@nestjs/common';
import { TasksService } from './tasks.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('tasks')
@UseGuards(JwtAuthGuard)
export class TasksController {
    constructor(private readonly tasksService: TasksService) { }

    @Get()
    async getTasks(@Request() req: any) {
        return this.tasksService.getTasks(req.user.userId);
    }
}
