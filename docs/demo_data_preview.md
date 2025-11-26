# Pay Periods Demo Data Preview

## 🗄️ **CONFIRMED DATABASE CONNECTION**
- **Database**: `paykey` (in Docker container `paykey_db`)
- **Host**: localhost:5435
- **Current State**: 0 pay periods, ready for demo data

## 📊 **WHAT THE SEED SCRIPT WILL CREATE**

### 1. Demo User Account
- **Email**: testuser@paykey.com
- **Password**: password123
- **Name**: Test User
- **Purpose**: Demo account for testing

### 2. 5 Realistic Workers
| Name | Job Title | Salary | Type |
|------|-----------|--------|------|
| John Kamau Mwangi | Software Developer | 120,000/month | Fixed |
| Sarah Wanjiku Njeri | Marketing Manager | 85,000/month | Fixed |
| Michael Ochieng Otieno | Construction Worker | 500/hour | Hourly |
| Grace Achieng Adhiambo | HR Specialist | 65,000/month | Fixed |
| David Kiprotich Chepkemoi | Accountant | 95,000/month | Fixed |

### 3. 6 Pay Periods (Last 3 Months - Bi-weekly)
- Bi-weekly periods from 3 months ago to present
- Realistic date ranges and pay dates
- All marked as "COMPLETED" status

### 4. 30+ Payroll Records
- One record per worker per pay period
- Realistic salary calculations based on employment type
- Kenyan tax calculations (PAYE, NHIF, NSSF)
- Various payment statuses (paid, pending, processing)
- Overtime and allowances included

## 🎯 **BUSINESS VALUE**
This demo data will show:
- Complete payroll workflow
- Realistic financial amounts in KES
- Proper tax calculations
- Worker management integration
- Pay period lifecycle tracking

## ⚠️ **SAFETY CONFIRMATION**
- **Target Database**: paykey (confirmed via .env)
- **Will NOT affect**: Any other databases
- **Will overwrite**: Only testuser@paykey.com and related demo data
- **Safe to run**: Yes, designed for demo/testing purposes

Would you like me to proceed with creating this demo data?
