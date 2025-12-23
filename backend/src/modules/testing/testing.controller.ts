import { Controller, Post, Body } from '@nestjs/common';
import { TestingService } from './testing.service';

@Controller('testing')
export class TestingController {
  constructor(private readonly testingService: TestingService) {}

  @Post('reset-payroll')
  async resetPayroll(@Body() body: { email: string }) {
    return this.testingService.resetPayrollForUser(body.email);
  }
}
