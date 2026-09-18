import { ConfigService } from '@nestjs/config';
import {
  NotificationType,
  NotificationsService,
} from './notifications.service';

describe('production notification delivery', () => {
  it.each([
    NotificationType.SMS,
    NotificationType.EMAIL,
    NotificationType.PUSH,
  ])('does not report unconfigured %s as sent', async (type) => {
    const service = new NotificationsService(
      new ConfigService({ NODE_ENV: 'production' }),
      {} as never,
    );
    const result = await service.sendNotification({
      type,
      recipientPhone: '254700000000',
      recipientEmail: 'user@example.test',
      recipientToken: 'device-token',
      subject: 'Test',
      message: 'Test',
    });
    expect(result.success).toBe(false);
    expect(result.messageId).toBeUndefined();
  });
});
