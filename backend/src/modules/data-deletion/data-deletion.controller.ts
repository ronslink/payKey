import { Controller, Post, Get, Body, Param, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { DataDeletionService } from './data-deletion.service';
import { CreateDeletionRequestDto } from './dto/create-deletion-request.dto';
import { DeletionRequest } from './entities/deletion-request.entity';

@ApiTags('Data Deletion')
@Controller('data-deletion')
export class DataDeletionController {
    constructor(private readonly dataDeletionService: DataDeletionService) { }

    @Post('request')
    @HttpCode(HttpStatus.ACCEPTED)
    @ApiOperation({
        summary: 'Request account data deletion',
        description: 'Submit a request to delete all data associated with an email address. The deletion will be processed automatically.',
    })
    @ApiResponse({
        status: 202,
        description: 'Deletion request accepted and queued for processing',
    })
    async createRequest(
        @Body() dto: CreateDeletionRequestDto,
    ): Promise<{ message: string; requestId: string }> {
        const request = await this.dataDeletionService.createRequest(dto);
        return {
            message: 'Your deletion request has been received and will be processed automatically. All associated data will be permanently deleted.',
            requestId: request.id,
        };
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
    async getStatus(@Param('id') id: string): Promise<DeletionRequest | { message: string }> {
        const request = await this.dataDeletionService.getRequestStatus(id);
        if (!request) {
            return { message: 'Request not found' };
        }
        return request;
    }
}
