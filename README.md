# Audit Tracker — SFRS(I) & SSA

A single-page audit testing workspace for financial documents. Upload Excel workbooks, run automated audit tests, and track issues linked to Singapore Standards on Auditing (SSA) and SFRS(I) paragraphs.

## Features

- **Issue tracker** — amount, risk category, risk level (High / Medium / Low) and priority (P1–P3), ranked automatically against materiality.
- **Issue location** — every issue points to workbook › sheet › row › cell; click to jump to the highlighted cell.
- **Standards links** — SSA / SFRS(I) references open the standard with the specific paragraph highlighted.
- **Excel uploader** — `.xlsx`, `.xls`, `.xlsm`, `.csv`; every sheet is tested with auto-detected (and editable) column mapping.

Automated tests: debit/credit balance, casting of totals, duplicates, round-sum and weekend entries, manual/suspense entries, items above performance materiality, period-end cut-off, credit balances on assets, aged receivables (>365 days), related-party indicators, formula errors, numbers stored as text and blank descriptions.

## Data & privacy

All data is stored in the browser's `localStorage`. Workbooks are parsed client-side with [SheetJS](https://sheetjs.com/) (loaded from cdnjs) and are never sent to a server. Data is per browser and per device — clearing site data removes it.

## Deploy to Vercel

This is a static site — no build step.

1. In Vercel, choose **Add New → Project** and import `wcheeng69-asp/audit-tracker`.
2. Framework preset: **Other**. Leave Build Command and Output Directory empty; Root Directory `./`.
3. Click **Deploy**.

Or from the CLI:

```bash
npm i -g vercel
vercel        # preview
vercel --prod # production
```

`vercel.json` adds basic security headers and disables caching of `index.html` so new versions show immediately.

## Run locally

Open `index.html` in a browser, or serve the folder:

```bash
npx serve .
```

## Disclaimer

Paragraph summaries of SSA and SFRS(I) are paraphrased for working use and are not the authoritative text. Refer to the standards issued by ISCA and the Accounting Standards Council, and check for revisions effective for the period under audit. The automated tests are aids to professional judgement, not a substitute for it.
