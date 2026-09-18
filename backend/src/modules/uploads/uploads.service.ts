import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';
import * as crypto from 'crypto';
import { resolvePrivateFile, storageRoot } from './storage-paths';

@Injectable()
export class UploadsService {
  private readonly uploadDir = storageRoot();

  constructor() {
    this.ensureUploadDirExists();
  }

  private ensureUploadDirExists() {
    const avatarsDir = path.join(this.uploadDir, 'public', 'avatars');
    if (!fs.existsSync(avatarsDir)) {
      fs.mkdirSync(avatarsDir, { recursive: true });
    }
  }

  async saveAvatar(file: Express.Multer.File): Promise<string> {
    if (!file) {
      throw new BadRequestException('No file uploaded');
    }

    // Validate mime type
    if (!file.mimetype.match(/^image\/(jpg|jpeg|png|gif|webp)$/)) {
      throw new BadRequestException('Only image files are allowed');
    }

    const fileExt = `.${file.mimetype.split('/')[1] === 'jpeg' ? 'jpg' : file.mimetype.split('/')[1]}`;
    const fileName = `${crypto.randomUUID()}${fileExt}`;
    const filePath = path.join(this.uploadDir, 'public', 'avatars', fileName);

    try {
      await fs.promises.writeFile(filePath, file.buffer);
      // Return relative path for URL construction
      const baseUrl = process.env.API_URL || 'http://localhost:3000';
      return `${baseUrl}/uploads/avatars/${fileName}`;
    } catch (error) {
      throw new Error(`Failed to save file: ${error.message}`);
    }
  }

  async saveDocument(
    file: Express.Multer.File,
    workerId: string,
  ): Promise<string> {
    if (!file) {
      throw new BadRequestException('No file uploaded');
    }

    if (!/^[a-f0-9-]{36}$/i.test(workerId)) {
      throw new BadRequestException('Invalid worker ID');
    }

    const workerDocsDir = path.join(
      this.uploadDir,
      'private',
      'documents',
      workerId,
    );
    if (!fs.existsSync(workerDocsDir)) {
      fs.mkdirSync(workerDocsDir, { recursive: true, mode: 0o700 });
    }

    const originalExtension = path.extname(file.originalname).toLowerCase();
    const fileExt = /^\.[a-z0-9]{1,10}$/.test(originalExtension)
      ? originalExtension
      : '';
    const fileName = `${crypto.randomUUID()}${fileExt}`;
    const filePath = path.join(workerDocsDir, fileName);

    try {
      await fs.promises.writeFile(filePath, file.buffer, { mode: 0o600 });
      return `private/documents/${workerId}/${fileName}`;
    } catch (error) {
      throw new Error(`Failed to save document: ${error.message}`);
    }
  }

  async resolveDocument(reference: string, workerId: string): Promise<string> {
    return resolvePrivateFile(reference, 'documents', workerId);
  }

  async deleteDocument(reference: string, workerId: string): Promise<void> {
    try {
      const filePath = await this.resolveDocument(reference, workerId);
      await fs.promises.unlink(filePath);
    } catch (error) {
      if (error instanceof NotFoundException) return;
      // Legacy backups may be mounted read-only; deleting the record revokes access.
      console.warn(`Failed to delete file: ${error.message}`);
    }
  }
}
