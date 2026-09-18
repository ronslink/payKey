import {
  Injectable,
  ConflictException,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { User } from '../users/entities/user.entity';
import * as bcrypt from 'bcrypt';
import * as appleSignin from 'apple-signin-auth';
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

  login(user: Omit<User, 'passwordHash'>) {
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
    const { provider, token, firstName, lastName, photoUrl } = socialLoginDto;

    let socialId: string;
    let verifiedEmail: string | undefined;

    if (provider === SocialProvider.GOOGLE) {
      const googlePayload = await this.verifyGoogleToken(token);
      socialId = googlePayload.sub;
      verifiedEmail = googlePayload.email;
    } else if (provider === SocialProvider.APPLE) {
      const applePayload = await this.verifyAppleToken(token);
      socialId = applePayload.sub;
      verifiedEmail = applePayload.email;

      // Apple can omit email on subsequent sign-ins. Only an identity already
      // linked to this verified subject may sign in without a verified email.
      if (!verifiedEmail) {
        const existingUser = await this.usersService.findOneByAppleId(socialId);
        if (existingUser) return this.login(existingUser);
      } else if (String(applePayload.email_verified) !== 'true') {
        throw new UnauthorizedException(
          'A verified provider email is required',
        );
      }
    } else {
      throw new UnauthorizedException('Unsupported social provider');
    }

    if (!verifiedEmail) {
      throw new UnauthorizedException('A verified provider email is required');
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
      throw new ServiceUnavailableException('Apple sign-in is not configured');
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

      if (!tokenPayload.sub) {
        throw new UnauthorizedException('Invalid Apple identity token');
      }
      return tokenPayload;
    } catch {
      throw new UnauthorizedException('Invalid Apple identity token');
    }
  }

  private async verifyGoogleToken(idToken: string) {
    // Build the list of accepted audience values.
    // GOOGLE_CLIENT_ID      = iOS OAuth client (104336380998-...)
    // GOOGLE_WEB_CLIENT_ID  = Android / Web OAuth client (126777889122-...) — canonical going forward
    // Both are kept so tokens from either platform are accepted.
    const iosClientId = this.configService.get<string>('GOOGLE_CLIENT_ID');
    const webClientId = this.configService.get<string>('GOOGLE_WEB_CLIENT_ID');

    const allowedAudiences = [iosClientId, webClientId]
      .map((audience) => audience?.trim())
      .filter((audience): audience is string => Boolean(audience));

    if (allowedAudiences.length === 0) {
      throw new ServiceUnavailableException('Google sign-in is not configured');
    }

    // Use a client with no audience restriction — we'll validate the audience ourselves
    // so we can accept tokens issued against either OAuth client ID.
    const client = new OAuth2Client();

    try {
      const ticket = await client.verifyIdToken({
        idToken,
        audience: allowedAudiences,
      });
      const payload = ticket.getPayload();
      if (!payload?.sub || !payload.email || payload.email_verified !== true) {
        throw new UnauthorizedException('A verified Google email is required');
      }
      console.debug(
        `Google token verified. Audience: ${payload.aud}, Platform client matched.`,
      );
      return payload;
    } catch {
      throw new UnauthorizedException('Invalid Google identity token');
    }
  }
}
