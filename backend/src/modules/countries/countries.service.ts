import { Injectable, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Country } from './entities/country.entity';

import { ALL_COUNTRIES } from './countries.data';

@Injectable()
export class CountriesService implements OnModuleInit {
  constructor(
    @InjectRepository(Country)
    private countriesRepository: Repository<Country>,
  ) {}

  async onModuleInit() {
    for (const country of ALL_COUNTRIES) {
      const exists = await this.countriesRepository.findOne({
        where: { code: country.code },
      });
      if (!exists) {
        await this.countriesRepository.save({
          ...country,
          isActive: true,
        });
      }
    }
  }

  findAll() {
    return this.countriesRepository.find({ where: { isActive: true } });
  }

  findOne(id: string) {
    return this.countriesRepository.findOne({ where: { id } });
  }
}
