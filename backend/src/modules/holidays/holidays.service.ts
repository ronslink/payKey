import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Holiday } from './entities/holiday.entity';

@Injectable()
export class HolidaysService implements OnModuleInit {
    private readonly logger = new Logger(HolidaysService.name);

    constructor(
        @InjectRepository(Holiday)
        private holidaysRepository: Repository<Holiday>,
    ) { }

    async onModuleInit() {
        await this.seedHolidays();
    }

    async seedHolidays() {
        const count = await this.holidaysRepository.count();
        if (count > 0) return;

        this.logger.log('Seeding Kenyan Holidays...');

        const fixedHolidays = [
            { name: 'New Year\'s Day', date: '2024-01-01', isRecurring: true },
            { name: 'Labour Day', date: '2024-05-01', isRecurring: true },
            { name: 'Madaraka Day', date: '2024-06-01', isRecurring: true },
            { name: 'Mazingira Day', date: '2024-10-10', isRecurring: true },
            { name: 'Mashujaa Day', date: '2024-10-20', isRecurring: true },
            { name: 'Jamhuri Day', date: '2024-12-12', isRecurring: true },
            { name: 'Christmas Day', date: '2024-12-25', isRecurring: true },
            { name: 'Boxing Day', date: '2024-12-26', isRecurring: true },
        ];

        // Variable holidays for 2024 and 2025
        const variableHolidays = [
            { name: 'Good Friday', date: '2024-03-29', isRecurring: false },
            { name: 'Easter Monday', date: '2024-04-01', isRecurring: false },
            { name: 'Idd-ul-Fitr', date: '2024-04-10', isRecurring: false }, // Approx
            { name: 'Idd-ul-Azha', date: '2024-06-17', isRecurring: false }, // Approx

            { name: 'Good Friday', date: '2025-04-18', isRecurring: false },
            { name: 'Easter Monday', date: '2025-04-21', isRecurring: false },
        ];

        const allHolidays = [...fixedHolidays, ...variableHolidays];

        for (const h of allHolidays) {
            await this.holidaysRepository.save(this.holidaysRepository.create(h));
        }

        this.logger.log(`Seeded ${allHolidays.length} holidays.`);
    }

    async findAll() {
        return this.holidaysRepository.find({ order: { date: 'ASC' } });
    }

    async create(createHolidayDto: Partial<Holiday>) {
        const holiday = this.holidaysRepository.create(createHolidayDto);
        return this.holidaysRepository.save(holiday);
    }

    async isHoliday(date: Date): Promise<boolean> {
        const dateString = date.toISOString().split('T')[0];
        const month = date.getMonth() + 1;
        const day = date.getDate();
        // Reconstruct YYYY-MM-DD for recurring check (using seed year 2024 as base for recurring logic?? No better logic needed)

        // Check specific date
        const specific = await this.holidaysRepository.findOne({ where: { date: dateString } });
        if (specific) return true;

        // Check recurring (ignore year)
        // TypeORM doesn't have easy "month/day" extraction in query builder across all DBs easily differently.
        // So we fetch all recurring and check in JS for now (low volume).
        const recurring = await this.holidaysRepository.find({ where: { isRecurring: true } });

        return recurring.some(h => {
            const hDate = new Date(h.date);
            return hDate.getMonth() + 1 === month && hDate.getDate() === day;
        });
    }
}
