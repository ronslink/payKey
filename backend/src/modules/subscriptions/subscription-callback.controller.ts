
import { Controller, Get, Query, Res } from '@nestjs/common';
import type { Response } from 'express';

@Controller('subscription')
export class SubscriptionCallbackController {
    @Get('success')
    handleSuccess(@Query('session_id') sessionId: string, @Res() res: Response) {
        // Return a simple HTML page that closes itself or tells the user to return to the app
        const html = `
      <!DOCTYPE html>
      <html>
        <head>
          <title>Payment Successful</title>
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
            body {
              font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
              display: flex;
              justify-content: center;
              align-items: center;
              height: 100vh;
              margin: 0;
              background-color: #f0fdf4;
              color: #166534;
            }
            .container {
              text-align: center;
              padding: 2rem;
              background: white;
              border-radius: 1rem;
              box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
              max-width: 90%;
            }
            .icon {
              font-size: 4rem;
              margin-bottom: 1rem;
            }
            h1 { margin: 0 0 0.5rem; }
            p { margin: 0; color: #4b5563; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="icon">✅</div>
            <h1>Payment Successful!</h1>
            <p>Your subscription is now active.</p>
            <p style="margin-top: 1rem; font-size: 0.875rem;">
              You can close this window and return to the PayKey app.
            </p>
          </div>
          <script>
            // Try to close the window automatically
            setTimeout(() => {
              // window.close(); 
              // Window.close() only works if script opened it, so we rely on user action mostly
            }, 2000);
          </script>
        </body>
      </html>
    `;
        res.send(html);
    }

    @Get('cancel')
    handleCancel(@Res() res: Response) {
        const html = `
      <!DOCTYPE html>
      <html>
        <head>
          <title>Payment Cancelled</title>
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
            body {
              font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
              display: flex;
              justify-content: center;
              align-items: center;
              height: 100vh;
              margin: 0;
              background-color: #fef2f2;
              color: #991b1b;
            }
            .container {
              text-align: center;
              padding: 2rem;
              background: white;
              border-radius: 1rem;
              box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
              max-width: 90%;
            }
            .icon { font-size: 4rem; margin-bottom: 1rem; }
            h1 { margin: 0 0 0.5rem; }
            p { margin: 0; color: #4b5563; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="icon">❌</div>
            <h1>Payment Cancelled</h1>
            <p>No charges were made.</p>
             <p style="margin-top: 1rem; font-size: 0.875rem;">
              You can close this window and return to the PayKey app.
            </p>
          </div>
        </body>
      </html>
    `;
        res.send(html);
    }
}
