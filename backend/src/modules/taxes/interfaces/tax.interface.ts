export interface TaxBreakdown {
  nssf: number;
  nhif: number;
  housingLevy: number;
  paye: number;
  totalDeductions: number;
}

export interface PayrollCalculation {
  workerId: string;
  workerName: string;
  grossSalary: number;
  taxBreakdown: TaxBreakdown;
  netPay: number;
}
