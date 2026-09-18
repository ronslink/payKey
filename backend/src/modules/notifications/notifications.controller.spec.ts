import { NotificationsController } from './notifications.controller';
import { DevicePlatform } from './entities/device-token.entity';

describe('device token ownership', () => {
  const createController = () => {
    const repository = {
      update: jest.fn(),
      findOne: jest.fn().mockResolvedValue(null),
      create: jest.fn((x) => x),
      save: jest.fn(),
    };
    const manager = {
      query: jest.fn(),
      getRepository: jest.fn(() => repository),
    };
    const transaction = jest.fn((callback) => callback(manager));
    const controller = new NotificationsController(
      {} as never,
      { manager: { transaction } } as never,
      {} as never,
    );
    return { controller, repository, manager, transaction };
  };

  it('deactivates previous account associations before activating the current owner', async () => {
    const { controller, repository, manager } = createController();
    await controller.registerDeviceToken(
      { user: { userId: 'new-user' } },
      { token: 'device-token', platform: DevicePlatform.ANDROID },
    );
    expect(manager.query).toHaveBeenCalledWith(
      'SELECT pg_advisory_xact_lock(hashtext($1))',
      ['device-token'],
    );
    expect(repository.update).toHaveBeenCalledWith(
      { token: 'device-token' },
      { isActive: false },
    );
    expect(repository.save).toHaveBeenCalledWith(
      expect.objectContaining({
        token: 'device-token',
        userId: 'new-user',
        isActive: true,
      }),
    );
    expect(repository.update.mock.invocationCallOrder[0]).toBeLessThan(
      repository.save.mock.invocationCallOrder[0],
    );
  });

  it('rejects missing or malformed device tokens before accessing persistence', async () => {
    const { controller, transaction } = createController();
    await expect(
      controller.registerDeviceToken(
        { user: { userId: 'user' } },
        { token: '', platform: DevicePlatform.IOS },
      ),
    ).rejects.toThrow('valid device token');
    expect(transaction).not.toHaveBeenCalled();
  });

  it('disables the notification test sender in production', async () => {
    const before = process.env.NODE_ENV;
    process.env.NODE_ENV = 'production';
    try {
      await expect(
        createController().controller.sendTestNotification(
          { user: { userId: 'user' } },
          { type: 'EMAIL', message: 'test' },
        ),
      ).rejects.toMatchObject({ status: 404 });
    } finally {
      process.env.NODE_ENV = before;
    }
  });
});
