import { Injectable } from '@nestjs/common';

/**
 * Service for generating realistic mock data during trial period
 * for features the user doesn't have full access to.
 */
@Injectable()
export class MockDataService {
  /**
   * Generate mock payroll report data
   */
  generatePayrollReport(monthsBack: number = 4): MockPayrollReport {
    const months = this.getLastNMonths(monthsBack);
    const workers = this.generateMockWorkers(5);

    return {
      isMock: true,
      mockNotice:
        'This is sample data to demonstrate the Reports feature. Upgrade to see your actual reports.',
      data: {
        summary: {
          totalGrossPay: 485000,
          totalNetPay: 412250,
          totalDeductions: 72750,
          workerCount: 5,
          avgSalary: 97000,
        },
        monthlyTrend: months.map((month, index) => ({
          month,
          grossPay: 450000 + index * 10000 + Math.floor(Math.random() * 10000),
          netPay: 382500 + index * 8500 + Math.floor(Math.random() * 8500),
          deductions: 67500 + index * 1500 + Math.floor(Math.random() * 1500),
        })),
        workerBreakdown: workers.map((worker) => ({
          worker,
          grossPay: worker.baseSalary,
          netPay: Math.round(worker.baseSalary * 0.85),
          paye: Math.round(worker.baseSalary * 0.1),
          nssf: Math.min(1080, Math.round(worker.baseSalary * 0.06)),
          nhif: this.calculateNhif(worker.baseSalary),
        })),
        paymentsByMethod: [
          { method: 'M-Pesa', count: 4, total: 329800 },
          { method: 'Bank Transfer', count: 1, total: 82450 },
        ],
      },
    };
  }

  /**
   * Generate mock time tracking data
   */
  generateTimeTrackingData(): MockTimeTrackingData {
    const workers = this.generateMockWorkers(5);
    const today = new Date();

    return {
      isMock: true,
      mockNotice:
        'This is sample data to demonstrate Time Tracking. Upgrade to Gold to track real attendance.',
      data: {
        weeklyOverview: {
          totalHours: 184,
          overtime: 12,
          attendanceRate: 95.2,
          totalWorkers: 5,
          presentToday: 4,
        },
        dailyEntries: workers.map((worker) => ({
          worker,
          date: today.toISOString().split('T')[0],
          checkIn: this.randomTime(7, 9),
          checkOut: this.randomTime(16, 18),
          hoursWorked: 8 + Math.random() * 2,
          status: Math.random() > 0.1 ? 'present' : 'absent',
          location: this.randomLocation(),
        })),
        weeklyByWorker: workers.map((worker) => ({
          worker,
          monday: 8.5,
          tuesday: 9.0,
          wednesday: 8.25,
          thursday: 8.75,
          friday: 8.0,
          total: 42.5,
          overtime: 2.5,
        })),
      },
    };
  }

  /**
   * Generate mock leave management data
   */
  generateLeaveData(): MockLeaveData {
    const workers = this.generateMockWorkers(5);

    return {
      isMock: true,
      mockNotice:
        'This is sample data to demonstrate Leave Management. Upgrade to Basic to manage real leave requests.',
      data: {
        balanceSummary: workers.map((worker) => ({
          worker,
          annual: { entitled: 21, taken: 5, remaining: 16 },
          sick: { entitled: 10, taken: 2, remaining: 8 },
          maternity: { entitled: 90, taken: 0, remaining: 90 },
        })),
        upcomingLeave: [
          {
            worker: workers[0],
            type: 'Annual',
            startDate: this.futureDate(5),
            endDate: this.futureDate(9),
            days: 5,
            status: 'approved',
          },
          {
            worker: workers[2],
            type: 'Sick',
            startDate: this.futureDate(2),
            endDate: this.futureDate(3),
            days: 2,
            status: 'pending',
          },
        ],
        leaveHistory: [
          {
            worker: workers[1],
            type: 'Annual',
            startDate: this.pastDate(30),
            endDate: this.pastDate(26),
            days: 5,
            status: 'completed',
          },
          {
            worker: workers[3],
            type: 'Sick',
            startDate: this.pastDate(45),
            endDate: this.pastDate(44),
            days: 2,
            status: 'completed',
          },
        ],
      },
    };
  }

  /**
   * Generate mock multi-property data
   */
  generateMultiPropertyData(): MockPropertyData {
    return {
      isMock: true,
      mockNotice:
        'This is sample data to demonstrate Multi-Property Management. Upgrade to Platinum to manage multiple properties.',
      data: {
        properties: [
          {
            id: 'prop-1',
            name: 'Kilimani Residence',
            type: 'Residential',
            workerCount: 3,
            monthlyPayroll: 125000,
            address: 'Kilimani, Nairobi',
          },
          {
            id: 'prop-2',
            name: 'Westlands Office',
            type: 'Commercial',
            workerCount: 5,
            monthlyPayroll: 285000,
            address: 'Westlands, Nairobi',
          },
          {
            id: 'prop-3',
            name: 'Karen Villa',
            type: 'Residential',
            workerCount: 2,
            monthlyPayroll: 95000,
            address: 'Karen, Nairobi',
          },
        ],
        consolidatedSummary: {
          totalProperties: 3,
          totalWorkers: 10,
          totalMonthlyPayroll: 505000,
          avgPayrollPerProperty: 168333,
        },
        propertyComparison: [
          {
            property: 'Kilimani Residence',
            jan: 120000,
            feb: 122000,
            mar: 125000,
          },
          {
            property: 'Westlands Office',
            jan: 275000,
            feb: 280000,
            mar: 285000,
          },
          { property: 'Karen Villa', jan: 92000, feb: 93000, mar: 95000 },
        ],
      },
    };
  }

  /**
   * Generate mock accounting integration data
   */
  generateAccountingData(): MockAccountingData {
    return {
      isMock: true,
      mockNotice:
        'This is sample data to demonstrate Accounting Integration. Upgrade to Platinum to sync with your accounting software.',
      data: {
        journalEntries: [
          {
            date: this.pastDate(1),
            description: 'Payroll - November 2024',
            debit: { account: 'Salaries Expense', amount: 485000 },
            credit: { account: 'Payroll Payable', amount: 485000 },
          },
          {
            date: this.pastDate(1),
            description: 'PAYE Deduction',
            debit: { account: 'Payroll Payable', amount: 48500 },
            credit: { account: 'PAYE Payable', amount: 48500 },
          },
          {
            date: this.pastDate(1),
            description: 'NSSF Contribution',
            debit: { account: 'NSSF Expense', amount: 10800 },
            credit: { account: 'NSSF Payable', amount: 10800 },
          },
        ],
        syncStatus: {
          lastSync: this.pastDate(1),
          status: 'success',
          recordsSynced: 15,
          pendingRecords: 0,
        },
        connectedApps: [
          {
            name: 'QuickBooks',
            status: 'connected',
            lastSync: this.pastDate(1),
          },
          { name: 'Xero', status: 'not_connected', lastSync: null },
        ],
      },
    };
  }

  /**
   * Generate mock P9 tax card data
   */
  generateP9Data(year: number = new Date().getFullYear()): MockP9Data {
    const workers = this.generateMockWorkers(3);

    return {
      isMock: true,
      mockNotice:
        'This is sample P9 data. Upgrade to Basic to generate real P9 tax cards for your workers.',
      data: {
        year,
        workers: workers.map((worker) => ({
          worker,
          taxPin: `A${Math.random().toString().slice(2, 11)}X`,
          monthlyBreakdown: Array.from({ length: 12 }, (_, i) => ({
            month: i + 1,
            grossPay: worker.baseSalary,
            taxableIncome: Math.round(worker.baseSalary * 0.9),
            paye: Math.round(worker.baseSalary * 0.1),
            relief: 2400,
            netTax: Math.round(worker.baseSalary * 0.1) - 2400,
          })),
          annualTotals: {
            grossPay: worker.baseSalary * 12,
            taxableIncome: Math.round(worker.baseSalary * 0.9) * 12,
            totalPaye: Math.round(worker.baseSalary * 0.1) * 12,
            totalRelief: 2400 * 12,
            netTax: (Math.round(worker.baseSalary * 0.1) - 2400) * 12,
          },
        })),
      },
    };
  }

  /**
   * Generate mock advanced reports
   */
  generateAdvancedReports(): MockAdvancedReports {
    return {
      isMock: true,
      mockNotice:
        'This is sample analytics data. Upgrade to Gold for real advanced reporting.',
      data: {
        payrollTrends: {
          sixMonthGrowth: 12.5,
          avgMonthlyPayroll: 485000,
          projectedNextMonth: 510000,
          seasonalPatterns: [
            { month: 'Jan', deviation: -5 },
            { month: 'Dec', deviation: +15 }, // Bonuses
          ],
        },
        workerInsights: {
          avgTenure: 18, // months
          turnoverRate: 8.5, // percent
          costPerWorker: 97000,
          highestPaid: 'Senior Cook',
          lowestPaid: 'Gardener',
        },
        taxCompliance: {
          currentYearPaye: 582000,
          currentYearNssf: 129600,
          currentYearNhif: 36000,
          filingStatus: 'up_to_date',
          nextDeadline: this.futureDate(15),
        },
        customReports: [
          {
            name: 'Monthly Payroll Summary',
            format: 'PDF',
            generated: this.pastDate(5),
          },
          {
            name: 'Annual Tax Report',
            format: 'Excel',
            generated: this.pastDate(30),
          },
          {
            name: 'Worker Cost Analysis',
            format: 'PDF',
            generated: this.pastDate(15),
          },
        ],
      },
    };
  }

  // ==================== Helper Methods ====================

  private generateMockWorkers(count: number): MockWorker[] {
    const names = [
      { name: 'John Kamau', role: 'House Manager', salary: 85000 },
      { name: 'Mary Wanjiku', role: 'Cook', salary: 65000 },
      { name: 'Peter Otieno', role: 'Driver', salary: 55000 },
      { name: 'Grace Akinyi', role: 'Housekeeper', salary: 45000 },
      { name: 'James Mwangi', role: 'Gardener', salary: 35000 },
      { name: 'Jane Njeri', role: 'Nanny', salary: 50000 },
      { name: 'David Kiprop', role: 'Security', salary: 40000 },
    ];

    return names.slice(0, count).map((n, i) => ({
      id: `worker-${i + 1}`,
      name: n.name,
      role: n.role,
      baseSalary: n.salary,
    }));
  }

  private getLastNMonths(n: number): string[] {
    const months = [];
    const date = new Date();
    for (let i = 0; i < n; i++) {
      months.unshift(
        date.toLocaleDateString('en-US', { month: 'short', year: 'numeric' }),
      );
      date.setMonth(date.getMonth() - 1);
    }
    return months;
  }

  private calculateNhif(grossSalary: number): number {
    if (grossSalary <= 5999) return 150;
    if (grossSalary <= 7999) return 300;
    if (grossSalary <= 11999) return 400;
    if (grossSalary <= 14999) return 500;
    if (grossSalary <= 19999) return 600;
    if (grossSalary <= 24999) return 750;
    if (grossSalary <= 29999) return 850;
    if (grossSalary <= 34999) return 900;
    if (grossSalary <= 39999) return 950;
    if (grossSalary <= 44999) return 1000;
    if (grossSalary <= 49999) return 1100;
    if (grossSalary <= 59999) return 1200;
    if (grossSalary <= 69999) return 1300;
    if (grossSalary <= 79999) return 1400;
    if (grossSalary <= 89999) return 1500;
    if (grossSalary <= 99999) return 1600;
    return 1700;
  }

  private randomTime(hourStart: number, hourEnd: number): string {
    const hour = hourStart + Math.floor(Math.random() * (hourEnd - hourStart));
    const minute = Math.floor(Math.random() * 60);
    return `${hour.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')}`;
  }

  private randomLocation(): string {
    const locations = [
      'Main Entrance',
      'Kitchen',
      'Garden',
      'Office',
      'Garage',
    ];
    return locations[Math.floor(Math.random() * locations.length)];
  }

  private futureDate(daysAhead: number): string {
    const date = new Date();
    date.setDate(date.getDate() + daysAhead);
    return date.toISOString().split('T')[0];
  }

  private pastDate(daysAgo: number): string {
    const date = new Date();
    date.setDate(date.getDate() - daysAgo);
    return date.toISOString().split('T')[0];
  }
}

// ==================== Type Definitions ====================

export interface MockWorker {
  id: string;
  name: string;
  role: string;
  baseSalary: number;
}

export interface MockPayrollReport {
  isMock: boolean;
  mockNotice: string;
  data: {
    summary: {
      totalGrossPay: number;
      totalNetPay: number;
      totalDeductions: number;
      workerCount: number;
      avgSalary: number;
    };
    monthlyTrend: Array<{
      month: string;
      grossPay: number;
      netPay: number;
      deductions: number;
    }>;
    workerBreakdown: Array<{
      worker: MockWorker;
      grossPay: number;
      netPay: number;
      paye: number;
      nssf: number;
      nhif: number;
    }>;
    paymentsByMethod: Array<{
      method: string;
      count: number;
      total: number;
    }>;
  };
}

export interface MockTimeTrackingData {
  isMock: boolean;
  mockNotice: string;
  data: {
    weeklyOverview: {
      totalHours: number;
      overtime: number;
      attendanceRate: number;
      totalWorkers: number;
      presentToday: number;
    };
    dailyEntries: Array<{
      worker: MockWorker;
      date: string;
      checkIn: string;
      checkOut: string;
      hoursWorked: number;
      status: string;
      location: string;
    }>;
    weeklyByWorker: Array<{
      worker: MockWorker;
      monday: number;
      tuesday: number;
      wednesday: number;
      thursday: number;
      friday: number;
      total: number;
      overtime: number;
    }>;
  };
}

export interface MockLeaveData {
  isMock: boolean;
  mockNotice: string;
  data: {
    balanceSummary: Array<{
      worker: MockWorker;
      annual: { entitled: number; taken: number; remaining: number };
      sick: { entitled: number; taken: number; remaining: number };
      maternity: { entitled: number; taken: number; remaining: number };
    }>;
    upcomingLeave: Array<{
      worker: MockWorker;
      type: string;
      startDate: string;
      endDate: string;
      days: number;
      status: string;
    }>;
    leaveHistory: Array<{
      worker: MockWorker;
      type: string;
      startDate: string;
      endDate: string;
      days: number;
      status: string;
    }>;
  };
}

export interface MockPropertyData {
  isMock: boolean;
  mockNotice: string;
  data: {
    properties: Array<{
      id: string;
      name: string;
      type: string;
      workerCount: number;
      monthlyPayroll: number;
      address: string;
    }>;
    consolidatedSummary: {
      totalProperties: number;
      totalWorkers: number;
      totalMonthlyPayroll: number;
      avgPayrollPerProperty: number;
    };
    propertyComparison: Array<{
      property: string;
      jan: number;
      feb: number;
      mar: number;
    }>;
  };
}

export interface MockAccountingData {
  isMock: boolean;
  mockNotice: string;
  data: {
    journalEntries: Array<{
      date: string;
      description: string;
      debit: { account: string; amount: number };
      credit: { account: string; amount: number };
    }>;
    syncStatus: {
      lastSync: string;
      status: string;
      recordsSynced: number;
      pendingRecords: number;
    };
    connectedApps: Array<{
      name: string;
      status: string;
      lastSync: string | null;
    }>;
  };
}

export interface MockP9Data {
  isMock: boolean;
  mockNotice: string;
  data: {
    year: number;
    workers: Array<{
      worker: MockWorker;
      taxPin: string;
      monthlyBreakdown: Array<{
        month: number;
        grossPay: number;
        taxableIncome: number;
        paye: number;
        relief: number;
        netTax: number;
      }>;
      annualTotals: {
        grossPay: number;
        taxableIncome: number;
        totalPaye: number;
        totalRelief: number;
        netTax: number;
      };
    }>;
  };
}

export interface MockAdvancedReports {
  isMock: boolean;
  mockNotice: string;
  data: {
    payrollTrends: {
      sixMonthGrowth: number;
      avgMonthlyPayroll: number;
      projectedNextMonth: number;
      seasonalPatterns: Array<{ month: string; deviation: number }>;
    };
    workerInsights: {
      avgTenure: number;
      turnoverRate: number;
      costPerWorker: number;
      highestPaid: string;
      lowestPaid: string;
    };
    taxCompliance: {
      currentYearPaye: number;
      currentYearNssf: number;
      currentYearNhif: number;
      filingStatus: string;
      nextDeadline: string;
    };
    customReports: Array<{
      name: string;
      format: string;
      generated: string;
    }>;
  };
}
