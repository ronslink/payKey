export declare enum AccountCategory {
    SALARY_EXPENSE = "SALARY_EXPENSE",
    PAYE_LIABILITY = "PAYE_LIABILITY",
    NSSF_LIABILITY = "NSSF_LIABILITY",
    NHIF_LIABILITY = "NHIF_LIABILITY",
    HOUSING_LEVY_LIABILITY = "HOUSING_LEVY_LIABILITY",
    CASH_BANK = "CASH_BANK"
}
export declare class AccountMapping {
    id: string;
    userId: string;
    category: AccountCategory;
    accountCode: string;
    accountName: string;
    description: string;
    createdAt: Date;
    updatedAt: Date;
}
