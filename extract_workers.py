import subprocess
import re
import json
import os

def extract_text(pdf_path):
    result = subprocess.run(['pdftotext', '-layout', pdf_path, '-'], capture_output=True, text=True)
    return result.stdout

def parse_payslip_text(text):
    # Each payslip is separated by multiple newlines or the header
    # We can split by the header "Samuel Olago"
    sections = re.split(r'\s+Samuel Olago', text)
    
    workers = []
    
    for section in sections:
        if "PAYSLIP" not in section:
            continue
            
        worker = {}
        
        # Helper to extract value after a label
        def get_val(label, line):
            if label in line:
                part = line.split(label)[1].strip()
                # If there's another label on the same line, truncate
                for other in ["NSSF No:", "ID No:", "PIN No:", "NHIF No:"]:
                    if label != other and other in part:
                        part = part.split(other)[0].strip()
                return part
            return None

        for line in section.split('\n'):
            line = line.strip()
            if not line: continue
            
            if "Emp No:" in line:
                val = get_val("Emp No:", line)
                if val: worker["emp_no"] = val
            
            if "Name:" in line:
                val = get_val("Name:", line)
                if val: worker["name"] = val
                
            if "Department:" in line:
                val = get_val("Department:", line)
                if val: worker["department"] = val
                
            if "Job Title:" in line:
                val = get_val("Job Title:", line)
                if val: worker["job_title"] = val
                
            if "PIN No:" in line:
                val = get_val("PIN No:", line)
                if val: worker["pin"] = val
            
            if "NSSF No:" in line:
                val = get_val("NSSF No:", line)
                if val: worker["nssf"] = val
                
            if "NHIF No:" in line:
                val = get_val("NHIF No:", line)
                if val: worker["nhif"] = val
                
            if "ID No:" in line:
                val = get_val("ID No:", line)
                if val: worker["id_no"] = val
                
            if "Basic Pay" in line:
                # Basic Pay is usually followed by a large space and then the amount
                parts = re.split(r'\s{2,}', line)
                if len(parts) >= 2:
                    worker["basic_pay"] = parts[-1].replace(',', '')
            
            if "Gross Pay" in line and "Gross Taxable" not in line:
                parts = re.split(r'\s{2,}', line)
                if len(parts) >= 2:
                    worker["gross_pay"] = parts[-1].replace(',', '')
            
            # Extract deductions
            if line.startswith("PAYE") and "PAYE" == line.split()[0]:
                parts = re.split(r'\s{2,}', line)
                if len(parts) >= 2:
                    worker["paye"] = parts[-1].replace(',', '')
            
            if "N.S.S.F - Employee" in line or "N.S.S.F. - Employee" in line:
                parts = re.split(r'\s{2,}', line)
                if len(parts) >= 2:
                    worker["nssf_employee"] = parts[-1].replace(',', '')
            
            if line.startswith("NHIF") and len(line.split()) <= 3:
                parts = re.split(r'\s{2,}', line)
                if len(parts) >= 2:
                    worker["nhif_deduction"] = parts[-1].replace(',', '')
            
            if "NET PAY" in line:
                parts = re.split(r'\s{2,}', line)
                if len(parts) >= 2:
                    worker["net_pay"] = parts[-1].replace(',', '')

        if "name" in worker and worker.get("emp_no", "").isdigit():
            workers.append(worker)
            
    return workers

def process_folder(folder_path):
    all_workers = {}
    payroll_history = []
    
    files = sorted([f for f in os.listdir(folder_path) if f.endswith('.pdf')])
    
    for file in files:
        # Extract month/year from filename like "Payslips - January 2024.pdf"
        match = re.search(r'Payslips - (\w+) (\d{4})', file)
        if not match: continue
        
        month_str = match.group(1)
        year_str = match.group(2)
        
        path = os.path.join(folder_path, file)
        text = extract_text(path)
        workers = parse_payslip_text(text)
        
        month_records = []
        for w in workers:
            name = w['name']
            if name not in all_workers:
                all_workers[name] = w
            else:
                for k, v in w.items():
                    if v and not all_workers[name].get(k):
                        all_workers[name][k] = v
                    elif k == 'basic_pay' and v:
                        all_workers[name][k] = v
            
            month_records.append({
                "name": name,
                "gross_salary": w.get("gross_pay", w.get("basic_pay", "0")),
                "basic_pay": w.get("basic_pay", "0"),
                "paye": w.get("paye", "0"),
                "nssf_employee": w.get("nssf_employee", "0"),
                "nhif": w.get("nhif_deduction", "0"),
                "net_pay": w.get("net_pay", "0"),
            })
            
        payroll_history.append({
            "month": month_str,
            "year": year_str,
            "records": month_records
        })
                        
    return list(all_workers.values()), payroll_history

if __name__ == "__main__":
    folder = "/Users/ron/Downloads/SAMUEL OLAGO NSSF NHIF and PAYSLIPS/Payslips and Muster file - 2024 - 2025"
    workers, history = process_folder(folder)
    
    output = {
        "workers": workers,
        "payroll_history": history
    }
    
    print(json.dumps(output, indent=2))
    
    with open("extracted_data.json", "w") as f:
        json.dump(output, f, indent=2)
