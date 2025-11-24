# UI/UX Wireframe Descriptions

## 1. Worker Payment Flow

### Screen 1: Payroll Dashboard
*   **Header**: "Payroll Center" with current date.
*   **Body**: List of active workers. Each card shows:
    *   Worker Name & Photo.
    *   "Status": Active/On Leave.
    *   "Salary": KES Amount.
    *   Checkbox to select for payment.
*   **Bottom Bar**: "Total to Pay: KES X,XXX". Button "Proceed to Pay".

### Screen 2: Payment Review
*   **Header**: "Review Payment".
*   **Body**: Breakdown of costs.
    *   Worker A: Salary + Transport Allowance.
    *   Worker B: Salary.
    *   Transaction Fees: KES XX.
    *   **Total**: KES XXX.
*   **Payment Method**: Dropdown (Saved Card ****1234, M-Pesa Phone Number).
*   **Action**: "Confirm & Pay" Button (Prominent).

### Screen 3: Processing/Success
*   **State A (Processing)**: Spinner with text "Initiating M-Pesa request... Check your phone".
*   **State B (Success)**: Green Checkmark. "Payment Successful!".
    *   Button: "Send Payslips" (Share via WhatsApp/Email).
    *   Button: "Done".

## 2. Leave Request Approval Flow

### Screen 1: Notifications/Inbox
*   **List Item**: "Leave Request - John Doe".
    *   Subtitle: "Sick Leave • Oct 20 - Oct 22 (3 Days)".
    *   Action Buttons (Quick): "Approve", "Reject".

### Screen 2: Request Details (If clicked)
*   **Header**: "Leave Request".
*   **Worker Info**: John Doe.
*   **Leave Balance**: "Sick Leave Remaining: 5 Days".
*   **Request**:
    *   Type: Sick Leave.
    *   Dates: Oct 20 - Oct 22.
    *   Note: "Going to hospital".
*   **Actions**: Two large buttons at bottom. "Reject" (Red outline), "Approve" (Green solid).

## 3. Tax Report Generation

### Screen 1: Compliance Hub
*   **Header**: "Tax & Compliance".
*   **Tabs**: "Calculator", "Reports", "Filing".
*   **Body (Reports Tab)**:
    *   Filter: Year (2024), Month (October).
    *   List of generated reports:
        *   "PAYE Return - Oct 2024" (PDF | CSV).
        *   "NSSF Return - Oct 2024" (Excel).
        *   "NHIF Return - Oct 2024" (Excel).
*   **Action**: Floating Action Button (+) "Generate New Report".

### Screen 2: Generate Report Modal
*   **Select Period**: Month/Year picker.
*   **Select Workers**: "All Workers" or specific selection.
*   **Format**: Checkboxes [x] PDF [x] Excel (iTax Compatible).
*   **Button**: "Generate". -> Triggers download/share sheet.
