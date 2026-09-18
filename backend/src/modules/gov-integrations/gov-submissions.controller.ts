import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  Res,
  UseGuards,
  Request,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import type { Response } from 'express';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { resolvePrivateFile } from '../uploads/storage-paths';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import {
  GovSubmission,
  GovSubmissionStatus,
} from './entities/gov-submission.entity';
import { KraService } from './services/kra.service';
import { ShifService } from './services/shif.service';
import { NssfService } from './services/nssf.service';

@Controller('gov')
@UseGuards(JwtAuthGuard)
export class GovSubmissionsController {
  constructor(
    @InjectRepository(GovSubmission)
    private readonly govSubmissionRepository: Repository<GovSubmission>,
    private readonly kraService: KraService,
    private readonly shifService: ShifService,
    private readonly nssfService: NssfService,
  ) {}

  /**
   * Get all submissions for the current user
   */
  @Get('submissions')
  async getSubmissions(@Request() req: any) {
    return this.govSubmissionRepository.find({
      where: { userId: req.user.userId },
      relations: ['payPeriod'],
      order: { createdAt: 'DESC' },
    });
  }

  /**
   * Get a specific submission
   */
  @Get('submissions/:id')
  async getSubmission(@Param('id') id: string, @Request() req: any) {
    const submission = await this.govSubmissionRepository.findOne({
      where: { id, userId: req.user.userId },
      relations: ['payPeriod'],
    });

    if (!submission) {
      throw new NotFoundException('Submission not found');
    }

    return submission;
  }

  /**
   * Generate a PAYE supporting worksheet (not an iTax upload template).
   */
  @Post('kra/generate')
  async generateP10(
    @Body() body: { payPeriodId: string },
    @Request() req: any,
  ) {
    if (!body.payPeriodId) {
      throw new BadRequestException('payPeriodId is required');
    }
    return this.kraService.generateP10Excel(body.payPeriodId, req.user.userId);
  }

  /**
   * Generate SHIF contribution file
   */
  @Post('shif/generate')
  async generateShif(
    @Body() body: { payPeriodId: string },
    @Request() req: any,
  ) {
    if (!body.payPeriodId) {
      throw new BadRequestException('payPeriodId is required');
    }
    return this.shifService.generateContributionFile(
      body.payPeriodId,
      req.user.userId,
    );
  }

  /**
   * Generate NSSF SF24 file
   */
  @Post('nssf/generate')
  async generateNssf(
    @Body() body: { payPeriodId: string },
    @Request() req: any,
  ) {
    if (!body.payPeriodId) {
      throw new BadRequestException('payPeriodId is required');
    }
    return this.nssfService.generateSF24(body.payPeriodId, req.user.userId);
  }

  /**
   * Download a generated file
   */
  @Get('submissions/:id/download')
  async downloadFile(
    @Param('id') id: string,
    @Request() req: any,
    @Res() res: Response,
  ) {
    const submission = await this.govSubmissionRepository.findOne({
      where: { id, userId: req.user.userId },
    });

    if (!submission) {
      throw new NotFoundException('Submission not found');
    }

    if (!submission.filePath) {
      throw new NotFoundException('File not found');
    }

    const filePath = await resolvePrivateFile(submission.filePath, 'gov-files');
    res.set({
      'Cache-Control': 'private, no-store',
      'X-Content-Type-Options': 'nosniff',
    });
    res.download(filePath, submission.fileName);
  }

  /**
   * Mark submission as uploaded (user uploaded to portal)
   */
  @Patch('submissions/:id/uploaded')
  async markAsUploaded(@Param('id') id: string, @Request() req: any) {
    const submission = await this.govSubmissionRepository.findOne({
      where: { id, userId: req.user.userId },
    });

    if (!submission) {
      throw new NotFoundException('Submission not found');
    }

    submission.status = GovSubmissionStatus.UPLOADED;
    submission.uploadedAt = new Date();

    return this.govSubmissionRepository.save(submission);
  }

  /**
   * Confirm submission with reference number from portal
   */
  @Patch('submissions/:id/confirm')
  async confirmSubmission(
    @Param('id') id: string,
    @Body() body: { referenceNumber: string; notes?: string },
    @Request() req: any,
  ) {
    if (!body.referenceNumber) {
      throw new BadRequestException('referenceNumber is required');
    }

    const submission = await this.govSubmissionRepository.findOne({
      where: { id, userId: req.user.userId },
    });

    if (!submission) {
      throw new NotFoundException('Submission not found');
    }

    submission.status = GovSubmissionStatus.CONFIRMED;
    submission.referenceNumber = body.referenceNumber;
    if (body.notes) {
      submission.notes = body.notes;
    }
    submission.confirmedAt = new Date();

    return this.govSubmissionRepository.save(submission);
  }
}
