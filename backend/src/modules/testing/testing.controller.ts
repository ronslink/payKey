import { Controller, Post, Body, NotFoundException } from '@nestjs/common';
import { TestingService } from './testing.service';

@Controller('testing')
export class TestingController {
  constructor(private readonly testingService: TestingService) {}

  @Post('reset-payroll')
  async resetPayroll(@Body() body: { email: string }) {
    if (process.env.NODE_ENV !== 'test') {
      throw new NotFoundException();
    }
    return this.testingService.resetPayrollForUser(body.email);
  }
}
