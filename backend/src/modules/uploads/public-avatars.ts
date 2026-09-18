import type { NestExpressApplication } from '@nestjs/platform-express';
import type { Request, Response, NextFunction } from 'express';
import { existingFileWithin, publicAvatarRoots } from './storage-paths';

/** Only avatars are public. Documents and government exports have guarded routes. */
export function registerPublicAvatars(
  app: Pick<NestExpressApplication, 'use'>,
): void {
  app.use(
    '/uploads/avatars',
    async (req: Request, res: Response, next: NextFunction) => {
      if (!['GET', 'HEAD'].includes(req.method)) return next();
      const filename = req.path.slice(1);
      if (!/^[a-zA-Z0-9_-]+\.(jpe?g|png|gif|webp)$/i.test(filename))
        return next();
      for (const root of publicAvatarRoots()) {
        const file = await existingFileWithin(root, filename);
        if (file) {
          res.set({
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, HEAD',
            'Cross-Origin-Resource-Policy': 'cross-origin',
            'X-Content-Type-Options': 'nosniff',
          });
          return res.sendFile(file);
        }
      }
      next();
    },
  );
}
