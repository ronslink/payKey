import { MODULE_METADATA } from '@nestjs/common/constants';
import { TestingController } from './testing.controller';
import { TestingService } from './testing.service';

describe('Destructive testing routes', () => {
  const originalEnvironment = process.env.NODE_ENV;

  afterEach(() => {
    if (originalEnvironment === undefined) delete process.env.NODE_ENV;
    else process.env.NODE_ENV = originalEnvironment;
  });

  it.each([
    ['production', false],
    ['development', false],
    [undefined, false],
    ['test', true],
  ] as const)(
    'only registers TestingModule for the explicit test environment (%s)',
    (environment, shouldRegister) => {
      if (environment === undefined) delete process.env.NODE_ENV;
      else process.env.NODE_ENV = environment;

      jest.isolateModules(() => {
        // Inspect Nest's module metadata without loading environment files,
        // bootstrapping a server, connecting to data stores or running seeds.
        const { ConfigModule } = jest.requireActual('@nestjs/config');
        const configSpy = jest
          .spyOn(ConfigModule, 'forRoot')
          .mockReturnValue({ module: ConfigModule });
        try {
          const { AppModule } = jest.requireActual('../../app.module');
          const { TestingModule } = jest.requireActual('./testing.module');
          expect(
            Reflect.getMetadata(MODULE_METADATA.IMPORTS, AppModule).includes(
              TestingModule,
            ),
          ).toBe(shouldRegister);
        } finally {
          configSpy.mockRestore();
        }
      });
    },
  );

  it('keeps the reset helper available to explicit test runs', async () => {
    process.env.NODE_ENV = 'test';
    const reset = jest.fn().mockResolvedValue({ message: 'reset' });
    const controller = new TestingController({
      resetPayrollForUser: reset,
    } as unknown as TestingService);
    await expect(
      controller.resetPayroll({ email: 'test@example.invalid' }),
    ).resolves.toEqual({ message: 'reset' });
    expect(reset).toHaveBeenCalledWith('test@example.invalid');
  });

  it('refuses deletion outside tests even if the controller was accidentally registered', async () => {
    process.env.NODE_ENV = 'production';
    const reset = jest.fn();
    const controller = new TestingController({
      resetPayrollForUser: reset,
    } as unknown as TestingService);
    await expect(
      controller.resetPayroll({ email: 'test@example.invalid' }),
    ).rejects.toMatchObject({ status: 404 });
    expect(reset).not.toHaveBeenCalled();
  });
});
