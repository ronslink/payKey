import {
  Injectable,
  NotFoundException,
  BadRequestException,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { User, UserRole, UserTier } from '../../users/entities/user.entity';
import { Worker } from '../entities/worker.entity';

@Injectable()
export class EmployeePortalService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    @InjectRepository(Worker)
    private workersRepository: Repository<Worker>,
    private jwtService: JwtService,
  ) {}

  /**
   * Generate an invite code for a worker
   */
  async generateInviteCode(
    workerId: string,
    employerId: string,
  ): Promise<{
    inviteCode: string;
    expiresAt: Date;
  }> {
    const worker = await this.workersRepository.findOne({
      where: { id: workerId, userId: employerId },
    });

    if (!worker) {
      throw new NotFoundException('Worker not found');
    }

    if (worker.linkedUserId) {
      throw new BadRequestException('Worker already has an account');
    }

    // Generate 6-digit code
    const inviteCode = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7); // Valid for 7 days

    worker.inviteCode = inviteCode;
    worker.inviteCodeExpiry = expiresAt;

    await this.workersRepository.save(worker);

    return { inviteCode, expiresAt };
  }

  /**
   * Employee claims their account using phone + invite code
   */
  async claimAccount(
    phoneNumber: string,
    inviteCode: string,
    pin: string,
  ): Promise<{ accessToken: string; user: Partial<User> }> {
    // Normalize phone number
    const normalizedPhone = this.normalizePhoneNumber(phoneNumber);

    // Find worker by phone and invite code
    const worker = await this.workersRepository.findOne({
      where: {
        phoneNumber: normalizedPhone,
        inviteCode: inviteCode,
      },
    });

    if (!worker) {
      // Try with original phone number
      const workerOriginal = await this.workersRepository.findOne({
        where: {
          phoneNumber: phoneNumber,
          inviteCode: inviteCode,
        },
      });

      if (!workerOriginal) {
        throw new BadRequestException('Invalid phone number or invite code');
      }

      return this.processClaimAccount(workerOriginal, pin);
    }

    return this.processClaimAccount(worker, pin);
  }

  private async processClaimAccount(
    worker: Worker,
    pin: string,
  ): Promise<{ accessToken: string; user: Partial<User> }> {
    // Check expiry
    if (worker.inviteCodeExpiry && new Date() > worker.inviteCodeExpiry) {
      throw new BadRequestException('Invite code has expired');
    }

    if (worker.linkedUserId) {
      throw new BadRequestException('Account already claimed');
    }

    // Validate PIN format (4-6 digits)
    if (!/^\d{4,6}$/.test(pin)) {
      throw new BadRequestException('PIN must be 4-6 digits');
    }

    // Hash PIN
    const hashedPin = await bcrypt.hash(pin, 10);

    // Create employee user account
    const user = this.usersRepository.create({
      email: worker.email || `worker-${worker.id}@paykey.local`,
      passwordHash: hashedPin, // Store hashed PIN as password
      role: UserRole.WORKER,
      employerId: worker.userId,
      linkedWorkerId: worker.id,
      phoneNumber: worker.phoneNumber,
      pin: hashedPin,
      firstName: worker.name.split(' ')[0],
      lastName: worker.name.split(' ').slice(1).join(' ') || '',
    });

    const savedUser = await this.usersRepository.save(user);

    // Link worker to user
    worker.linkedUserId = savedUser.id;
    worker.inviteCode = undefined as any; // Clear invite code
    worker.inviteCodeExpiry = undefined as any;
    await this.workersRepository.save(worker);

    // Get employer info to inherit their subscription tier
    const employer = await this.usersRepository.findOne({
      where: { id: worker.userId },
    });

    // Generate JWT
    const payload = {
      sub: savedUser.id,
      userId: savedUser.id,
      role: UserRole.WORKER,
      employerId: worker.userId,
      workerId: worker.id,
    };

    const accessToken = this.jwtService.sign(payload);

    return {
      accessToken,
      user: {
        id: savedUser.id,
        email: savedUser.email,
        firstName: savedUser.firstName,
        lastName: savedUser.lastName,
        role: savedUser.role,
        linkedWorkerId: savedUser.linkedWorkerId,
        tier: employer ? employer.tier : UserTier.FREE,
      },
    };
  }

  /**
   * Employee login with phone + PIN
   */
  async employeeLogin(
    phoneNumber: string,
    pin: string,
  ): Promise<{ accessToken: string; user: Partial<User> }> {
    const normalizedPhone = this.normalizePhoneNumber(phoneNumber);

    // Find user by phone
    let user = await this.usersRepository.findOne({
      where: { phoneNumber: normalizedPhone, role: UserRole.WORKER },
    });

    if (!user) {
      // Try with original phone number
      user = await this.usersRepository.findOne({
        where: { phoneNumber: phoneNumber, role: UserRole.WORKER },
      });
    }

    if (!user) {
      throw new UnauthorizedException('Invalid phone number or PIN');
    }

    // Verify PIN
    const isValidPin = await bcrypt.compare(pin, user.pin || user.passwordHash);
    if (!isValidPin) {
      throw new UnauthorizedException('Invalid phone number or PIN');
    }

    // Get worker info
    const worker = await this.workersRepository.findOne({
      where: { id: user.linkedWorkerId },
    });

    // Get employer info to inherit their subscription tier
    const employer = await this.usersRepository.findOne({
      where: { id: user.employerId },
    });

    // Generate JWT
    const payload = {
      sub: user.id,
      userId: user.id,
      role: UserRole.WORKER,
      employerId: user.employerId,
      workerId: user.linkedWorkerId,
    };

    const accessToken = this.jwtService.sign(payload);

    return {
      accessToken,
      user: {
        id: user.id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        role: user.role,
        linkedWorkerId: user.linkedWorkerId,
        employerId: user.employerId,
        // Vital: Return employer's tier so mobile app enables features like Time Tracking
        tier: employer ? employer.tier : UserTier.FREE,
      },
    };
  }

  /**
   * Check if a worker has been invited
   */
  async checkInviteStatus(
    workerId: string,
    employerId: string,
  ): Promise<{
    hasAccount: boolean;
    hasInvite: boolean;
    inviteExpiry: Date | null;
  }> {
    const worker = await this.workersRepository.findOne({
      where: { id: workerId, userId: employerId },
    });

    if (!worker) {
      throw new NotFoundException('Worker not found');
    }

    return {
      hasAccount: !!worker.linkedUserId,
      hasInvite: !!worker.inviteCode,
      inviteExpiry: worker.inviteCodeExpiry,
    };
  }

  private normalizePhoneNumber(phone: string): string {
    // Remove all non-digits
    let digits = phone.replace(/\D/g, '');

    // Handle Kenyan numbers
    if (digits.startsWith('254')) {
      digits = '+' + digits;
    } else if (digits.startsWith('0')) {
      digits = '+254' + digits.substring(1);
    } else if (digits.startsWith('7') || digits.startsWith('1')) {
      digits = '+254' + digits;
    }

    return digits;
  }
}
