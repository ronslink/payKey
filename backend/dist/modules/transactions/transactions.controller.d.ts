import { Repository } from 'typeorm';
import { Transaction } from '../payments/entities/transaction.entity';
export declare class TransactionsController {
    private transactionsRepository;
    constructor(transactionsRepository: Repository<Transaction>);
    getTransactions(req: any, page?: number, limit?: number, type?: string): Promise<{
        data: Transaction[];
        pagination: {
            page: number;
            limit: number;
            total: number;
            pages: number;
        };
    }>;
    getTransaction(req: any, id: string): Promise<Transaction | {
        error: string;
    }>;
}
