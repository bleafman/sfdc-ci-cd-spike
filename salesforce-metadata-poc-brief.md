# Salesforce Metadata-as-Code POC Brief

## Goal

Prove out a workflow where Salesforce org configuration (metadata) is managed as version-controlled code in Git, deployed via CLI, and could realistically be maintained by AI-assisted dev tools. This is a learning exercise and proof of concept — not production work.

## What We're Trying to Demonstrate

1. **Metadata retrieval**: Pull a Salesforce org's configuration into a local project as source files (XML).
2. **Version control**: Commit that metadata to Git and track changes over time.
3. **CLI-driven deployment**: Push metadata changes to a Salesforce org using SFDX — no ClickOps.
4. **Realistic-ish scenarios**: Make configuration changes that mirror the kind of work a Salesforce admin would do (not trivial, not production-critical).
5. **AI dev tool compatibility**: See how well tools like Claude Code can understand, modify, and deploy Salesforce metadata.

## Mental Model: How Salesforce Orgs, Projects, and Environments Relate

- **SFDX Project** = a local directory on your machine (lives in Git). This is your source of truth. It is NOT "inside" any Salesforce org — it's a local representation of metadata that you push to and pull from orgs.
- **Developer Edition Org** = a free, persistent Salesforce instance you sign up for. Has its own URL, data, metadata, users. You enable this as a **Dev Hub**, which gives it the ability to spawn scratch orgs.
- **Scratch Orgs** = ephemeral, disposable Salesforce instances created by your Dev Hub. Each is a fully independent org (own URL, own data, own metadata). They expire after 1-30 days. Used for development and testing.
- **Sandboxes** (not available in this POC) = clones of a paid production org. Same concept as scratch orgs but persistent, with real data. Only available with paid Salesforce licenses.

One project can interact with multiple orgs. You authenticate to each org separately and push/pull metadata between your local project and whichever org you're targeting.

Sandboxes CAN be managed via CLI (`sf org create sandbox`, `sf project deploy/retrieve`) — we just can't use them in this POC because they require a production org.

## Configuration Layers

Salesforce configuration is expressed through:
1. **Metadata API** — the primary source. Custom objects, fields, flows, profiles, validation rules, layouts, etc. Retrieved as XML files.
2. **Scratch Org Definition File** (`config/project-scratch-def.json`) — org-level settings like enabled features, edition, preferences. A separate config layer from metadata.
3. **Tooling API** — a more granular, REST-friendly way to query individual metadata components. Useful for scripting but not the primary retrieve/deploy mechanism.

## Legibility Note

The raw metadata is XML — structured and complete, but not always pleasant to read. Simple things (stages, fields, picklists) are quite readable. Complex things (Flows, profiles with hundreds of field permissions) are verbose and hard to scan.

However, the metadata is highly **machine-legible**. An AI tool (Claude, etc.) can parse the XML and answer questions like "what permissions does the SDR profile have?" or "what validation rules exist on Opportunity?" — which is a key benefit of the metadata-as-code approach.

A future enhancement (out of scope for this POC) would be a generated documentation layer — a script or AI-powered tool that reads the metadata repo and produces human-readable summaries of the sales process, permission model, automation rules, etc. Note this as a possibility but don't build it here.

## Environment

- **Salesforce Developer Edition** (free) — sign up at https://developer.salesforce.com/signup
- **Scratch orgs** for testing (available via SFDX with a Dev Hub-enabled org)
- **Public or private GitHub repo** for version control
- No paid Salesforce licenses or sandboxes required
- No third-party tools (no Gearset, Copado, etc.) — this is pure SFDX + Git

## Prerequisites (Manual Steps Before Handing Off to AI)

### 1. Sign up for a Salesforce Developer Edition
- Go to https://developer.salesforce.com/signup
- This will be your "Dev Hub" org (the org that can create scratch orgs)

### 2. Enable Dev Hub
- In your Developer Edition org: Setup → Dev Hub → Enable

### 3. Install the Salesforce CLI
- `npm install -g @salesforce/cli` (requires Node.js)
- Verify: `sf version`

### 4. Authenticate the CLI to your Dev Hub
- `sf org login web --set-default-dev-hub --alias devhub`
- This opens a browser for OAuth login

### 5. Initialize the project
- `sf project generate --name salesforce-poc`
- This creates the SFDX project structure

### 6. Create a scratch org
- `sf org create scratch --set-default --definition-file config/project-scratch-def.json --alias poc-scratch --duration-days 14`
- This gives you a clean, disposable Salesforce org to work against

### 7. Initialize Git
- `cd salesforce-poc && git init && git add . && git commit -m "Initial SFDX project"`

## Scenarios to Implement

Each scenario should follow the cycle: make change → retrieve metadata → commit to Git → verify you can deploy it to a fresh scratch org.

### Scenario 1: Customize Opportunity Stages
- Modify the default Opportunity stages to reflect a realistic B2B sales process
- Suggested stages: Prospecting → Discovery → Proposal → Negotiation → Closed Won / Closed Lost
- Assign probability percentages to each stage
- **What this tests**: picklist value metadata, deploy/retrieve cycle

### Scenario 2: Role Hierarchy and Profiles
- Create a basic role hierarchy: VP of Sales → Sales Manager → SDR
- Create or clone profiles for each role with different permission levels
  - Admin: full access
  - Sales Manager: read/write on Accounts, Contacts, Opportunities; can view reports
  - SDR: read/write on Leads and Contacts; read-only on Accounts; no access to Opportunities
- **What this tests**: role metadata, profile metadata, field-level security, RBAC-style config

### Scenario 3: Custom Fields and Validation Rules
- Add custom fields to the Opportunity object:
  - `Deal_Source__c` (picklist: Inbound, Outbound, Partner, Referral)
  - `Expected_Contract_Value__c` (currency)
  - `Next_Step__c` (text)
- Add a validation rule: Opportunity cannot be moved to "Proposal" stage without `Next_Step__c` being populated
- **What this tests**: custom field metadata, validation rule metadata, object-level customization

### Scenario 4: Basic Flow (Automation)
- Create a simple Flow: when a Lead is converted, auto-create a Task assigned to the Opportunity owner that says "Schedule discovery call"
- **What this tests**: Flow metadata (the most complex declarative metadata type), automation config as code

### Scenario 5: Round-Trip Deployment Test
- Spin up a brand-new scratch org
- Deploy ALL metadata from the Git repo to the new org
- Verify everything landed correctly
- **What this tests**: the core premise — can we express the org config as code and reconstitute it?

## Seed Data

Since we're using scratch orgs (not sandboxes), there's no production data to clone. Options for seed data:

- **SFDX data import**: Create a JSON or CSV file with sample records and use `sf data import tree` to load them. Include maybe 10-20 Accounts, 30-50 Contacts, 15-20 Opportunities across stages, and some Leads.
- **Anonymous Apex**: Write an Apex script that generates sample data. Run via `sf apex run --file seed-data.apex`.
- **Keep it minimal**: Seed data is nice-to-have for manual verification but isn't the core of this POC. Don't over-invest here.

A sample seed data set should include:
- Accounts: mix of company sizes (startup, mid-market, enterprise)
- Contacts: 2-3 per Account with different roles
- Opportunities: spread across the custom stages, various amounts
- Leads: some ready for conversion, some early-stage

## Project Structure (Expected)

```
salesforce-poc/
├── config/
│   └── project-scratch-def.json    # Scratch org definition
├── force-app/
│   └── main/
│       └── default/
│           ├── objects/             # Custom fields, validation rules
│           ├── profiles/            # Profile metadata
│           ├── roles/               # Role hierarchy
│           ├── flows/               # Flow automation
│           └── standardValueSets/   # Picklist values (e.g., Opportunity stages)
├── scripts/
│   ├── seed-data.apex              # Optional seed data script
│   └── setup.sh                    # Optional automation for org setup
├── data/                           # Optional seed data JSON/CSV files
├── sfdx-project.json
├── .gitignore
└── README.md
```

## Success Criteria

1. All five scenarios are committed to Git as metadata files
2. A fresh scratch org can be spun up and fully configured by deploying from the repo
3. The metadata is human-readable enough that an AI dev tool can understand and modify it
4. The round-trip (retrieve → commit → deploy to new org) works cleanly
5. Document any metadata that couldn't be captured or required manual steps

## Phase 2: GitHub Actions CI/CD Pipeline

Phase 1 (above) proves the metadata-as-code workflow manually via CLI. Phase 2 automates it. The goal is: no one deploys to the target org by hand. The pipeline is the only path to deployment.

### What to Build

**1. Validation on PR (required check before merge)**

A GitHub Action that triggers on every PR to `main`:
- Authenticates to a scratch org (or a dedicated validation scratch org)
- Runs `sf project deploy start --check-only --test-level RunLocalTests` — this validates the deployment and runs Apex tests without actually deploying
- Reports pass/fail as a GitHub status check
- PR cannot merge if validation fails

This is the equivalent of branch protection. The Salesforce org doesn't have native "block unauthorized deploys," but if the only way to get code into `main` is through a PR that passes this check, you've achieved the same thing.

**2. Deploy on merge to main**

A GitHub Action that triggers when a PR is merged to `main`:
- Authenticates to the target org
- Runs `sf project deploy start --test-level RunLocalTests` — this is the real deployment
- Posts deployment status (success/failure) somewhere visible (GitHub Actions log, Slack notification, whatever)

**3. Drift detection (scheduled)**

A GitHub Action on a cron schedule (e.g., daily or every few hours):
- Authenticates to the target org
- Runs `sf project retrieve start` to pull current metadata
- Diffs the result against what's in `main`
- If there's a diff, someone made a change directly in the org (ClickOps). The action should either:
  - Open an issue or PR with the diff, or
  - Post an alert to Slack/email
- This is the cheap alternative to Gearset's drift monitoring

### Authentication Setup

This is the trickiest part and should be documented carefully:

- Salesforce CLI in CI uses a **JWT bearer flow** for authentication (no interactive browser login)
- You'll need to:
  1. Create a **Connected App** in your Salesforce org (Setup → App Manager → New Connected App)
  2. Generate a self-signed SSL certificate and private key
  3. Configure the Connected App to use the certificate for JWT auth
  4. Store the private key as a **GitHub Secret** (e.g., `SALESFORCE_JWT_KEY`)
  5. Store the Connected App's consumer key as a GitHub Secret (e.g., `SALESFORCE_CONSUMER_KEY`)
  6. Store the target org username as a GitHub Secret (e.g., `SALESFORCE_USERNAME`)
- The auth command in CI: `sf org login jwt --client-id $SALESFORCE_CONSUMER_KEY --jwt-key-file server.key --username $SALESFORCE_USERNAME --set-default`

**Important**: Document the Connected App setup step-by-step. This is the part that trips people up most and is Salesforce-specific. A developer who's never touched Salesforce won't know what a Connected App is or how JWT auth maps to the platform.

### Expected Workflow Files

```
.github/
└── workflows/
    ├── validate-pr.yml        # Runs on PR to main — check-only deploy + tests
    ├── deploy-to-org.yml      # Runs on merge to main — real deployment
    └── drift-detection.yml    # Scheduled — detect untracked changes in org
```

### Success Criteria for Phase 2

1. A PR with broken metadata (e.g., a bad field reference) fails the validation check and cannot merge
2. A PR with valid metadata passes validation, merges, and auto-deploys to the target org
3. A manual change made directly in the Salesforce org is detected by the drift action and flagged
4. All auth credentials are in GitHub Secrets — nothing sensitive in the repo
5. The workflow files are well-commented (same audience guidance as Phase 1 — senior devs, not Salesforce-native)

### Phase 2 Notes

- For the POC, the "target org" for deployment can just be another scratch org or your Dev Hub org. In a real setup it'd be a production org or sandbox.
- Scratch orgs expire, so the validation workflow might need to create a fresh scratch org per PR run and delete it after. This is a common pattern but adds complexity — start with a persistent scratch org and note the limitation.
- The JWT auth setup is a one-time manual step. It's annoying but well-documented by Salesforce. Don't let it become a rabbit hole — get it working, move on.

## Audience and Documentation Style

This repo may be shared with senior developers who are strong engineers but have little or no Salesforce experience. Write all documentation, comments, and commit messages with that audience in mind.

Specific guidance:

- **Inline comments on metadata files**: Salesforce metadata is XML, and the element names aren't always self-explanatory. Add XML comments (`<!-- ... -->`) explaining what non-obvious elements do. For example, explain what `forecastCategory` means on an Opportunity stage, what `fieldPermissions` entries control in a profile, or why a Flow has the structure it does. Don't comment every line — assume the reader can read XML — but do explain Salesforce-specific concepts and any "why" that isn't obvious.
- **README and docs**: The README should explain Salesforce concepts as they come up — what a scratch org is, what the metadata represents, how the deploy/retrieve cycle works. Write it for someone who could build a full-stack app but has never opened Salesforce Setup. Don't assume familiarity with Salesforce terminology.
- **Commit messages**: Each commit should explain what was changed in plain English and why it matters from a business/admin perspective. E.g., "Add SDR profile with restricted Opportunity access — SDRs should only work Leads and Contacts, not edit deals directly."
- **Scripts**: Any shell scripts or Apex scripts should have header comments explaining what they do, and inline comments on any Salesforce-specific CLI flags or API calls. Explain what flags like `--target-org`, `--definition-file`, etc. are doing.
- **Don't dumb it down**: The audience is technically sophisticated. You don't need to explain what XML is or how Git works. Do explain Salesforce-specific mental models, terminology, and anything that would trip up a strong developer who's never touched the platform.

## Notes

- Scratch orgs expire (max 30 days). Don't rely on them persisting.
- The metadata is XML. It's structured and AI tools handle it well, but it can be dense — this is why the commenting guidance above matters.
- If a scenario fails to deploy cleanly, document why — that's a useful finding for the POC.
- This is explicitly a learning exercise. Move fast, break things, take notes.
