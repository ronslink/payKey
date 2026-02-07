import { Injectable, ConflictException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './entities/user.entity';
import { CreateUserDto } from './dto/create-user.dto';
import { IntaSendService } from '../payments/intasend.service';

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);

  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    private intaSendService: IntaSendService,
  ) { }

  async create(
    createUserDto: CreateUserDto & { passwordHash: string },
  ): Promise<User> {
    // Check for duplicate email before attempting to create
    const existingUser = await this.usersRepository.findOne({
      where: { email: createUserDto.email },
    });

    if (existingUser) {
      throw new ConflictException('Email already exists');
    }

    const { password, ...userData } = createUserDto;
    const user = this.usersRepository.create({
      ...userData,
      passwordHash: createUserDto.passwordHash,
    });
    return this.usersRepository.save(user);
  }

  async findOneByEmail(email: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { email } });
  }

  async findOneById(id: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { id } });
  }

  async findOneByGoogleId(googleId: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { googleId } });
  }

  async findOneByAppleId(appleId: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { appleId } });
  }

  async createSocialUser(details: {
    email: string;
    firstName?: string;
    lastName?: string;
    googleId?: string;
    appleId?: string;
    photoUrl?: string;
  }): Promise<User> {
    const existingUser = await this.usersRepository.findOne({
      where: { email: details.email },
    });

    if (existingUser) {
      // If user exists, link the social ID if not already linked
      const updates: Partial<User> = {};
      if (details.googleId && !existingUser.googleId) {
        updates.googleId = details.googleId;
      }
      if (details.appleId && !existingUser.appleId) {
        updates.appleId = details.appleId;
      }
      // Update photo if missing
      if (details.photoUrl && !existingUser.photoUrl) {
        updates.photoUrl = details.photoUrl;
      }

      if (Object.keys(updates).length > 0) {
        await this.usersRepository.update(existingUser.id, updates);
        return this.usersRepository.findOne({ where: { id: existingUser.id } }) as Promise<User>;
      }
      return existingUser;
    }

    // Create new user
    const user = this.usersRepository.create({
      email: details.email,
      firstName: details.firstName,
      lastName: details.lastName,
      googleId: details.googleId,
      appleId: details.appleId,
      photoUrl: details.photoUrl,
      isOnboardingCompleted: false, // Explicitly set to false
    });
    return this.usersRepository.save(user);
  }
  async update(id: string, updateUserDto: Partial<User>): Promise<User> {
    // Check if all required onboarding fields are present
    const user = await this.usersRepository.findOne({ where: { id } });
    if (!user) {
      throw new Error('User not found');
    }

    // Merge current user data with updates to check completeness
    const updatedData = { ...user, ...updateUserDto };

    // Check if onboarding is complete based on required fields
    const hasRequiredPersonalInfo =
      updatedData.firstName && updatedData.lastName;

    const hasRequiredIdentification =
      updatedData.idType && updatedData.idNumber && updatedData.nationalityId;

    const hasRequiredTaxCompliance = updatedData.kraPin;

    const hasRequiredLocation = updatedData.countryId;

    // Residency status is optional but tracked
    const hasRequiredResidencyInfo = true; // Residency status is optional for onboarding

    // Mark onboarding as completed if all required fields are present
    if (
      hasRequiredPersonalInfo &&
      hasRequiredIdentification &&
      hasRequiredTaxCompliance &&
      hasRequiredLocation &&
      hasRequiredResidencyInfo
    ) {
      updateUserDto.isOnboardingCompleted = true;

      // Create IntaSend Wallet if not exists
      if (!user.intasendWalletId) {
        try {
          const walletLabel = `WALLET-${user.id.substring(0, 8).toUpperCase()}`;
          const wallet = await this.intaSendService.createWallet('KES', walletLabel, true);
          if (wallet && wallet.wallet_id) {
            updateUserDto.intasendWalletId = wallet.wallet_id;
            this.logger.log(`Created IntaSend wallet ${wallet.wallet_id} for user ${user.id}`);
          }
        } catch (error) {
          this.logger.error(`Failed to create IntaSend wallet for user ${user.id}`, error);
          // We don't block onboarding completion if wallet creation fails, but we should log it.
          // Or should we block? Safest to log for now to avoid UX blockers.
        }
      }
    }

    await this.usersRepository.update(id, updateUserDto);
    const updatedUser = await this.usersRepository.findOne({ where: { id } });
    if (!updatedUser) {
      throw new Error('User not found after update');
    }
    return updatedUser;
  }
}
