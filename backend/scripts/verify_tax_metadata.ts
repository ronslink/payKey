
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { PayrollPaymentService } from '../src/modules/payments/payroll-payment.service';
import { PayrollRecord, PayrollStatus } from '../src/modules/payroll/entities/payroll-record.entity';
import { Transaction } from '../src/modules/payments/entities/transaction.entity';
import { Repository } from 'typeorm';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Worker } from '../src/modules/workers/entities/worker.entity';
import { MpesaService } from '../src/modules/payments/mpesa.service';

// Mock MpesaService to avoid real calls
const mockMpesaService = {
    sendB2C: async () => ({
        success: true,
        transactionId: 'MOCK_TRX_' + Date.now(),
    }),
};

async function bootstrap() {
    const app = await NestFactory.createApplicationContext(AppModule);

    // Override MpesaService with mock
    // In a real e2e test we'd use Test.createTestingModule, but here we just want to access the real DB.
    // Ideally, we shouldn't send real B2C. 
    // We can spy on the real service or just trust that we set credentials to safe values or use the mock.
    // Since we can't easily swap the provider in a compiled AppContext without TestingModule, 
    // we will manually instantiate the service or use reliance on the fact that we might not have credits/live creds.
    // BUT: PayrollPaymentService uses DI.

    // Safer approach: Check if we can use the TestingModule to swap MpesaService.
    // But for this environment, let's just inspect the Code I wrote.
    // Actually, I can use a script that manually fetches the repo and service.

    const payrollPaymentService = app.get(PayrollPaymentService);
    // We need to swap the mpesaService inside it if possible, or ensure it doesn't actually send money.
    // The user's env has sandbox creds.
    // To avoid noise, let's monkey patch the mpesaService instance.
    (payrollPaymentService as any).mpesaService = mockMpesaService;

    const payrollRepo = app.get<Repository<PayrollRecord>>(getRepositoryToken(PayrollRecord));
    const transactionRepo = app.get<Repository<Transaction>>(getRepositoryToken(Transaction));

    console.log('--- Starting Tax Metadata Verification ---');

    // 1. Create a Fake Payroll Record (In-Memory or DB?)
    // We need to save it to DB because processPayouts reloads or updates it.
    // But processPayouts takes an array of entities.

    const mockRecord = new PayrollRecord();
    mockRecord.id = 'test-record-' + Date.now();
    mockRecord.userId = 'test-user-id';
    mockRecord.workerId = 'test-worker-id';
    mockRecord.netSalary = 5000;
    mockRecord.grossSalary = 6000;
    mockRecord.status = PayrollStatus.FINALIZED;
    mockRecord.paymentStatus = 'pending';
    mockRecord.taxBreakdown = {
        paye: 1000,
        nssf: 200,
        nhif: 150,
        housingLevy: 100,
        totalDeductions: 1450
    };
    mockRecord.worker = {
        name: 'Test Worker',
        phoneNumber: '254700000000',
        paymentMethod: 'MPESA'
    } as unknown as Worker;

    // We need to mock the repositories for the service call OR use real DB.
    // Using real DB is better but polluting.
    // Let's rely on unit testing style by creating a new service instance with mocks.

    const mockPayrollRepo = {
        save: async (entity: any) => entity,
    } as any;

    const mockTransactionRepo = {
        create: (entity: any) => {
            // This is what we want to verify!
            console.log('Transaction Created with Metadata:', entity.metadata);

            if (!entity.metadata.taxBreakdown) {
                console.error('FAILED: taxBreakdown missing in transaction metadata');
                process.exit(1);
            }
            if (entity.metadata.grossSalary !== 6000) {
                console.error('FAILED: grossSalary missing or incorrect');
                process.exit(1);
            }

            return { ...entity, id: 'mock-trx-id' };
        },
        save: async (entity: any) => entity,
    } as any;

    const testService = new PayrollPaymentService(
        mockTransactionRepo,
        mockMpesaService as any,
        mockPayrollRepo
    );

    await testService.processPayouts([mockRecord]);

    console.log('SUCCESS: Tax Metadata verified in transaction creation.');
    await app.close();
}

bootstrap();
