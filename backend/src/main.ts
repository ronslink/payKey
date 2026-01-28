import { NestFactory } from '@nestjs/core';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';
import * as crypto from 'crypto';
import { json, urlencoded } from 'express';

// Fix for Node.js 18 compatibility with TypeORM
if (!globalThis.crypto) {
  globalThis.crypto = crypto as any;
}

import { NestExpressApplication } from '@nestjs/platform-express';
import { join } from 'path';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule, {
    bodyParser: false, // Disable default parser to handle raw body manually
  });

  // Serve static files from 'uploads' directory
  // Use process.cwd() to ensure we look in /app/uploads regardless of where dist/main.js is
  app.useStaticAssets(join(process.cwd(), 'uploads'), {
    prefix: '/uploads/',
    setHeaders: (res) => {
      res.set('Access-Control-Allow-Origin', '*');
      res.set('Access-Control-Allow-Methods', 'GET');
      res.set('Cross-Origin-Resource-Policy', 'cross-origin');
    },
  });

  // Middleware to capture raw body for webhook verification
  const rawBodyBuffer = (req: any, res: any, buf: Buffer, encoding: string) => {
    if (buf && buf.length) {
      req.rawBody = buf;
    }
  };

  app.use(json({ verify: rawBodyBuffer }));
  app.use(urlencoded({ verify: rawBodyBuffer, extended: true }));

  // Trust proxy (required for Cloudflare/reverse proxies to get real client IP)
  // Only enable in production where we're behind a reverse proxy
  if (process.env.NODE_ENV === 'production') {
    const expressApp = app.getHttpAdapter().getInstance();
    expressApp.set('trust proxy', true);
  }

  // Enable CORS for all localhost development ports
  app.enableCors({
    origin:
      process.env.NODE_ENV === 'production'
        ? [
          'https://paydome.co',
          'https://www.paydome.co',
          'http://localhost:8080',
          'http://0.0.0.0:8080',
          'http://127.0.0.1:8080'
        ]
        : true,
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
