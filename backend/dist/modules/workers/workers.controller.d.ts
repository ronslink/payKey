import { WorkersService } from './workers.service';
import { CreateWorkerDto } from './dto/create-worker.dto';
import { CreateTerminationDto } from './dto/termination.dto';
import { TerminationService } from './services/termination.service';
import type { AuthenticatedRequest } from '../../common/interfaces/user.interface';
import type { Response } from 'express';
export declare class WorkersController {
    private readonly workersService;
    private readonly terminationService;
    constructor(workersService: WorkersService, terminationService: TerminationService);
    create(req: AuthenticatedRequest, createWorkerDto: CreateWorkerDto): Promise<import("./entities/worker.entity").Worker>;
    update(req: AuthenticatedRequest, id: string, updateWorkerDto: Partial<CreateWorkerDto>): Promise<import("./entities/worker.entity").Worker>;
    remove(req: AuthenticatedRequest, id: string): Promise<void>;
    findAll(req: AuthenticatedRequest, res: Response): Promise<Response<any, Record<string, any>>>;
    findOne(req: AuthenticatedRequest, id: string): Promise<import("./entities/worker.entity").Worker | null>;
    calculateFinalPayment(req: AuthenticatedRequest, id: string, terminationDate: string): Promise<import("./dto/termination.dto").FinalPaymentCalculationDto>;
    terminateWorker(req: AuthenticatedRequest, id: string, dto: CreateTerminationDto): Promise<import("./entities/termination.entity").Termination>;
    getTerminationHistory(req: AuthenticatedRequest): Promise<import("./entities/termination.entity").Termination[]>;
}
