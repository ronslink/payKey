import { OnModuleInit } from '@nestjs/common';
import { Repository } from 'typeorm';
import { Country } from './entities/country.entity';
export declare class CountriesService implements OnModuleInit {
    private countriesRepository;
    constructor(countriesRepository: Repository<Country>);
    onModuleInit(): Promise<void>;
    findAll(): Promise<Country[]>;
    findOne(id: string): Promise<Country | null>;
}
