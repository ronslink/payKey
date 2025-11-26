import { Repository } from 'typeorm';
import { Worker } from '../entities/worker.entity';
import { Termination } from '../entities/termination.entity';
import { TaxesService } from '../../taxes/taxes.service';
import { CreateTerminationDto, FinalPaymentCalculationDto } from '../dto/termination.dto';
export declare class TerminationService {
    private workerRepository;
    private terminationRepository;
    private taxesService;
    constructor(workerRepository: Repository<Worker>, terminationRepository: Repository<Termination>, taxesService: TaxesService);
    calculateFinalPayment(workerId: string, userId: string, terminationDate: Date): Promise<FinalPaymentCalculationDto>;
    terminateWorker(workerId: string, userId: string, dto: CreateTerminationDto): Promise<Termination>;
    getTerminationHistory(userId: string): Promise<Termination[]>;
    getTermination(id: string, userId: string): Promise<Termination>;
}
