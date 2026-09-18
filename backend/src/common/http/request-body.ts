import { INestApplication } from '@nestjs/common';
import { json, urlencoded } from 'express';
import type { IncomingMessage, ServerResponse } from 'http';

/** Preserve the exact received bytes for signed payment webhooks. */
export function registerRequestBodyParsers(app: INestApplication): void {
  const captureRawBody = (
    req: IncomingMessage & { rawBody?: Buffer },
    _res: ServerResponse,
    buffer: Buffer,
  ) => {
    req.rawBody = buffer;
  };
  app.use(json({ verify: captureRawBody }));
  app.use(urlencoded({ verify: captureRawBody, extended: true }));
}
