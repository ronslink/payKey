const fs = require('fs');
const pdfjs = require('pdfjs-dist/legacy/build/pdf.js');

const pdfPath = process.argv[2] || 'D:/payKey/backend/data_import/SAMUEL OLAGO NSSF NHIF and PAYSLIPS/NSSF 2024 - 2025/NSSF - Samuel Olago - Jan 2024.pdf';

async function extractPdf() {
    const data = new Uint8Array(fs.readFileSync(pdfPath));
    const pdf = await pdfjs.getDocument({ data }).promise;

    let fullText = '';
    for (let i = 1; i <= pdf.numPages; i++) {
        const page = await pdf.getPage(i);
        const textContent = await page.getTextContent();
        const pageText = textContent.items.map(item => item.str).join(' ');
        fullText += `\n=== Page ${i} ===\n${pageText}`;
    }

    console.log(fullText);
}

extractPdf().catch(console.error);
