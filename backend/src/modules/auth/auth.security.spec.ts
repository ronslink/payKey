import { ValidationPipe } from '@nestjs/common';
import { PIPES_METADATA } from '@nestjs/common/constants';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { OAuth2Client, LoginTicket } from 'google-auth-library';
import * as appleSignin from 'apple-signin-auth';
import { Repository } from 'typeorm';
import { IntaSendService } from '../payments/intasend.service';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { User, UserRole, UserTier } from '../users/entities/user.entity';
import { UsersService } from '../users/users.service';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { SocialProvider } from './dto/social-login.dto';

jest.mock('apple-signin-auth', () => ({ verifyIdToken: jest.fn() }));

describe('Public authentication security', () => {
  const registration = {
    email: 'signup@example.invalid',
    password: 'local-test-password',
    firstName: 'Test',
  };

  afterEach(() => jest.restoreAllMocks());

  it.each([
    ['role', UserRole.SUPER_ADMIN],
    ['tier', UserTier.PLATINUM],
    ['walletBalance', 1000000],
    ['clearingBalance', 1000000],
    ['isOnboardingCompleted', true],
    ['intasendWalletId', 'another-wallet'],
  ])(
    'rejects privileged signup property %s at the HTTP boundary',
    async (key, value) => {
      const [pipe] = Reflect.getMetadata(
        PIPES_METADATA,
        Object.getOwnPropertyDescriptor(AuthController.prototype, 'register')!
          .value,
      ) as ValidationPipe[];

      await expect(
        pipe.transform(
          { ...registration, [key]: value },
          {
            type: 'body',
            metatype: CreateUserDto,
          },
        ),
      ).rejects.toMatchObject({ status: 400 });
    },
  );

  it('creates only a free ordinary account even if an internal caller passes privileged properties', async () => {
    const repository = {
      findOne: jest.fn().mockResolvedValue(null),
      create: jest.fn((data) => ({ id: 'new-user', ...data })),
      save: jest.fn((data) => Promise.resolve(data)),
    };
    const users = new UsersService(
      repository as unknown as Repository<User>,
      {} as IntaSendService,
    );
    const jwt = new JwtService({ secret: 'unit-test-only-signing-secret' });
    const auth = new AuthService(users, jwt, new ConfigService());
    const response = await auth.register({
      ...registration,
      role: UserRole.SUPER_ADMIN,
      tier: UserTier.PLATINUM,
      walletBalance: 1000000,
      clearingBalance: 1000000,
      intasendWalletId: 'another-wallet',
      employerId: 'another-employer',
      isOnboardingCompleted: true,
    } as CreateUserDto);

    const persisted = repository.save.mock.calls[0][0];
    expect(persisted).toMatchObject({
      email: registration.email,
      role: UserRole.USER,
      tier: UserTier.FREE,
      walletBalance: 0,
      clearingBalance: 0,
      isOnboardingCompleted: false,
    });
    expect(persisted).not.toHaveProperty('intasendWalletId');
    expect(persisted).not.toHaveProperty('employerId');
    expect(persisted).not.toHaveProperty('password');
    expect(jwt.verify(response.access_token)).toMatchObject({
      role: UserRole.USER,
      tier: UserTier.FREE,
    });
  });

  const makeSocialService = (values: Record<string, string> = {}) => {
    const users = {
      createSocialUser: jest.fn((details) =>
        Promise.resolve({
          id: 'social-user',
          role: UserRole.USER,
          tier: UserTier.FREE,
          ...details,
        }),
      ),
      findOneByAppleId: jest.fn().mockResolvedValue(null),
    };
    return {
      users,
      auth: new AuthService(
        users as unknown as UsersService,
        new JwtService({ secret: 'unit-test-only-signing-secret' }),
        { get: (key: string) => values[key] } as ConfigService,
      ),
    };
  };

  const socialRequest = {
    provider: SocialProvider.GOOGLE,
    token: 'untrusted-token',
    email: 'victim@example.invalid',
  };

  it('does not authenticate a supplied email when Google is not configured', async () => {
    const verify = jest.spyOn(OAuth2Client.prototype, 'verifyIdToken');
    const { auth, users } = makeSocialService({ NODE_ENV: 'production' });

    await expect(auth.loginWithSocial(socialRequest)).rejects.toMatchObject({
      status: 503,
    });
    expect(verify).not.toHaveBeenCalled();
    expect(users.createSocialUser).not.toHaveBeenCalled();
  });

  it.each([
    { sub: 'verified-subject', email_verified: true },
    {
      sub: 'verified-subject',
      email: 'victim@example.invalid',
      email_verified: false,
    },
  ])('refuses tokens without a verified Google email', async (payload) => {
    jest.spyOn(OAuth2Client.prototype, 'verifyIdToken').mockResolvedValue({
      getPayload: () => payload,
    } as LoginTicket);
    const { auth, users } = makeSocialService({
      GOOGLE_WEB_CLIENT_ID: 'expected-audience',
    });

    await expect(auth.loginWithSocial(socialRequest)).rejects.toMatchObject({
      status: 401,
    });
    expect(users.createSocialUser).not.toHaveBeenCalled();
  });

  it('uses the verified Google email instead of the email supplied by the client', async () => {
    const verify = jest
      .spyOn(OAuth2Client.prototype, 'verifyIdToken')
      .mockResolvedValue({
        getPayload: () => ({
          sub: 'verified-subject',
          email: 'owner@example.invalid',
          email_verified: true,
        }),
      } as LoginTicket);
    const { auth, users } = makeSocialService({
      GOOGLE_WEB_CLIENT_ID: 'expected-audience',
    });

    await auth.loginWithSocial(socialRequest);
    expect(verify).toHaveBeenCalledWith({
      idToken: socialRequest.token,
      audience: ['expected-audience'],
    });
    expect(users.createSocialUser).toHaveBeenCalledWith(
      expect.objectContaining({
        email: 'owner@example.invalid',
        googleId: 'verified-subject',
      }),
    );
  });

  const appleConfiguration = {
    APPLE_KEY_ID: 'test-key-id',
    APPLE_TEAM_ID: 'test-team-id',
    APPLE_BUNDLE_ID: 'test-bundle-id',
    APPLE_PRIVATE_KEY: 'unused-test-value',
  };

  it('rejects an unlinked Apple subject with no verified email rather than using the client email', async () => {
    jest.mocked(appleSignin.verifyIdToken).mockResolvedValue({
      sub: 'apple-subject',
    } as appleSignin.AppleIdTokenType);
    const { auth, users } = makeSocialService(appleConfiguration);

    await expect(
      auth.loginWithSocial({
        ...socialRequest,
        provider: SocialProvider.APPLE,
      }),
    ).rejects.toMatchObject({ status: 401 });
    expect(users.findOneByAppleId).toHaveBeenCalledWith('apple-subject');
    expect(users.createSocialUser).not.toHaveBeenCalled();
  });

  it('allows a returning Apple subject already linked to an account when email is omitted', async () => {
    jest.mocked(appleSignin.verifyIdToken).mockResolvedValue({
      sub: 'apple-subject',
    } as appleSignin.AppleIdTokenType);
    const { auth, users } = makeSocialService(appleConfiguration);
    users.findOneByAppleId.mockResolvedValue({
      id: 'linked-apple-user',
      email: 'owner@example.invalid',
      role: UserRole.USER,
      tier: UserTier.FREE,
    });

    const result = await auth.loginWithSocial({
      ...socialRequest,
      provider: SocialProvider.APPLE,
    });
    expect(result.user.id).toBe('linked-apple-user');
    expect(result.user.email).toBe('owner@example.invalid');
    expect(users.createSocialUser).not.toHaveBeenCalled();
  });

  it('rejects an Apple token whose email is not verified', async () => {
    jest.mocked(appleSignin.verifyIdToken).mockResolvedValue({
      sub: 'apple-subject',
      email: 'victim@example.invalid',
      email_verified: 'false',
    } as appleSignin.AppleIdTokenType);
    const { auth, users } = makeSocialService(appleConfiguration);

    await expect(
      auth.loginWithSocial({
        ...socialRequest,
        provider: SocialProvider.APPLE,
      }),
    ).rejects.toMatchObject({ status: 401 });
    expect(users.createSocialUser).not.toHaveBeenCalled();
  });
});
