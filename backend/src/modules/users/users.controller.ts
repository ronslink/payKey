import {
  Controller,
  Get,
  Patch,
  Body,
  UseGuards,
  Request,
  UsePipes,
  ValidationPipe,
  BadRequestException,
} from '@nestjs/common';
import { validate } from 'class-validator';
import { plainToInstance } from 'class-transformer';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { UpdateComplianceProfileDto } from './dto/update-compliance-profile.dto';
import { UpdateUserDto } from './dto/update-user.dto';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) { }

  @UseGuards(JwtAuthGuard)
  @Get('profile')
  getProfile(@Request() req: any) {
    return this.usersService.findOneById(req.user.userId);
  }

  @UseGuards(JwtAuthGuard)
  @Patch('profile')
  @UsePipes(new ValidationPipe({ whitelist: true }))
  updateProfile(@Request() req: any, @Body() updateUserDto: UpdateUserDto) {
    return this.usersService.update(req.user.userId, updateUserDto);
  }

  @UseGuards(JwtAuthGuard)
  @Patch('compliance')
  @UsePipes(new ValidationPipe({ whitelist: true, transform: true }))
  updateCompliance(
    @Request() req: any,
    @Body() updateComplianceDto: UpdateComplianceProfileDto,
  ) {
    return this.usersService.update(req.user.userId, updateComplianceDto);
  }
}
