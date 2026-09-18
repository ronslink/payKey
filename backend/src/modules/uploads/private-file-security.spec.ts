import { INestApplication, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { PassportModule } from '@nestjs/passport';
import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import { sign } from 'jsonwebtoken';
import request from 'supertest';
import { JwtStrategy } from '../auth/jwt.strategy';
import { WorkerDocumentsController } from '../workers/controllers/worker-documents.controller';
import { WorkerDocument } from '../workers/entities/worker-document.entity';
import { Worker } from '../workers/entities/worker.entity';
import { GovSubmission } from '../gov-integrations/entities/gov-submission.entity';
import { GovSubmissionsController } from '../gov-integrations/gov-submissions.controller';
import { KraService } from '../gov-integrations/services/kra.service';
import { NssfService } from '../gov-integrations/services/nssf.service';
import { ShifService } from '../gov-integrations/services/shif.service';
import { registerPublicAvatars } from './public-avatars';
import { resolvePrivateExport, resolvePrivateFile } from './storage-paths';
import { UploadsService } from './uploads.service';
import { ExportService } from '../export/services/export.service';
import { ExportType } from '../export/entities/export.entity';

describe('private file access', () => {
  const workerId = '10000000-0000-4000-8000-000000000001';
  const documentId = '20000000-0000-4000-8000-000000000002';
  const jwtSecret = 'private-file-tests-only-signing-key-123456789';
  let temp: string;
  let app: INestApplication;
  let uploads: UploadsService;
  let document: Record<string, any>;
  let submission: Record<string, any>;
  const previousStorageRoot = process.env.STORAGE_ROOT;
  const previousLegacyRoot = process.env.LEGACY_UPLOADS_DIR;

  const bearer = (user: string) =>
    `Bearer ${sign({ sub: user }, jwtSecret, { expiresIn: '1h' })}`;
  const write = (relative: string, contents: string) => {
    const destination = path.join(temp, relative);
    fs.mkdirSync(path.dirname(destination), { recursive: true });
    fs.writeFileSync(destination, contents);
    return destination;
  };

  beforeAll(async () => {
    temp = fs.mkdtempSync(path.join(os.tmpdir(), 'paykey-private-files-'));
    process.env.STORAGE_ROOT = path.join(temp, 'storage');
    process.env.LEGACY_UPLOADS_DIR = path.join(temp, 'legacy-uploads');
    uploads = new UploadsService();
    document = {
      id: documentId,
      workerId,
      name: 'contract.pdf',
      url: `https://old-api.example/uploads/documents/${workerId}/contract.pdf`,
    };
    submission = {
      id: 'submission-1',
      userId: 'employer-a',
      fileName: 'payroll.xlsx',
      filePath: 'uploads/gov-files/shif/payroll.xlsx',
    };
    write(
      `legacy-uploads/documents/${workerId}/contract.pdf`,
      'private contract',
    );
    write('legacy-uploads/gov-files/shif/payroll.xlsx', 'private payroll');
    write('legacy-uploads/avatars/old-avatar.png', 'old avatar');
    write('storage/public/avatars/new-avatar.png', 'new avatar');

    const module = await Test.createTestingModule({
      imports: [PassportModule],
      controllers: [WorkerDocumentsController, GovSubmissionsController],
      providers: [
        JwtStrategy,
        {
          provide: ConfigService,
          useValue: {
            get: (key: string) => (key === 'JWT_SECRET' ? jwtSecret : 'test'),
          },
        },
        { provide: UploadsService, useValue: uploads },
        {
          provide: getRepositoryToken(WorkerDocument),
          useValue: {
            findOne: jest.fn(({ where }) =>
              Promise.resolve(where.id === documentId ? document : null),
            ),
            find: jest.fn().mockResolvedValue([document]),
          },
        },
        {
          provide: getRepositoryToken(Worker),
          useValue: {
            findOne: jest.fn(({ where }) =>
              Promise.resolve(
                where.id === workerId && where.userId === 'employer-a'
                  ? { id: workerId }
                  : null,
              ),
            ),
          },
        },
        {
          provide: getRepositoryToken(GovSubmission),
          useValue: {
            findOne: jest.fn(({ where }) =>
              Promise.resolve(
                where.id === submission.id && where.userId === submission.userId
                  ? submission
                  : null,
              ),
            ),
          },
        },
        { provide: KraService, useValue: {} },
        { provide: ShifService, useValue: {} },
        { provide: NssfService, useValue: {} },
      ],
    }).compile();
    app = module.createNestApplication();
    registerPublicAvatars(app);
    await app.init();
  });

  afterAll(async () => {
    await app?.close();
    if (previousStorageRoot === undefined) delete process.env.STORAGE_ROOT;
    else process.env.STORAGE_ROOT = previousStorageRoot;
    if (previousLegacyRoot === undefined) delete process.env.LEGACY_UPLOADS_DIR;
    else process.env.LEGACY_UPLOADS_DIR = previousLegacyRoot;
    // Restrict recursive cleanup to this suite's generated temporary directory.
    if (
      temp &&
      path.dirname(temp) === path.resolve(os.tmpdir()) &&
      path.basename(temp).startsWith('paykey-private-files-')
    ) {
      fs.rmSync(temp, { recursive: true, force: true });
    }
  });

  it('serves old and new avatars but never legacy private files', async () => {
    await request(app.getHttpServer())
      .get('/uploads/avatars/old-avatar.png')
      .expect(200);
    await request(app.getHttpServer())
      .get('/uploads/avatars/new-avatar.png')
      .expect(200);
    await request(app.getHttpServer())
      .get(`/uploads/documents/${workerId}/contract.pdf`)
      .expect(404);
    await request(app.getHttpServer())
      .get('/uploads/gov-files/shif/payroll.xlsx')
      .expect(404);
    await request(app.getHttpServer())
      .get('/uploads/avatars/../gov-files/shif/payroll.xlsx')
      .expect(404);
    await request(app.getHttpServer())
      .get('/storage/private/gov-files/shif/payroll.xlsx')
      .expect(404);
  });

  it('requires a valid JWT and employer ownership for worker document downloads', async () => {
    const endpoint = `/workers/documents/${documentId}/download`;
    await request(app.getHttpServer()).get(endpoint).expect(401);
    await request(app.getHttpServer())
      .get(endpoint)
      .set('Authorization', 'Bearer invalid')
      .expect(401);
    await request(app.getHttpServer())
      .get(endpoint)
      .set('Authorization', bearer('employer-b'))
      .expect(404);
    const response = await request(app.getHttpServer())
      .get(endpoint)
      .set('Authorization', bearer('employer-a'))
      .expect(200);
    expect(response.headers['cache-control']).toBe('private, no-store');
    expect(response.headers['content-disposition']).toContain('attachment');
    expect(response.body.toString()).toBe('private contract');
  });

  it('replaces legacy document URLs with guarded download routes in responses', async () => {
    const response = await request(app.getHttpServer())
      .get(`/workers/${workerId}/documents`)
      .set('Authorization', bearer('employer-a'))
      .expect(200);
    expect(response.body[0].url).toBe(
      `/workers/documents/${documentId}/download`,
    );
    expect(document.url).toContain('/uploads/documents/');
  });

  it('keeps government exports restricted to the submission owner', async () => {
    const endpoint = '/gov/submissions/submission-1/download';
    await request(app.getHttpServer()).get(endpoint).expect(401);
    await request(app.getHttpServer())
      .get(endpoint)
      .set('Authorization', bearer('employer-b'))
      .expect(404);
    const response = await request(app.getHttpServer())
      .get(endpoint)
      .set('Authorization', bearer('employer-a'))
      .expect(200);
    expect(response.headers['cache-control']).toBe('private, no-store');
    expect(response.headers['content-length']).toBe(
      String(Buffer.byteLength('private payroll')),
    );
  });

  it('writes new worker documents outside every public root', async () => {
    const reference = await uploads.saveDocument(
      {
        originalname: 'contract.pdf',
        buffer: Buffer.from('new private contract'),
      } as Express.Multer.File,
      workerId,
    );
    expect(reference).toMatch(new RegExp(`^private/documents/${workerId}/`));
    const file = await uploads.resolveDocument(reference, workerId);
    expect(
      file.startsWith(path.join(temp, 'storage', 'private', 'documents')),
    ).toBe(true);
    expect(fs.readFileSync(file, 'utf8')).toBe('new private contract');
    await request(app.getHttpServer()).get(`/${reference}`).expect(404);
    await uploads.deleteDocument(reference, workerId);
    expect(fs.existsSync(file)).toBe(false);
  });

  it('does not preserve active filename extensions on public avatars', async () => {
    const url = await uploads.saveAvatar({
      originalname: 'payload.html',
      mimetype: 'image/png',
      buffer: Buffer.from('image'),
    } as Express.Multer.File);
    expect(url).toMatch(/\.png$/);
    const response = await request(app.getHttpServer())
      .get(new URL(url).pathname)
      .expect(200);
    expect(response.headers['content-type']).toContain('image/png');
    expect(response.headers['x-content-type-options']).toBe('nosniff');
  });

  it.each([
    'private/documents/../../secret',
    `uploads/documents/${workerId}/..%2f..%2fsecret`,
    `https://old-api.example/uploads/documents/${workerId}/%2e%2e%5csecret`,
    'private/documents/other-worker/contract.pdf',
    'private/gov-files/shif/payroll.xlsx',
    '/etc/passwd',
  ])('rejects invalid document reference %s', async (reference) => {
    await expect(
      uploads.resolveDocument(reference, workerId),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('rejects legacy directory symlinks outside the private document root', async () => {
    const outside = path.join(temp, 'outside');
    fs.mkdirSync(outside);
    fs.writeFileSync(path.join(outside, 'secret.pdf'), 'secret');
    const linkedWorker = '30000000-0000-4000-8000-000000000003';
    fs.symlinkSync(
      outside,
      path.join(temp, 'legacy-uploads', 'documents', linkedWorker),
      'junction',
    );
    await expect(
      uploads.resolveDocument(
        `uploads/documents/${linkedWorker}/secret.pdf`,
        linkedWorker,
      ),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('reads a legacy government reference after copying files into private storage', async () => {
    const destination = write(
      'storage/private/gov-files/kra/existing.xlsx',
      'migrated',
    );
    await expect(
      resolvePrivateFile('uploads/gov-files/kra/existing.xlsx', 'gov-files'),
    ).resolves.toBe(destination);
    await expect(
      resolvePrivateFile(
        path.join(process.cwd(), 'uploads/gov-files/kra/existing.xlsx'),
        'gov-files',
      ),
    ).resolves.toBe(destination);
    await expect(
      resolvePrivateFile(path.join(temp, 'outside/secret.pdf'), 'gov-files'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('scopes every government export query to the requesting employer', async () => {
    const records = { find: jest.fn().mockResolvedValue([]) };
    for (const Service of [ShifService, NssfService]) {
      const service = new Service(records as any, {} as any);
      const generate =
        service instanceof ShifService
          ? service.generateContributionFile.bind(service)
          : service.generateSF24.bind(service);
      await expect(
        generate('another-employers-period', 'employer-a'),
      ).rejects.toThrow('No payroll records');
      expect(records.find).toHaveBeenLastCalledWith({
        where: {
          payPeriodId: 'another-employers-period',
          userId: 'employer-a',
        },
        relations: ['worker'],
      });
    }
    const query = {
      leftJoinAndSelect: jest.fn().mockReturnThis(),
      where: jest.fn().mockReturnThis(),
      andWhere: jest.fn().mockReturnThis(),
      getMany: jest.fn().mockResolvedValue([]),
    };
    const kra = new KraService(
      { createQueryBuilder: () => query } as any,
      {} as any,
    );
    const log = jest.spyOn(console, 'error').mockImplementation(() => {});
    try {
      await expect(
        kra.generateP10Excel('another-employers-period', 'employer-a'),
      ).rejects.toThrow('No payroll records');
      expect(query.andWhere).toHaveBeenCalledWith('pr.userId = :userId', {
        userId: 'employer-a',
      });
    } finally {
      log.mockRestore();
    }
  });

  it('writes government exports privately without overwriting previous submissions', async () => {
    const records = {
      find: jest.fn().mockResolvedValue([
        {
          grossSalary: 10000,
          taxBreakdown: { shif: 275 },
          worker: { name: 'Employee' },
        },
      ]),
    };
    const submissions = {
      create: jest.fn((value) => value),
      save: jest.fn().mockImplementation((value) => Promise.resolve(value)),
    };
    const shif = new ShifService(records as any, submissions as any);
    const first = await shif.generateContributionFile('period-1', 'employer-a');
    const second = await shif.generateContributionFile(
      'period-1',
      'employer-a',
    );
    expect(first.filePath).toMatch(
      /^private\/gov-files\/shif\/[a-f0-9-]+\.xlsx$/,
    );
    expect(first.filePath).not.toBe(second.filePath);
    const resolved = await resolvePrivateFile(first.filePath, 'gov-files');
    expect(fs.statSync(resolved).size).toBeGreaterThan(0);
    await request(app.getHttpServer()).get(`/${first.filePath}`).expect(404);
  });

  it('writes accounting exports to persistent private storage and checks ownership before reading', async () => {
    const repository = {
      create: jest.fn((value) => value),
      save: jest.fn((value) => Promise.resolve({ ...value, id: 'export-1' })),
      findOne: jest.fn(),
    };
    const service = new ExportService(repository as any, {} as any, {} as any);
    jest
      .spyOn(service, 'generateGenericCSV')
      .mockResolvedValue('employee,pay\nEmployee,1000\n');
    const record = await service.createExport(
      'employer-a',
      ExportType.GENERIC_CSV,
      new Date('2026-09-01'),
      new Date('2026-09-30'),
    );
    expect(record.filePath).toMatch(/^private\/exports\/[a-f0-9-]+\.csv$/);
    const file = await resolvePrivateExport(record.filePath);
    expect(
      file.startsWith(path.join(temp, 'storage', 'private', 'exports')),
    ).toBe(true);
    repository.findOne
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce(record);
    await expect(
      service.getExportFile('export-1', 'employer-b'),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(repository.findOne).toHaveBeenLastCalledWith({
      where: { id: 'export-1', userId: 'employer-b' },
    });
    await expect(
      service.getExportFile('export-1', 'employer-a'),
    ).resolves.toEqual(Buffer.from('employee,pay\nEmployee,1000\n'));
    await request(app.getHttpServer()).get(`/${record.filePath}`).expect(404);
    await request(app.getHttpServer()).get('/exports/payroll.csv').expect(404);
  });

  it('resolves preserved legacy accounting exports without retaining an ephemeral container path', async () => {
    const destination = write(
      'legacy-uploads/exports/payroll.csv',
      'legacy payroll',
    );
    for (const reference of [
      path.join(process.cwd(), 'exports', 'payroll.csv'),
      path.join(temp, 'legacy-uploads', 'exports', 'payroll.csv'),
      'exports/payroll.csv',
    ]) {
      await expect(resolvePrivateExport(reference)).resolves.toBe(destination);
    }
  });

  it.each([
    'exports/../outside/secret.csv',
    'private/exports/../../secret.csv',
    '/etc/passwd',
    'exports/%2e%2e%2fsecret.csv',
  ])('rejects unsafe accounting export reference %s', async (reference) => {
    await expect(resolvePrivateExport(reference)).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });
});
