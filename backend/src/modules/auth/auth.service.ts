import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { User } from '../users/entities/user.entity';
import * as bcrypt from 'bcrypt';

interface JwtPayload {
  email: string;
  sub: string;
  tier: string;
  role: string;
}

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
  ) { }

  async validateUser(
    email: string,
    password: string,
  ): Promise<Omit<User, 'passwordHash'> | null> {
    const user = await this.usersService.findOneByEmail(email);
    if (user && (await bcrypt.compare(password, user.passwordHash))) {
      const { passwordHash: _, ...result } = user;
      return result as Omit<User, 'passwordHash'>;
    }
    return null;
  }

  async login(user: Omit<User, 'passwordHash'>) {
    const payload: JwtPayload = {
      email: user.email,
      sub: user.id,
      tier: user.tier,
      role: user.role,
    };
    return {
      access_token: this.jwtService.sign(payload),
      user: {
        id: user.id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        tier: user.tier,
        role: user.role,
        isOnboardingCompleted: user.isOnboardingCompleted,
      },
    };
  }

  async register(createUserDto: CreateUserDto) {
    const salt = await bcrypt.genSalt();
    const hashedPassword = await bcrypt.hash(createUserDto.password, salt);

    const newUser = await this.usersService.create({
      ...createUserDto,
      passwordHash: hashedPassword,
    });

    return this.login(newUser);
  }
}
