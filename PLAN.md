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

## Phase 1.5: Manual CI/CD Dry Run (current)

Test the change→retrieve→commit→deploy-to-persistent-org workflow by hand before automating.

### Feature work (vehicle for testing the workflow)
- [ ] Closed Won Opportunities are locked — only admins can edit/change ownership
- [ ] SDRs can reassign Opportunity ownership only in Prospecting/Discovery
- [ ] Only admins can change Account ownership
- [ ] Create test users (SDR, Sales Manager) to verify permissions work
- [ ] Deploy to Dev org (persistent) — simulates "merge to main → deploy to staging"

### AppExchange experiment
- [ ] Install a real AppExchange package into scratch org
- [ ] Retrieve metadata to see what it added
- [ ] Figure out the "commit back" process — what goes in the repo vs. what gets ignored
- [ ] Document the runbook for "we installed an app, now what"

### Versioning / release strategy
- [ ] Decide on tagging approach (git tags with semver? GitHub releases?)
- [ ] Tag the current working state as v0.1.0

## Phase 2: CI/CD Pipeline

- [ ] GitHub Actions: validate on PR open (deploy --check-only / dry-run)
- [ ] GitHub Actions: deploy on PR merge to main
- [ ] Auth strategy for CI (JWT bearer flow vs. SFDX auth URL)
- [ ] Scratch org creation in CI for validation
- [ ] Secret management for SF auth

## Open Questions

- [ ] Profile metadata explosion — real orgs have massive profile files. How do teams manage this?
- [ ] Flow metadata is verbose and hard to diff — what do teams actually do for code review on Flows?
- [ ] Conflict resolution when two people modify the same metadata type
- [ ] Metadata documentation gap — no in-file comments, description fields are limited
- [ ] Retrieve pulls ALL metadata of a type — need a strategy for what to include vs. ignore
- [ ] Standard object fields bloat the repo — every retrieve pulls dozens of standard field XMLs
