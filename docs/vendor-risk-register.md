# Vendor Risk Register

**Owner:** Michael Mader (michael@haderach.ai)  
**Status:** Draft — to be completed prior to SOC 2 Type I audit  
**Last reviewed:** 2026-04-14  
**Review cadence:** Annually (or on vendor change)

---

## Purpose

Tracks third-party vendors and subprocessors that handle Haderach data. SOC 2 requires that vendor risk is assessed and documented before onboarding and reviewed periodically.

---

## Register

| Vendor | Category | Data processed | Risk tier | SOC 2 / security docs | Notes |
|---|---|---|---|---|---|
| Google Cloud Platform | Cloud infrastructure | All platform data (compute, database, storage, auth) | High | SOC 2 Type II — [cloud.google.com/security/compliance](https://cloud.google.com/security/compliance) | Primary cloud provider |
| OpenAI | AI model API | User chat messages, agent prompts | High | SOC 2 Type II — [openai.com/security](https://openai.com/security) | Processes user input; DPA in place via API terms |
| GitHub | Source control / CI | Source code, secrets in Actions (via WIF) | Medium | SOC 2 Type II — [github.com/trust](https://github.com/trust) | No customer data; WIF used, no static secrets in Actions |
| Bill.com | Accounts payable data sync | Client vendor invoice data | High | SOC 2 Type II — [bill.com/security](https://bill.com/security) | Client credentials provided; OAuth migration tracked separately |
| QuickBooks Online (Intuit) | Accounting data sync | Client financial data | High | SOC 2 Type II — [intuit.com/security](https://intuit.com/security) | Client credentials provided; OAuth migration tracked separately |
| AWS (Cost Explorer) | Cloud billing data sync | Client AWS billing data | Medium | SOC 2 Type II — [aws.amazon.com/compliance](https://aws.amazon.com/compliance) | Client credentials provided; migration to customer-managed access tracked separately |
| Firebase Hosting | Frontend hosting | Public static assets only | Low | SOC 2 Type II — [firebase.google.com/support/privacy](https://firebase.google.com/support/privacy) | No customer data; public content only. Part of GCP/Google Trust Services. |
| Payload CMS | Headless CMS framework | CMS content (job listings, org metadata) | Low | MIT open source — self-hosted, no vendor-hosted data processing. [github.com/payloadcms/payload](https://github.com/payloadcms/payload) | Self-hosted on Cloud Run with dedicated Cloud SQL instance. No data leaves the platform. No DPA required — no vendor data custody. |
| _[TODO: add remaining SaaS tools as identified]_ | | | | | |

---

## Risk tier definitions

| Tier | Criteria |
|---|---|
| High | Processes or stores customer or client personal data; material breach impact |
| Medium | Accesses source code, infrastructure config, or billing metadata; limited PII exposure |
| Low | No access to customer data; public-facing static content only |

---

## DPA / contract status

| Vendor | DPA in place | Notes |
|---|---|---|
| Google Cloud | Yes — accepted via GCP console | Standard DPA |
| OpenAI | Yes — via API terms | Review if data residency requirements emerge |
| GitHub | Yes — via GitHub Enterprise terms | Standard DPA |
| Bill.com | _[TODO: confirm]_ | |
| QuickBooks Online | _[TODO: confirm]_ | |
| AWS | _[TODO: confirm]_ | |
