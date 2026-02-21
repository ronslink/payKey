import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Body,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  Request,
  HttpCode,
  BadRequestException,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiTags, ApiConsumes, ApiBody } from '@nestjs/swagger';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtAuthGuard } from '../../auth/jwt-auth.guard';
import {
  WorkerDocument,
  DocumentType,
} from '../entities/worker-document.entity';
import { Worker } from '../entities/worker.entity';
import { UploadDocumentDto } from '../dto/upload-document.dto';
import { UploadsService } from '../../uploads/uploads.service';

@ApiTags('Worker Documents')
@Controller('workers')
@UseGuards(JwtAuthGuard)
export class WorkerDocumentsController {
  constructor(
    @InjectRepository(WorkerDocument)
    private readonly documentRepository: Repository<WorkerDocument>,
    @InjectRepository(Worker)
    private readonly workerRepository: Repository<Worker>,
    private readonly uploadsService: UploadsService,
  ) {}

  /**
   * Get all documents for a worker
   */
  @Get(':workerId/documents')
  async getDocuments(@Param('workerId') workerId: string, @Request() req: any) {
    console.log(
      `[WorkerDocumentsController] getDocuments called for worker: ${workerId}, user: ${req.user?.userId}`,
    );
    try {
      // Verify worker belongs to this user
      const worker = await this.workerRepository.findOne({
        where: { id: workerId, userId: req.user.userId },
      });

      if (!worker) {
        console.log(
          `[WorkerDocumentsController] Worker not found or not owned by user`,
        );
        throw new NotFoundException('Worker not found');
      }

      const documents = await this.documentRepository.find({
        where: { workerId },
        order: { createdAt: 'DESC' },
      });
      console.log(
        `[WorkerDocumentsController] Found ${documents.length} documents`,
      );

      return documents;
    } catch (error) {
      console.error(
        '[WorkerDocumentsController] Error in getDocuments:',
        error,
      );
      throw error;
    }
  }

  /**
   * Upload a document for a worker
   */
  @Post(':workerId/documents')
  @HttpCode(201)
  @UseInterceptors(FileInterceptor('file'))
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: { type: 'string', format: 'binary' },
        type: { type: 'string', enum: Object.values(DocumentType) },
        notes: { type: 'string' },
        expiresAt: { type: 'string', format: 'date' },
      },
    },
  })
  async uploadDocument(
    @Param('workerId') workerId: string,
    @UploadedFile() file: Express.Multer.File,
    @Body() dto: UploadDocumentDto,
    @Request() req: any,
  ) {
    if (!file) {
      throw new BadRequestException('No file uploaded');
    }

    // Verify worker belongs to this user
    const worker = await this.workerRepository.findOne({
      where: { id: workerId, userId: req.user.userId },
    });

    if (!worker) {
      throw new NotFoundException('Worker not found');
    }

    // Save file using uploads service
    const url = await this.uploadsService.saveDocument(file, workerId);

    // Create document record
    const document = this.documentRepository.create({
      workerId,
      type: dto.type || DocumentType.OTHER,
      name: file.originalname,
      url,
      fileSize: file.size,
      mimeType: file.mimetype,
      expiresAt: dto.expiresAt ? new Date(dto.expiresAt) : undefined,
      notes: dto.notes,
    });

    await this.documentRepository.save(document);

    return document;
  }

  /**
   * Delete a document
   */
  @Delete('documents/:documentId')
  @HttpCode(204)
  async deleteDocument(
    @Param('documentId') documentId: string,
    @Request() req: any,
  ) {
    // Find document and verify ownership through worker
    const document = await this.documentRepository.findOne({
      where: { id: documentId },
      relations: ['worker'],
    });

    if (!document) {
      throw new NotFoundException('Document not found');
    }

    // Verify worker belongs to this user
    const worker = await this.workerRepository.findOne({
      where: { id: document.workerId, userId: req.user.userId },
    });

    if (!worker) {
      throw new ForbiddenException('Access denied');
    }

    // Delete file from filesystem
    await this.uploadsService.deleteDocument(document.url);

    // Delete database record
    await this.documentRepository.delete(documentId);
  }
}
