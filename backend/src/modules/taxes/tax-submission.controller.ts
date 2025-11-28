import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  UseGuards,
  Request,
} from '@nestjs/common';
import { TaxesService } from './taxes.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('taxes/submissions')
@UseGuards(JwtAuthGuard)
export class TaxSubmissionController {
  constructor(private readonly taxesService: TaxesService) { }

  @Get()
  async getSubmissions(@Request() req: any) {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    return this.taxesService.getSubmissions(req.user.userId);
  }

  @Patch(':id/file')
  async markAsFiled(@Request() req: any, @Param('id') id: string) {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    return this.taxesService.markAsFiled(id, req.user.userId);
  }

  @Post('generate')
  async generateSubmission(
    @Request() req: any,
    @Body() body: { payPeriodId: string },
  ) {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    return this.taxesService.generateTaxSubmission(
      body.payPeriodId,
      req.user.userId,
    );
  }
}
