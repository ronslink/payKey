# Statutory Tax API Integration Requirements: Kenya

This document outlines the requirements for becoming a "Certified Intermediary" or "Third-Party Integrator" to enable direct API filing for payroll taxes in Kenya. 

Direct API integration is an alternative to the file-based export/upload method but requires significant vetting and technical compliance.

## 1. Kenya Revenue Authority (KRA) - iTax / GavaConnect

To integrate directly with KRA's systems (e.g., for auto-filing P10 returns), a provider must become a **Certified Third-Party Integrator**.

### Requirements
*   **Vetting & Documentation:**
    *   Submission of company registration documents (Certificate of Incorporation, CR12).
    *   Valid Tax Compliance Certificate (TCC).
    *   Details of directors and technical capacity proof.
*   **Sandbox Certification:**
    *   Registration on the KRA Developer Portal (GavaConnect).
    *   Successful completion of technical tests in the KRA Sandbox environment to verify tax calculation accuracy matches iTax logic exactly.
*   **Device Integration (eTIMS/VSCU):**
    *   For VAT and certain payroll functions, integration with a Virtual Sales Control Unit (VSCU) or OSCU standard may be required.
*   **Security Audit:**
    *   Systems must pass strict security and functional audits before production API keys are issued.

### Resources
*   [KRA Developer Portal](https://developer.kra.go.ke/)
*   [GavaConnect Information](https://www.kra.go.ke/)

---

## 2. Social Health Authority (SHA) - SHIF

The Social Health Authority (formerly NHIF) mandates strict technical standards for health data exchange and contribution remittance.

### Requirements
*   **FHIR Standard Compliance:**
    *   Integration must strictly adhere to the **Fast Healthcare Interoperability Resources (FHIR) R4** standard for all data exchange.
*   **Developer Onboarding:**
    *   Registration as a partner on the SHA Developer Portal (`developer.dha.go.ke`).
    *   Approval of the organizational profile.
*   **Security Standards:**
    *   Mandatory use of JSON Web Tokens (JWT) for authentication.
    *   Full compliance with the **Data Protection Act (2019)** regarding patient/employee data handling.
*   **Interoperability:**
    *   Systems must be able to verify patient/employee eligibility via API before submission.

### Resources
*   [SHA Developer Portal](https://developer.dha.go.ke)

---

## 3. National Social Security Fund (NSSF) - ESSP

NSSF integration is typically less "open" than KRA or SHA and often operates on a partnership model.

### Requirements
*   **Direct Partnership/Contract:**
    *   Integration often requires a formal agreement or "Digital Service Provider" contract with NSSF.
*   **ESSP Backend Integration:**
    *   Technical integration connects directly to the Enhanced Self-Service Portal (ESSP) backend.
*   **Certification:**
    *   Verification of the ability to generate valid SF24 data structures and process payments correctly.

---

## Strategic Recommendation

Given the complexity and 3-6 month timeline for full API certification, **statutory file exports** (Excel/CSV) are the recommended immediate solution.

*   **Current Capability:** The system currently supports generating:
    *   **KRA P10 (CSV)**
    *   **NSSF Returns (Excel/CSV Compatible)**
    *   **SHIF Returns (Excel/CSV Compatible)**

These files can be downloaded by any employer and uploaded to the respective portals (iTax, ESSP, SHA) immediately, ensuring compliance without waiting for intermediary certification.
