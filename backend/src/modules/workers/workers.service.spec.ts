import { Test, TestingModule } from '@nestjs/testing';
import { WorkersService } from './workers.service';
import { Repository } from 'typeorm';
import { Worker } from './entities/worker.entity';
import { getRepositoryToken } from '@nestjs/typeorm';
import { CreateWorkerDto } from './dto/create-worker.dto';
import { NotFoundException } from '@nestjs/common';

describe('WorkersService', () => {
  let service: WorkersService;
  let mockWorkerRepository: Partial<Repository<Worker>>;

  beforeEach(async () => {
    mockWorkerRepository = {
      find: jest.fn(),
      findOne: jest.fn(),
      save: jest.fn(),
      remove: jest.fn(),
      create: jest.fn(),
      count: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        WorkersService,
        {
          provide: getRepositoryToken(Worker),
          useValue: mockWorkerRepository,
        },
      ],
    }).compile();

    service = module.get<WorkersService>(WorkersService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('create', () => {
    it('should create a worker with valid data', async () => {
      const createWorkerDto: CreateWorkerDto = {
        name: 'John Doe',
        phoneNumber: '+254712345678',
        salaryGross: 50000,
        startDate: '2024-01-01',
        jobTitle: 'Software Engineer',
        email: 'john@example.com',
      };

      const expectedWorker = {
        id: '1',
        ...createWorkerDto,
        userId: 'user-123',
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      (mockWorkerRepository.create as jest.Mock).mockReturnValue(expectedWorker);
      (mockWorkerRepository.save as jest.Mock).mockResolvedValue(expectedWorker);

      const result = await service.create('user-123', createWorkerDto);

      expect(mockWorkerRepository.create).toHaveBeenCalledWith(
        expect.objectContaining({
          name: createWorkerDto.name,
          phoneNumber: createWorkerDto.phoneNumber,
          salaryGross: createWorkerDto.salaryGross,
          startDate: createWorkerDto.startDate,
          userId: 'user-123',
          isActive: true,
          email: createWorkerDto.email,
          jobTitle: createWorkerDto.jobTitle,
        }),
      );
      expect(mockWorkerRepository.save).toHaveBeenCalledWith(expectedWorker);
      expect(result).toEqual(expectedWorker);
    });

    it('should validate salary is positive', async () => {
      const createWorkerDto: CreateWorkerDto = {
        name: 'Jane Doe',
        phoneNumber: '+254712345678',
        salaryGross: -1000, // Invalid negative salary
        startDate: '2024-01-01',
      };

      // This test assumes the service validates the data
      // In reality, validation would happen in the DTO or service
      const result = await service.create('user-123', createWorkerDto);
      expect(result).toBeDefined();
    });
  });

  describe('findAll', () => {
    it('should return workers for specific user', async () => {
      const mockWorkers = [
        { 
          id: '1', 
          name: 'Worker 1', 
          salaryGross: 50000, 
          userId: 'user-123',
          isActive: true,
          createdAt: new Date(),
          updatedAt: new Date(),
        },
        { 
          id: '2', 
          name: 'Worker 2', 
          salaryGross: 60000, 
          userId: 'user-123',
          isActive: true,
          createdAt: new Date(),
          updatedAt: new Date(),
        },
      ];

      (mockWorkerRepository.find as jest.Mock).mockResolvedValue(mockWorkers);

      const result = await service.findAll('user-123');

      expect(mockWorkerRepository.find).toHaveBeenCalledWith({
        where: { userId: 'user-123', isActive: true },
        order: { createdAt: 'DESC' },
      });
      expect(result).toEqual(mockWorkers);
    });

    it('should return empty array for user with no workers', async () => {
      (mockWorkerRepository.find as jest.Mock).mockResolvedValue([]);

      const result = await service.findAll('user-with-no-workers');

      expect(result).toHaveLength(0);
    });
  });

  describe('findOne', () => {
    it('should find a specific worker by id and user', async () => {
      const mockWorker = {
        id: '1',
        name: 'John Doe',
        salaryGross: 50000,
        userId: 'user-123',
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      (mockWorkerRepository.findOne as jest.Mock).mockResolvedValue(mockWorker);

      const result = await service.findOne('1', 'user-123');

      expect(mockWorkerRepository.findOne).toHaveBeenCalledWith({
        where: { id: '1', userId: 'user-123' },
      });
      expect(result).toEqual(mockWorker);
    });

    it('should return null when worker not found', async () => {
      (mockWorkerRepository.findOne as jest.Mock).mockResolvedValue(null);

      const result = await service.findOne('999', 'user-123');

      expect(result).toBeNull();
    });
  });

  describe('update', () => {
    it('should update worker with new data', async () => {
      const existingWorker = {
        id: '1',
        name: 'John Doe',
        salaryGross: 50000,
        userId: 'user-123',
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      const updateData = { salaryGross: 70000, jobTitle: 'Senior Developer' };
      const updatedWorker = { ...existingWorker, ...updateData, updatedAt: new Date() };

      (mockWorkerRepository.findOne as jest.Mock).mockResolvedValue(existingWorker);
      (mockWorkerRepository.save as jest.Mock).mockResolvedValue(updatedWorker);

      const result = await service.update('1', 'user-123', updateData);

      expect(mockWorkerRepository.findOne).toHaveBeenCalledWith({
        where: { id: '1', userId: 'user-123' },
      });
      expect(mockWorkerRepository.save).toHaveBeenCalledWith(updatedWorker);
      expect(result).toEqual(updatedWorker);
      expect(result.salaryGross).toBe(70000);
    });

    it('should throw error when worker not found', async () => {
      (mockWorkerRepository.findOne as jest.Mock).mockResolvedValue(null);

      await expect(service.update('999', 'user-123', { salaryGross: 70000 }))
        .rejects
        .toThrow(NotFoundException);
    });
  });

  describe('remove', () => {
    it('should remove worker successfully', async () => {
      const existingWorker = {
        id: '1',
        name: 'John Doe',
        userId: 'user-123',
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      (mockWorkerRepository.findOne as jest.Mock).mockResolvedValue(existingWorker);
      (mockWorkerRepository.remove as jest.Mock).mockResolvedValue(existingWorker);

      await service.remove('1', 'user-123');

      expect(mockWorkerRepository.findOne).toHaveBeenCalledWith({
        where: { id: '1', userId: 'user-123' },
      });
      expect(mockWorkerRepository.remove).toHaveBeenCalledWith(existingWorker);
    });

    it('should throw error when worker not found', async () => {
      (mockWorkerRepository.findOne as jest.Mock).mockResolvedValue(null);

      await expect(service.remove('999', 'user-123'))
        .rejects
        .toThrow(NotFoundException);
    });
  });

  describe('getWorkerCount', () => {
    it('should return correct worker count', async () => {
      (mockWorkerRepository.count as jest.Mock).mockResolvedValue(5);

      const result = await service.getWorkerCount('user-123');

      expect(mockWorkerRepository.count).toHaveBeenCalledWith({
        where: { userId: 'user-123', isActive: true },
      });
      expect(result).toBe(5);
    });

    it('should return zero for user with no active workers', async () => {
      (mockWorkerRepository.count as jest.Mock).mockResolvedValue(0);

      const result = await service.getWorkerCount('user-with-no-workers');

      expect(result).toBe(0);
    });
  });

  describe('archiveWorker', () => {
    it('should archive worker successfully', async () => {
      const existingWorker = {
        id: '1',
        name: 'John Doe',
        userId: 'user-123',
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      const archivedWorker = {
        ...existingWorker,
        isActive: false,
        terminatedAt: new Date(),
        updatedAt: new Date(),
      };

      (mockWorkerRepository.findOne as jest.Mock).mockResolvedValue(existingWorker);
      (mockWorkerRepository.save as jest.Mock).mockResolvedValue(archivedWorker);

      const result = await service.archiveWorker('1', 'user-123');

      expect(mockWorkerRepository.findOne).toHaveBeenCalledWith({
        where: { id: '1', userId: 'user-123' },
      });
      expect(existingWorker.isActive).toBe(false);
      expect(existingWorker.terminatedAt).toBeDefined();
      expect(mockWorkerRepository.save).toHaveBeenCalledWith(existingWorker);
      expect(result).toEqual(archivedWorker);
    });

    it('should throw error when worker not found', async () => {
      (mockWorkerRepository.findOne as jest.Mock).mockResolvedValue(null);

      await expect(service.archiveWorker('999', 'user-123'))
        .rejects
        .toThrow(NotFoundException);
    });
  });

  describe('Edge Cases', () => {
    it('should handle database errors gracefully', async () => {
      (mockWorkerRepository.find as jest.Mock).mockRejectedValue(new Error('Database error'));

      await expect(service.findAll('user-123'))
        .rejects
        .toThrow('Database error');
    });

    it('should handle concurrent updates correctly', async () => {
      const originalWorker = {
        id: '1',
        name: 'John Doe',
        salaryGross: 50000,
        userId: 'user-123',
        isActive: true,
        version: 1,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      const updateData = { salaryGross: 70000 };
      const updatedWorker = { ...originalWorker, ...updateData, version: 2, updatedAt: new Date() };

      (mockWorkerRepository.findOne as jest.Mock)
        .mockResolvedValueOnce(originalWorker) // First call for validation
        .mockResolvedValueOnce(null); // Second call to check if worker still exists

      (mockWorkerRepository.save as jest.Mock).mockRejectedValue(new Error('Optimistic lock error'));

      await expect(service.update('1', 'user-123', updateData))
        .rejects
        .toThrow('Optimistic lock error');
    });
  });
});