import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  HttpCode,
  HttpStatus,
  UseGuards,
  Request,
  ValidationPipe,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { DataDeletionService } from './data-deletion.service';
import { CreateDeletionRequestDto } from './dto/create-deletion-request.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@ApiTags('Data Deletion')
@Controller('data-deletion')
export class DataDeletionController {
  constructor(private readonly dataDeletionService: DataDeletionService) {}

  @Post('request')
  @HttpCode(HttpStatus.ACCEPTED)
  @ApiOperation({
    summary: 'Request account data deletion',
    description:
      'Submit a request to delete all data associated with an email address. The deletion will be processed automatically.',
  })
  @ApiResponse({
    status: 202,
    description: 'Deletion request accepted and queued for processing',
  })
  async createRequest(
    @Body(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true }))
    dto: CreateDeletionRequestDto,
  ): Promise<{ message: string; requestId: string }> {
    const request = await this.dataDeletionService.createRequest(dto);
    return {
      message:
        'Your deletion request has been received and will be processed automatically. All associated data will be permanently deleted.',
      requestId: request.id,
    };
  }

  @Post('request/me')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.ACCEPTED)
  async createAuthenticatedRequest(
    @Request() req: { user: { userId: string } },
    @Body(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true }))
    dto: CreateDeletionRequestDto,
  ) {
    const request = await this.dataDeletionService.createRequest(
      dto,
      req.user.userId,
    );
    return { message: 'Account deletion requested.', requestId: request.id };
  }

  @Get('status/:id')
  @ApiOperation({
    summary: 'Check deletion request status',
    description: 'Check the status of a previously submitted deletion request',
  })
  @ApiResponse({
    status: 200,
    description: 'Returns the current status of the deletion request',
  })
  async getStatus(@Param('id') id: string) {
    const request = await this.dataDeletionService.getRequestStatus(id);
    if (!request) {
      return { message: 'Request not found' };
    }
    return {
      id: request.id,
      status: request.status,
      requestedAt: request.requestedAt,
      processedAt: request.processedAt,
    };
  }
}
