export interface TaxBreakdown {
  nssf: number;
  nhif: number;
  housingLevy: number;
  paye: number;
  totalDeductions: number;
  taxablePay?: number;
  taxCharged?: number;
  personalReliefApplied?: number;
  insuranceReliefApplied?: number;
  allowablePensionDeduction?: number;
  allowableMortgageInterest?: number;
  allowablePostRetirementMedicalContribution?: number;
}

export interface PayrollCalculation {
  workerId: string;
  workerName: string;
  grossSalary: number;
  taxBreakdown: TaxBreakdown;
  netPay: number;
}
