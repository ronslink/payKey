import { Injectable, BadRequestException } from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';
import * as crypto from 'crypto';

@Injectable()
export class UploadsService {
    private readonly uploadDir = 'uploads';

    constructor() {
        this.ensureUploadDirExists();
    }

    private ensureUploadDirExists() {
        const avatarsDir = path.join(this.uploadDir, 'avatars');
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

        const fileExt = path.extname(file.originalname);
        const fileName = `${crypto.randomUUID()}${fileExt}`;
        const filePath = path.join(this.uploadDir, 'avatars', fileName);

        try {
            await fs.promises.writeFile(filePath, file.buffer);
            // Return relative path for URL construction
            const baseUrl = process.env.API_URL || 'http://localhost:3000';
            return `${baseUrl}/uploads/avatars/${fileName}`;
        } catch (error) {
            throw new Error(`Failed to save file: ${error.message}`);
        }
    }

    async saveDocument(file: Express.Multer.File, workerId: string): Promise<string> {
        if (!file) {
            throw new BadRequestException('No file uploaded');
        }

        // Create worker-specific documents directory
        const workerDocsDir = path.join(this.uploadDir, 'documents', workerId);
        if (!fs.existsSync(workerDocsDir)) {
            fs.mkdirSync(workerDocsDir, { recursive: true });
        }

        const fileExt = path.extname(file.originalname);
        const fileName = `${crypto.randomUUID()}${fileExt}`;
        const filePath = path.join(workerDocsDir, fileName);

        try {
            await fs.promises.writeFile(filePath, file.buffer);
            const baseUrl = process.env.API_URL || 'http://localhost:3000';
            return `${baseUrl}/uploads/documents/${workerId}/${fileName}`;
        } catch (error) {
            throw new Error(`Failed to save document: ${error.message}`);
        }
    }

    async deleteDocument(url: string): Promise<void> {
        try {
            // Extract relative path from URL
            const urlObj = new URL(url);
            const relativePath = urlObj.pathname.replace(/^\//, ''); // Remove leading slash
            const filePath = path.join(process.cwd(), relativePath);

            if (fs.existsSync(filePath)) {
                await fs.promises.unlink(filePath);
            }
        } catch (error) {
            // Log but don't throw - file might already be deleted
            console.warn(`Failed to delete file: ${error.message}`);
        }
    }
}
