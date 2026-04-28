# Spike Plan

Goal: Discover the shape of Salesforce metadata-as-code and CI/CD, find where the workflow breaks with real-world use cases.

## Phase 1: Metadata-as-Code [DONE]

- [x] Install SF CLI, generate SFDX project
- [x] Scenario 1: Opportunity stages (StandardValueSet)
- [x] Scenario 2: Role hierarchy + profiles
- [x] Scenario 3: Custom fields + validation rule
- [x] Scenario 4: Lead conversion Flow
- [x] Scenario 5: Round-trip deploy script — tested clean on fresh scratch org
- [x] Seed data (Apex + JSON)
- [x] Verify each scenario works in org UI (including Lead conversion Flow)

## Phase 1.5: Manual CI/CD Dry Run [IN PROGRESS]

Test the change->retrieve->commit->deploy-to-persistent-org workflow by hand before automating.

### Ownership restriction rules [DONE]
- [x] Closed Won Opportunities are locked — only admins can edit/change ownership
- [x] SDRs can reassign Opportunity ownership only in Prospecting/Discovery
- [x] Only admins can change Account ownership
- [x] Apex tests for ownership rules (with MIXED_DML_OPERATION workaround)

### AppExchange / managed packages [DONE]
- [x] Install DLRS into scratch org
- [x] Retrieve metadata to see what it added
- [x] Discovered: managed package metadata is retrievable but NOT deployable
- [x] Created `dependencies.json` manifest pattern (like package.json for SF packages)
- [x] Updated setup script to install packages from manifest before deploying source
- [x] Added `.forceignore` patterns for managed package namespaces
- [x] Cleaned up retrieved DLRS metadata from repo

### Versioning / release strategy [DONE]
- [x] Tag current working state as v0.1.0

### Remaining Phase 1.5 work
- [ ] Create test users (SDR, Sales Manager) to verify permissions work end-to-end
- [ ] Deploy to Dev org (persistent) — simulates "merge to main -> deploy to staging"
- [ ] Document the runbook for "we installed an app, now what"

## Phase 2: CI/CD Pipeline

- [ ] GitHub Actions: validate on PR open (deploy --check-only / dry-run)
- [ ] GitHub Actions: deploy on PR merge to main
- [ ] Auth strategy for CI (JWT bearer flow vs. SFDX auth URL)
- [ ] Scratch org creation in CI for validation
- [ ] Secret management for SF auth
- [ ] Sandbox-specific setup script variant

## Open Questions

- [ ] Profile metadata explosion — real orgs have massive profile files. How do teams manage this?
- [ ] Flow metadata is verbose and hard to diff — what do teams actually do for code review on Flows?
- [ ] Conflict resolution when two people modify the same metadata type
- [ ] Metadata documentation gap — no in-file comments, description fields are limited
- [ ] Retrieve pulls ALL metadata of a type — need a strategy for what to include vs. ignore
- [ ] Standard object fields bloat the repo — every retrieve pulls dozens of standard field XMLs
- [ ] How to handle package version upgrades — do you just change the versionId in dependencies.json?
