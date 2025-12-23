import { Controller, Get, Post, Body, Query } from '@nestjs/common';
import { HolidaysService } from './holidays.service';
import { Holiday } from './entities/holiday.entity';

@Controller('holidays')
export class HolidaysController {
  constructor(private readonly holidaysService: HolidaysService) {}

  @Get()
  findAll() {
    return this.holidaysService.findAll();
  }

  @Post()
  create(@Body() createHolidayDto: Partial<Holiday>) {
    return this.holidaysService.create(createHolidayDto);
  }
}
