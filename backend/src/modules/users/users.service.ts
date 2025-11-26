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
  ) {}

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
    // If compliance data is being updated, mark onboarding as completed
    const hasComplianceData =
      updateUserDto.kraPin ||
      updateUserDto.nssfNumber ||
      updateUserDto.nhifNumber;

    if (hasComplianceData) {
      updateUserDto.isOnboardingCompleted = true;
    }

    await this.usersRepository.update(id, updateUserDto);
    const user = await this.usersRepository.findOne({ where: { id } });
    if (!user) {
      throw new Error('User not found');
    }
    return user;
  }
}
