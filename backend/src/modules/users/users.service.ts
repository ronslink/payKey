import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './entities/user.entity';
import { CreateUserDto } from './dto/create-user.dto';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
  ) { }

  async create(
    createUserDto: CreateUserDto & { passwordHash: string },
  ): Promise<User> {
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
      updatedData.firstName &&
      updatedData.lastName;

    const hasRequiredIdentification =
      updatedData.idType &&
      updatedData.idNumber &&
      updatedData.nationalityId;

    const hasRequiredTaxCompliance =
      updatedData.kraPin;

    const hasRequiredLocation =
      updatedData.countryId;

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
    }

    await this.usersRepository.update(id, updateUserDto);
    const updatedUser = await this.usersRepository.findOne({ where: { id } });
    if (!updatedUser) {
      throw new Error('User not found after update');
    }
    return updatedUser;
  }
}
