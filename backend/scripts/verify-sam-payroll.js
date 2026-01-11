/**
 * Verify Sam Olago's 2025 Payroll Calculations
 * Compares stored tax breakdowns against what they should be with correct tax configs
 */

const axios = require('axios');

const API_URL = 'https://api.paydome.co';

async function verifyPayrollCalculations() {
    console.log('🔍 Verifying Sam Olago\'s 2025 Payroll Calculations...\n');

    let token;
    try {
        const loginResponse = await axios.post(`${API_URL}/auth/login`, {
            email: 'kingpublish@gmail.com',
            password: 'Sam2026test!',
        });
        token = loginResponse.data.access_token;
        console.log('✅ Authenticated as Sam Olago\n');
    } catch (error) {
        console.error('❌ Authentication failed:', error.response?.data?.message || error.message);
        return;
    }

    const authHeaders = { Authorization: 'Bearer ' + token };

    // 1. Get Workers
    let workers = [];
    try {
        const workersRes = await axios.get(`${API_URL}/workers`, { headers: authHeaders });
        workers = workersRes.data;
        console.log(`📊 Found ${workers.length} workers:`);
        workers.forEach(w => console.log(`   - ${w.name}: KES ${w.salaryGross?.toLocaleString() || 'N/A'}`));
    } catch (e) {
        console.error('❌ Failed to fetch workers:', e.message);
        return;
    }

    // 2. Get Pay Periods (2025)
    let payPeriods = [];
    try {
        const periodsRes = await axios.get(`${API_URL}/pay-periods?limit=100`, { headers: authHeaders });
        const allPeriods = Array.isArray(periodsRes.data.data) ? periodsRes.data.data : periodsRes.data;
        payPeriods = allPeriods.filter(p => p.name.includes('2025'));
        console.log(`\n📅 Found ${payPeriods.length} 2025 Pay Periods:`);
        payPeriods.forEach(p => console.log(`   - ${p.name}: ${p.status}`));
    } catch (e) {
        console.error('❌ Failed to fetch pay periods:', e.message);
        return;
    }

    if (payPeriods.length === 0) {
        console.log('\n⚠️ No 2025 pay periods found. Nothing to verify.');
        return;
    }

    // 3. For each completed/processing period, get payroll records and compare
    console.log('\n' + '='.repeat(80));
    console.log('📋 PAYROLL VERIFICATION');
    console.log('='.repeat(80));

    for (const period of payPeriods) {
        console.log(`\n📅 ${period.name} (${period.status})`);
        console.log('-'.repeat(60));

        try {
            const recordsRes = await axios.get(`${API_URL}/payroll/period-records/${period.id}`, { headers: authHeaders });
            const records = recordsRes.data;

            if (records.length === 0) {
                console.log('   No payroll records found.');
                continue;
            }

            for (const record of records) {
                const workerName = record.worker?.name || record.workerId;
                const grossSalary = parseFloat(record.grossSalary) || 0;
                const storedTaxBreakdown = record.taxBreakdown || {};
                const storedNetPay = parseFloat(record.netSalary || record.netPay) || 0;

                // Expected calculations (2025 Kenya tax rates)
                const expected = calculateExpectedTaxes(grossSalary);

                console.log(`\n   Worker: ${workerName}`);
                console.log(`   Gross: KES ${grossSalary.toLocaleString()}`);

                const checks = [
                    { name: 'NSSF', stored: storedTaxBreakdown.nssf, expected: expected.nssf },
                    { name: 'SHIF/NHIF', stored: storedTaxBreakdown.nhif, expected: expected.shif },
                    { name: 'Housing Levy', stored: storedTaxBreakdown.housingLevy, expected: expected.housingLevy },
                    { name: 'PAYE', stored: storedTaxBreakdown.paye, expected: expected.paye },
                ];

                let hasDiscrepancy = false;
                for (const check of checks) {
                    const stored = parseFloat(check.stored) || 0;
                    const exp = check.expected;
                    const diff = stored - exp;
                    const status = Math.abs(diff) < 1 ? 'OK' : 'DIFF';
                    console.log(`   ${check.name}: Stored=${stored.toFixed(2)}, Expected=${exp.toFixed(2)}, Diff=${diff.toFixed(2)} [${status}]`);
                    if (Math.abs(diff) >= 1) hasDiscrepancy = true;
                }

                const storedTotal = parseFloat(storedTaxBreakdown.totalDeductions) ||
                    (parseFloat(storedTaxBreakdown.nssf || 0) + parseFloat(storedTaxBreakdown.nhif || 0) +
                        parseFloat(storedTaxBreakdown.housingLevy || 0) + parseFloat(storedTaxBreakdown.paye || 0));
                const expectedTotal = expected.totalDeductions;

                console.log(`   Total Deductions: Stored=${storedTotal.toFixed(2)}, Expected=${expectedTotal.toFixed(2)}`);
                console.log(`   Net Pay: Stored=${storedNetPay.toFixed(2)}, Expected=${(grossSalary - expectedTotal).toFixed(2)}`);

                if (hasDiscrepancy) {
                    console.log('   >>> DISCREPANCY DETECTED <<<');
                }
            }
        } catch (e) {
            console.log(`   ❌ Failed to fetch records: ${e.message}`);
        }
    }

    console.log('\n' + '='.repeat(80));
    console.log('✅ Verification complete');
}

/**
 * Calculate expected taxes using 2025 Kenya tax rates
 */
function calculateExpectedTaxes(grossSalary) {
    // NSSF (Feb 2025 rates)
    // Tier 1: 6% of first KES 8,000 = KES 480
    // Tier 2: 6% of KES 8,001 - 72,000
    let nssf = 0;
    const tier1Limit = 8000;
    const tier2Limit = 72000;
    const nssfRate = 0.06;

    nssf += Math.min(grossSalary, tier1Limit) * nssfRate;
    if (grossSalary > tier1Limit) {
        nssf += Math.min(grossSalary - tier1Limit, tier2Limit - tier1Limit) * nssfRate;
    }
    nssf = Math.round(nssf * 100) / 100;

    // SHIF (Oct 2024 rates - 2.75%, min KES 300)
    let shif = grossSalary * 0.0275;
    shif = Math.max(shif, 300);
    shif = Math.round(shif * 100) / 100;

    // Housing Levy (1.5%)
    let housingLevy = grossSalary * 0.015;
    housingLevy = Math.round(housingLevy * 100) / 100;

    // PAYE (Kenya 2023+ tax brackets)
    // Taxable income = Gross - NSSF
    const taxableIncome = grossSalary - nssf;
    let paye = 0;
    let remaining = taxableIncome;

    const brackets = [
        { limit: 24000, rate: 0.10 },
        { limit: 32333, rate: 0.25 },
        { limit: 500000, rate: 0.30 },
        { limit: 800000, rate: 0.325 },
        { limit: Infinity, rate: 0.35 },
    ];

    let prevLimit = 0;
    for (const bracket of brackets) {
        if (remaining <= 0) break;
        const bracketAmount = bracket.limit === Infinity ? remaining : Math.min(remaining, bracket.limit - prevLimit);
        paye += bracketAmount * bracket.rate;
        remaining -= bracketAmount;
        prevLimit = bracket.limit;
    }

    // Personal relief: KES 2,400/month
    paye = Math.max(0, paye - 2400);
    paye = Math.round(paye * 100) / 100;

    const totalDeductions = nssf + shif + housingLevy + paye;

    return {
        nssf,
        shif,
        housingLevy,
        paye,
        totalDeductions: Math.round(totalDeductions * 100) / 100,
    };
}

verifyPayrollCalculations();
