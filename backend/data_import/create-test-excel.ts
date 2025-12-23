import * as XLSX from 'xlsx';
import * as fs from 'fs';

// Create test data with 10 Kenyan workers
const workers = [
    {
        'name*': 'Wanjiku Muthoni',
        'phoneNumber*': '+254722111001',
        'salaryGross*': 18000,
        'idNumber': '28451234',
        'kraPin': 'A001234567B',
        'nssfNumber': '100234567',
        'nhifNumber': '1234567',
        'jobTitle': 'House Help',
        'startDate': '2026-01-01',
        'dateOfBirth': '1985-03-15',
    },
    {
        'name*': 'Omondi Peter',
        'phoneNumber*': '+254733222002',
        'salaryGross*': 22000,
        'idNumber': '31245678',
        'kraPin': 'A002345678C',
        'nssfNumber': '100345678',
        'nhifNumber': '2345678',
        'jobTitle': 'Gardener',
        'startDate': '2026-01-01',
        'dateOfBirth': '1980-07-22',
    },
    {
        'name*': 'Akinyi Grace',
        'phoneNumber*': '+254711333003',
        'salaryGross*': 25000,
        'idNumber': '29876543',
        'kraPin': 'A003456789D',
        'nssfNumber': '100456789',
        'nhifNumber': '3456789',
        'jobTitle': 'Cook',
        'startDate': '2026-01-01',
        'dateOfBirth': '1990-11-08',
    },
    {
        'name*': 'Kiprop David',
        'phoneNumber*': '+254720444004',
        'salaryGross*': 20000,
        'idNumber': '30567891',
        'kraPin': 'A004567890E',
        'nssfNumber': '100567890',
        'nhifNumber': '4567890',
        'jobTitle': 'Driver',
        'startDate': '2026-01-01',
        'dateOfBirth': '1988-02-28',
    },
    {
        'name*': 'Nyambura Faith',
        'phoneNumber*': '+254712555005',
        'salaryGross*': 15000,
        'idNumber': '27654321',
        'kraPin': 'A005678901F',
        'nssfNumber': '100678901',
        'nhifNumber': '5678901',
        'jobTitle': 'Nanny',
        'startDate': '2026-01-01',
        'dateOfBirth': '1992-05-10',
    },
    {
        'name*': 'Otieno James',
        'phoneNumber*': '+254725666006',
        'salaryGross*': 28000,
        'idNumber': '32456789',
        'kraPin': 'A006789012G',
        'nssfNumber': '100789012',
        'nhifNumber': '6789012',
        'jobTitle': 'Security Guard',
        'startDate': '2026-01-01',
        'dateOfBirth': '1978-09-03',
    },
    {
        'name*': 'Chebet Rose',
        'phoneNumber*': '+254734777007',
        'salaryGross*': 16000,
        'idNumber': '28765432',
        'kraPin': 'A007890123H',
        'nssfNumber': '100890123',
        'nhifNumber': '7890123',
        'jobTitle': 'Cleaner',
        'startDate': '2026-01-01',
        'dateOfBirth': '1995-12-20',
    },
    {
        'name*': 'Kamau Michael',
        'phoneNumber*': '+254721888008',
        'salaryGross*': 19000,
        'idNumber': '29123456',
        'kraPin': 'A008901234I',
        'nssfNumber': '100901234',
        'nhifNumber': '8901234',
        'jobTitle': 'Houseboy',
        'startDate': '2026-01-01',
        'dateOfBirth': '1993-06-14',
    },
    {
        'name*': 'Adhiambo Lucy',
        'phoneNumber*': '+254710999009',
        'salaryGross*': 21000,
        'idNumber': '30234567',
        'kraPin': 'A009012345J',
        'nssfNumber': '100012345',
        'nhifNumber': '9012345',
        'jobTitle': 'Laundry Person',
        'startDate': '2026-01-01',
        'dateOfBirth': '1987-04-25',
    },
    {
        'name*': 'Mutua Joseph',
        'phoneNumber*': '+254723000010',
        'salaryGross*': 24000,
        'idNumber': '31876543',
        'kraPin': 'A010123456K',
        'nssfNumber': '100123456',
        'nhifNumber': '0123456',
        'jobTitle': 'Caretaker',
        'startDate': '2026-01-01',
        'dateOfBirth': '1982-08-17',
    },
];

// Create workbook
const workbook = XLSX.utils.book_new();

// Add data sheet
const headers = [
    'name*',
    'phoneNumber*',
    'salaryGross*',
    'idNumber',
    'kraPin',
    'nssfNumber',
    'nhifNumber',
    'jobTitle',
    'startDate',
    'dateOfBirth',
];

const worksheet = XLSX.utils.json_to_sheet(workers, { header: headers });

// Set column widths
worksheet['!cols'] = [
    { wch: 20 }, // name
    { wch: 16 }, // phone
    { wch: 12 }, // salary
    { wch: 12 }, // idNumber
    { wch: 14 }, // kraPin
    { wch: 12 }, // nssf
    { wch: 12 }, // nhif
    { wch: 15 }, // jobTitle
    { wch: 12 }, // startDate
    { wch: 12 }, // dateOfBirth
];

XLSX.utils.book_append_sheet(workbook, worksheet, 'Workers');

// Write to file
const buffer = XLSX.write(workbook, { type: 'buffer', bookType: 'xlsx' });
fs.writeFileSync('./test_workers_import.xlsx', buffer);

console.log('✅ Created test_workers_import.xlsx with 10 Kenyan workers');
console.log('\nWorkers:');
workers.forEach((w, i) => {
    console.log(`  ${i + 1}. ${w['name*']} - ${w['jobTitle']} (KES ${w['salaryGross*']})`);
});
