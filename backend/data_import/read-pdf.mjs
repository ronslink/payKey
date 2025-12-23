import { getDocument } from 'pdfjs-dist/legacy/build/pdf.mjs';
import { readFileSync } from 'fs';

const pdfPath = process.argv[2] || 'D:/payKey/backend/data_import/SAMUEL OLAGO NSSF NHIF and PAYSLIPS/Payslips and Muster file - 2024 - 2025/Payslips - January 2024.pdf';

async function extractPdf() {
    const data = new Uint8Array(readFileSync(pdfPath));
    const pdf = await getDocument({ data }).promise;

    let fullText = '';
    for (let i = 1; i <= pdf.numPages; i++) {
        const page = await pdf.getPage(i);
        const textContent = await page.getTextContent();
        const pageText = textContent.items.map(item => item.str).join('\n');
        fullText += `\n=== Page ${i} ===\n${pageText}`;
    }

    console.log(fullText);
}

extractPdf().catch(console.error);
