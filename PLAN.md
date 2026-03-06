# Spike Plan

Goal: Discover the shape of Salesforce metadata-as-code and CI/CD, find where the workflow breaks with real-world use cases.

## Phase 1: Metadata-as-Code (current)

- [x] Install SF CLI, generate SFDX project
- [x] Scenario 1: Opportunity stages (StandardValueSet)
- [x] Scenario 2: Role hierarchy + profiles
- [x] Scenario 3: Custom fields + validation rule
- [x] Scenario 4: Lead conversion Flow
- [x] Scenario 5: Round-trip deploy script
- [x] Seed data (Apex + JSON)
- [x] Get a clean deploy to a scratch org
- [x] Load and verify seed data
- [ ] Verify each scenario works in the org UI
- [ ] Test the full round-trip script on a fresh scratch org
- [ ] Commit working state

## Phase 2: CI/CD Pipeline

- [ ] GitHub Actions: deploy on PR merge
- [ ] GitHub Actions: validate on PR open (deploy --dry-run)
- [ ] Scratch org pooling or on-demand creation in CI
- [ ] Secret management for SF auth in CI

## Open Questions / To Explore

- [ ] What happens when you install an AppExchange package — what metadata does it add, and does it pollute the repo on retrieve?
- [ ] How do you handle metadata that shouldn't be in source control (org-specific settings, user records, etc.)?
- [ ] XML comments not supported by SF CLI metadata converter — what's the documentation story for metadata files? (research in progress)
- [ ] Profile metadata explosion — real orgs have massive profile files. How do teams manage this?
- [ ] Flow metadata is verbose and hard to diff — what do teams actually do for code review on Flows?
- [ ] Conflict resolution when two people modify the same metadata type
- [ ] What's the metadata impact of installing plugins/apps from AppExchange on the CI/CD flow?
- [ ] `<description>` element limitations — what's the real documentation strategy for Salesforce metadata? (research in progress)
