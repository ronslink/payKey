import { ConfigService } from '@nestjs/config';
import { HttpService } from '@nestjs/axios';
import { Repository } from 'typeorm';
import { Transaction } from './entities/transaction.entity';
export declare class MpesaService {
    private configService;
    private httpService;
    private transactionsRepository;
    private readonly logger;
    private readonly baseUrl;
    constructor(configService: ConfigService, httpService: HttpService, transactionsRepository: Repository<Transaction>);
    getAccessToken(): Promise<string>;
    initiateStkPush(userId: string, phoneNumber: string, amount: number): Promise<any>;
    sendB2C(transactionId: string, phoneNumber: string, amount: number, remarks: string): Promise<any>;
}
