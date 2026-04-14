# Incident Response Policy

**Owner:** Michael Mader (michael@haderach.ai)  
**Status:** Draft — to be completed prior to SOC 2 Type I audit  
**Last reviewed:** 2026-04-14  
**Review cadence:** Annually

---

## Scope

Covers security incidents affecting the Haderach platform, including:
- Unauthorized access to systems, data, or credentials
- Confirmed or suspected data breach involving customer or client data
- Credential compromise (SA keys, API keys, OAuth tokens)
- Significant service availability events impacting customers

---

## Severity tiers

| Tier | Definition | Initial response target |
|---|---|---|
| P0 | Active breach, confirmed data exposure, or credential compromise in production | Within 1 hour |
| P1 | Suspected compromise, anomalous access patterns, or significant availability impact | Within 4 hours |
| P2 | Anomalous activity requiring investigation, no confirmed impact | Within 24 hours |

---

## Notification timelines

- **Internal escalation:** Immediate on P0/P1 detection
- **Customer notification:** Within 72 hours of confirmed breach (GDPR Article 33 / CCPA requirement)
- **Subprocessor notification:** Per DPA obligations — notify affected subprocessors within 24 hours of confirmed breach

---

## Response procedure

1. **Detect** — Alert triggered via GCP Admin Activity logs, anomaly detection, or manual discovery
2. **Contain** — Revoke compromised credentials, isolate affected systems
3. **Assess** — Determine scope of exposure (what data, which users, what timeframe)
4. **Notify** — Follow notification timelines above
5. **Remediate** — Rotate credentials, patch vulnerabilities, update access controls
6. **Document** — Record incident timeline, actions taken, and lessons learned
7. **Review** — Post-incident review within 5 business days

_[TODO: expand with specific runbook steps per incident type]_

---

## Contacts

| Role | Contact |
|---|---|
| Incident owner | Michael Mader — michael@haderach.ai |
| _[TODO: add backup contact when team grows]_ | |
