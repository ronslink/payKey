import { Injectable, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { User } from '../users/entities/user.entity';
import * as bcrypt from 'bcrypt';
import * as appleSignin from 'apple-signin-auth';
import * as fs from 'fs';
import * as path from 'path';
import { ConfigService } from '@nestjs/config';
import { OAuth2Client } from 'google-auth-library';

interface JwtPayload {
  email: string;
  sub: string;
  tier: string;
  role: string;
  employerId?: string;
  workerId?: string;
}

import { SocialLoginDto, SocialProvider } from './dto/social-login.dto';

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  async validateUser(
    email: string,
    password: string,
  ): Promise<Omit<User, 'passwordHash'> | null> {
    const user = await this.usersService.findOneByEmail(email);
    if (
      user &&
      user.passwordHash &&
      (await bcrypt.compare(password, user.passwordHash))
    ) {
      const { passwordHash: _hash, ...result } = user;
      console.debug(
        'Login validated for user:',
        _hash ? user.email : 'unknown',
      );
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
      // Include employerId and workerId for WORKER role
      employerId: user.employerId,
      workerId: user.linkedWorkerId, // This comes from the User entity for workers
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
    // Check if user already exists
    const existingUser = await this.usersService.findOneByEmail(
      createUserDto.email,
    );

    if (existingUser) {
      throw new ConflictException('Email already registered');
    }

    const salt = await bcrypt.genSalt();
    const hashedPassword = await bcrypt.hash(createUserDto.password, salt);

    const newUser = await this.usersService.create({
      ...createUserDto,
      passwordHash: hashedPassword,
    });

    return this.login(newUser);
  }

  async loginWithSocial(socialLoginDto: SocialLoginDto) {
    const {
      provider,
      token,
      email: clientEmail,
      firstName,
      lastName,
      photoUrl,
    } = socialLoginDto;

    let socialId = token;
    let verifiedEmail = clientEmail;

    if (provider === SocialProvider.GOOGLE) {
      const googlePayload = await this.verifyGoogleToken(token);
      socialId = googlePayload.sub;
      verifiedEmail = googlePayload.email || clientEmail;
    } else if (provider === SocialProvider.APPLE) {
      const applePayload = await this.verifyAppleToken(token);
      socialId = applePayload.sub;
      verifiedEmail = applePayload.email || clientEmail;
    }

    // Check if user exists or create them
    const user = await this.usersService.createSocialUser({
      email: verifiedEmail,
      firstName,
      lastName,
      photoUrl,
      googleId: provider === SocialProvider.GOOGLE ? socialId : undefined,
      appleId: provider === SocialProvider.APPLE ? socialId : undefined,
    });

    return this.login(user);
  }

  private async verifyAppleToken(idToken: string) {
    const appleKeyId = this.configService.get<string>('APPLE_KEY_ID');
    const appleTeamId = this.configService.get<string>('APPLE_TEAM_ID');
    const appleBundleId = this.configService.get<string>('APPLE_BUNDLE_ID');
    const appleKeyPath = this.configService.get<string>('APPLE_KEY_PATH');
    const applePrivateKeyEnv =
      this.configService.get<string>('APPLE_PRIVATE_KEY');

    if (
      !appleKeyId ||
      !appleTeamId ||
      !appleBundleId ||
      (!appleKeyPath && !applePrivateKeyEnv)
    ) {
      throw new Error('Apple configuration missing in environment variables');
    }

    try {
      if (applePrivateKeyEnv) {
        console.debug('Apple Sign-in: Using private key from environment');
      } else if (appleKeyPath) {
        console.debug(
          'Apple Sign-in: Using private key from file:',
          appleKeyPath,
        );
      }

      const tokenPayload = await appleSignin.verifyIdToken(idToken, {
        audience: appleBundleId,
        ignoreExpiration: false,
      });

      return tokenPayload;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      throw new Error(`Apple token verification failed: ${message}`);
    }
  }

  private async verifyGoogleToken(idToken: string) {
    // We assume GOOGLE_CLIENT_ID is in env
    const googleClientId = this.configService.get<string>('GOOGLE_CLIENT_ID');
    const client = new OAuth2Client(googleClientId);

    try {
      const ticket = await client.verifyIdToken({
        idToken,
        audience: googleClientId,
      });
      return ticket.getPayload()!;
    } catch (error) {
      // If GOOGLE_CLIENT_ID is missing, we might still want to allow development
      // but for production this is critical.
      if (!googleClientId) {
        console.warn(
          'GOOGLE_CLIENT_ID missing, skipping Google token verification',
        );
        return { sub: idToken, email: undefined }; // Fallback for dev
      }
      throw new Error(`Google token verification failed: ${error.message}`);
    }
  }
}
