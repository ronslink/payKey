import { TaxesService } from './taxes.service';
export declare class TaxSubmissionController {
    private readonly taxesService;
    constructor(taxesService: TaxesService);
    getSubmissions(req: any): Promise<import("./entities/tax-submission.entity").TaxSubmission[]>;
    markAsFiled(req: any, id: string): Promise<import("./entities/tax-submission.entity").TaxSubmission>;
    generateSubmission(req: any, body: {
        payPeriodId: string;
    }): Promise<import("./entities/tax-submission.entity").TaxSubmission>;
}
