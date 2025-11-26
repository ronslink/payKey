import { Injectable, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Country } from './entities/country.entity';

@Injectable()
export class CountriesService implements OnModuleInit {
  constructor(
    @InjectRepository(Country)
    private countriesRepository: Repository<Country>,
  ) {}

  async onModuleInit() {
    // Seed Kenya if not exists
    const count = await this.countriesRepository.count();
    if (count === 0) {
      await this.countriesRepository.save({
        code: 'KE',
        name: 'Kenya',
        currency: 'KES',
        isActive: true,
      });
    }
  }

  findAll() {
    return this.countriesRepository.find({ where: { isActive: true } });
  }

  findOne(id: string) {
    return this.countriesRepository.findOne({ where: { id } });
  }
}
