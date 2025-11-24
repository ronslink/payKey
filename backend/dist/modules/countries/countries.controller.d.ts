import { CountriesService } from './countries.service';
export declare class CountriesController {
    private readonly countriesService;
    constructor(countriesService: CountriesService);
    findAll(): Promise<import("./entities/country.entity").Country[]>;
}
