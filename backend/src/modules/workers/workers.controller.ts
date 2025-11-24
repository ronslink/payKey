import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  UseGuards,
  Request,
  Res,
  Delete,
} from '@nestjs/common';
import { WorkersService } from './workers.service';
import { CreateWorkerDto } from './dto/create-worker.dto';
import { CreateTerminationDto } from './dto/termination.dto';
import { TerminationService } from './services/termination.service';
import type { AuthenticatedRequest } from '../../common/interfaces/user.interface';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { SubscriptionGuard } from '../subscriptions/subscription.guard';
import type { Response } from 'express';

@Controller('workers')
@UseGuards(JwtAuthGuard)
export class WorkersController {
  constructor(
    private readonly workersService: WorkersService,
    private readonly terminationService: TerminationService,
  ) { }

  @Post()
  @UseGuards(SubscriptionGuard)
  create(
    @Request() req: AuthenticatedRequest,
    @Body() createWorkerDto: CreateWorkerDto,
  ) {
    return this.workersService.create(req.user.userId, createWorkerDto);
  }

  @Patch(':id')
  update(
    @Request() req: AuthenticatedRequest,
    @Param('id') id: string,
    @Body() updateWorkerDto: Partial<CreateWorkerDto>,
  ) {
    return this.workersService.update(id, req.user.userId, updateWorkerDto);
  }

  @Delete(':id')
  remove(@Request() req: AuthenticatedRequest, @Param('id') id: string) {
    return this.workersService.remove(id, req.user.userId);
  }

  @Get()
  async findAll(@Request() req: AuthenticatedRequest, @Res() res: Response) {
    const workers = await this.workersService.findAll(req.user.userId);

    // Explicitly prevent caching to avoid 304 responses
    res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
    res.setHeader('Pragma', 'no-cache');
    res.setHeader('Expires', '0');
    res.setHeader('ETag', `"workers-${Date.now()}-${workers.length}"`);
    res.setHeader('Last-Modified', new Date().toUTCString());

    return res.json(workers);
  }

  @Get(':id')
  findOne(@Request() req: AuthenticatedRequest, @Param('id') id: string) {
    return this.workersService.findOne(id, req.user.userId);
  }

  // Termination endpoints
  @Post(':id/calculate-final-payment')
  calculateFinalPayment(
    @Request() req: AuthenticatedRequest,
    @Param('id') id: string,
    @Body('terminationDate') terminationDate: string,
  ) {
    return this.terminationService.calculateFinalPayment(
      id,
      req.user.userId,
      new Date(terminationDate),
    );
  }

  @Post(':id/terminate')
  terminateWorker(
    @Request() req: AuthenticatedRequest,
    @Param('id') id: string,
    @Body() dto: CreateTerminationDto,
  ) {
    return this.terminationService.terminateWorker(id, req.user.userId, dto);
  }

  @Get('terminated/history')
  getTerminationHistory(@Request() req: AuthenticatedRequest) {
    return this.terminationService.getTerminationHistory(req.user.userId);
  }
}
