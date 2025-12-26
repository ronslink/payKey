import { NestFactory } from '@nestjs/core';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';
import * as crypto from 'crypto';

// Fix for Node.js 18 compatibility with TypeORM
if (!globalThis.crypto) {
  globalThis.crypto = crypto as any;
}

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Trust proxy (required for Cloudflare/reverse proxies to get real client IP)
  // Only enable in production where we're behind a reverse proxy
  if (process.env.NODE_ENV === 'production') {
    const expressApp = app.getHttpAdapter().getInstance();
    expressApp.set('trust proxy', true);
  }

  // Enable CORS for all localhost development ports
  app.enableCors({
    origin: true, // Allow all origins in development (including all localhost ports)
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: [
      'Content-Type',
      'Authorization',
      'Accept',
      'Origin',
      'X-Requested-With',
      'Access-Control-Request-Method',
      'Access-Control-Request-Headers',
      'Accept-Language',
      'Cache-Control',
      'Pragma',
      'Expires',
      'If-Modified-Since',
      'ETag',
      'Last-Modified',
    ],
    exposedHeaders: [
      'Content-Type',
      'Authorization',
      'Content-Disposition',
      'Content-Length',
    ],
  });

  // Swagger Documentation Setup
  const config = new DocumentBuilder()
    .setTitle('PayKey API')
    .setDescription('The PayKey Payroll Management API description')
    .setVersion('1.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api', app, document);

  // Start the application
  await app.listen(process.env.PORT ?? 3000, '0.0.0.0');
}
bootstrap();
