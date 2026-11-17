# Audit Tracker — SFRS(I) & SSA

A single-page audit testing workspace for financial documents. Upload Excel workbooks, run automated audit tests, and track issues linked to Singapore Standards on Auditing (SSA) and SFRS(I) paragraphs.

## Features

- **Issue tracker** — amount, risk category, risk level (High / Medium / Low) and priority (P1–P3), ranked automatically against materiality.
- **Issue location** — every issue points to workbook › sheet › row › cell; click to jump to the highlighted cell.
- **Standards links** — SSA / SFRS(I) references open the standard with the specific paragraph highlighted.
- **Excel uploader** — `.xlsx`, `.xls`, `.xlsm`, `.csv`; every sheet is tested with auto-detected (and editable) column mapping.

Automated tests: debit/credit balance, casting of totals, duplicates, round-sum and weekend entries, manual/suspense entries, items above performance materiality, period-end cut-off, credit balances on assets, aged receivables (>365 days), related-party indicators, formula errors, numbers stored as text and blank descriptions.

## Sign-in & user management

Authentication uses Supabase Auth (`auth.users`). Users sign in with a **username**; the app maps it to an internal email `username@audit-tracker.local`.

| Username | Role | Initial password |
|---|---|---|
| priya | Administrator | `password` |
| dan | Auditor | `password` |
| marcus | Auditor | `password` |

Users are prompted to choose their own password after first sign-in. Administrators get a **Users** tab to add users with an initial password, reset passwords, change roles and delete users. These actions go through the `admin-users` Edge Function, which checks the caller is an admin and uses the service-role key server-side — no secret keys are in the browser.

## Data

Workbooks, issues and engagement settings are stored in Supabase per user (`public.settings`, `public.workbooks`, `public.issues`) with row-level security — each user sees only their own data. Data saved in a browser before sign-in was added is offered for import on first sign-in. Workbooks are parsed client-side with [SheetJS](https://sheetjs.com/).

### Supabase files

- `supabase/migrations/…_audit_tracker_schema.sql` — tables, RLS policies, profile trigger
- `supabase/seed_users.sql` — the three seed users (already applied)
- `supabase/functions/admin-users/` — admin Edge Function (deployed, `verify_jwt = false`; it validates the caller itself)

The publishable key in `index.html` is safe to expose; access is enforced by RLS.

**Recommended:** in the Supabase dashboard → Authentication → Sign In / Providers, turn off **Allow new users to sign up**, so accounts can only be created by an administrator.

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
