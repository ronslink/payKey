import {
  Controller,
  Post,
  Body,
  UsePipes,
  ValidationPipe,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { LoginDto } from './dto/login.dto';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) { }

  @Post('register')
  @UsePipes(new ValidationPipe())
  async register(@Body() createUserDto: CreateUserDto) {
    try {
      return await this.authService.register(createUserDto);
    } catch (error) {
      // Check for duplicate email error (PostgreSQL code 23505)
      const errorMessage = error instanceof Error ? error.message : '';
      if (
        errorMessage.includes('duplicate') ||
        errorMessage.includes('unique') ||
        errorMessage.includes('already exists')
      ) {
        throw new HttpException('Email already exists', HttpStatus.CONFLICT);
      }

      console.error('Registration error:', error);

      if (error instanceof HttpException) {
        throw error;
      }

      throw new HttpException('Registration failed', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }
  @Post('login')
  @UsePipes(new ValidationPipe())
  async login(@Body() loginDto: LoginDto) {
    try {
      console.log('Login attempt for:', loginDto.email);

      const user = await this.authService.validateUser(
        loginDto.email,
        loginDto.password,
      );

      console.log('User validation result:', user ? 'Success' : 'Failed');

      if (!user) {
        console.log('Invalid credentials for:', loginDto.email);
        throw new HttpException('Invalid credentials', HttpStatus.UNAUTHORIZED);
      }

      console.log('Generating token for user:', user.id);
      const result = await this.authService.login(user);
      console.log('Login successful for:', loginDto.email);

      return result;
    } catch (error) {
      console.error('Login error for', loginDto.email + ':', error);

      if (error instanceof HttpException) {
        console.error(
          'HttpException:',
          error.message,
          'Status:',
          error.getStatus(),
        );
        throw error;
      }

      console.error('Unexpected error:', error);
      throw new HttpException(
        'Internal server error',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}
