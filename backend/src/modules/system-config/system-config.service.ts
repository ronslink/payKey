import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SystemConfig } from './entities/system-config.entity';

@Injectable()
export class SystemConfigService {
  private cache = new Map<string, string>();

  constructor(
    @InjectRepository(SystemConfig)
    private configRepository: Repository<SystemConfig>,
  ) {}

  async get(key: string): Promise<string | null> {
    if (this.cache.has(key)) {
      return this.cache.get(key) || null;
    }

    const config = await this.configRepository.findOne({ where: { key } });
    if (config) {
      this.cache.set(key, config.value);
      return config.value;
    }
    return null;
  }

  async set(key: string, value: string, description?: string): Promise<void> {
    const config = this.configRepository.create({ key, value, description });
    await this.configRepository.save(config);
    this.cache.set(key, value);
  }
}
