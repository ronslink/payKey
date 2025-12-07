import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { PayPeriodsService } from './pay-periods.service';
import { CreatePayPeriodDto } from './dto/create-pay-period.dto';
import { UpdatePayPeriodDto } from './dto/update-pay-period.dto';
import {
  PayPeriodStatus,
  PayPeriodFrequency,
} from './entities/pay-period.entity';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('pay-periods')
@UseGuards(JwtAuthGuard)
export class PayPeriodsController {
  constructor(private readonly payPeriodsService: PayPeriodsService) { }

  @Post()
  create(@Request() req: any, @Body() createPayPeriodDto: CreatePayPeriodDto) {
    return this.payPeriodsService.create(createPayPeriodDto, req.user.userId);
  }

  @Get()
  findAll(
    @Request() req: any,
    @Query('page') page: string = '1',
    @Query('limit') limit: string = '10',
    @Query('status') status?: PayPeriodStatus,
    @Query('frequency') frequency?: string,
  ) {
    const pageNum = parseInt(page, 10) || 1;
    const limitNum = parseInt(limit, 10) || 10;

    return this.payPeriodsService.findAll(req.user.userId, pageNum, limitNum, status, frequency);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.payPeriodsService.findOne(id);
  }

  @Patch(':id')
  update(
    @Param('id') id: string,
    @Body() updatePayPeriodDto: UpdatePayPeriodDto,
  ) {
    return this.payPeriodsService.update(id, updatePayPeriodDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.payPeriodsService.remove(id);
  }

  @Post(':id/activate')
  activate(@Param('id') id: string) {
    return this.payPeriodsService.activate(id);
  }

  @Post(':id/process')
  process(@Param('id') id: string) {
    return this.payPeriodsService.process(id);
  }

  @Post(':id/complete')
  complete(@Param('id') id: string) {
    return this.payPeriodsService.complete(id);
  }

  @Post(':id/close')
  close(@Param('id') id: string) {
    return this.payPeriodsService.close(id);
  }

  @Post(':id/generate-taxes')
  async generateTaxes(@Param('id') id: string) {
    await this.payPeriodsService.generateTaxSubmissionData(id);
    return { message: 'Tax submission data generated successfully' };
  }

  @Get(':id/statistics')
  getStatistics(@Param('id') id: string) {
    return this.payPeriodsService.getPayPeriodStatistics(id);
  }

  @Post('generate')
  generatePayPeriods(
    @Body()
    body: {
      userId: string;
      frequency: PayPeriodFrequency;
      startDate: string;
      endDate: string;
    },
  ) {
    return this.payPeriodsService.generatePayPeriods(
      body.userId,
      body.frequency,
      new Date(body.startDate),
      new Date(body.endDate),
    );
  }
}
