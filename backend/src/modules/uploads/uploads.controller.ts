import {
    Controller,
    Post,
    UseInterceptors,
    UploadedFile,
    UseGuards,
    HttpCode,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { UploadsService } from './uploads.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ApiConsumes, ApiBody, ApiTags } from '@nestjs/swagger';

@ApiTags('uploads')
@Controller('uploads')
@UseGuards(JwtAuthGuard)
export class UploadsController {
    constructor(private readonly uploadsService: UploadsService) { }

    @Post('avatar')
    @HttpCode(201)
    @UseInterceptors(FileInterceptor('file'))
    @ApiConsumes('multipart/form-data')
    @ApiBody({
        schema: {
            type: 'object',
            properties: {
                file: {
                    type: 'string',
                    format: 'binary',
                },
            },
        },
    })
    async uploadAvatar(@UploadedFile() file: Express.Multer.File) {
        const url = await this.uploadsService.saveAvatar(file);
        return { url };
    }
}
