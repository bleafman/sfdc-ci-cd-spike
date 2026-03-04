# Salesforce Metadata-as-Code POC

A proof of concept demonstrating that Salesforce org configuration can be managed as version-controlled code, deployed via CLI, and maintained by AI-assisted dev tools.

## What This Repo Contains

This repo holds the **complete configuration** of a Salesforce sales org expressed as XML metadata files. No ClickOps — everything is code.

| Scenario | What It Configures | Key Files |
|---|---|---|
| **1. Opportunity Stages** | Custom B2B sales pipeline stages with probabilities | `standardValueSets/OpportunityStage.*` |
| **2. Roles & Profiles** | VP Sales → Sales Manager → SDR hierarchy with RBAC | `roles/`, `profiles/` |
| **3. Custom Fields & Validation** | Deal Source, Contract Value, Next Step fields + validation rule | `objects/Opportunity/` |
| **4. Flow Automation** | Auto-create "Schedule discovery call" task on Lead conversion | `flows/Lead_Conversion_Task_Creation.*` |
| **5. Round-Trip Deploy** | Script to spin up a new org and deploy everything from scratch | `scripts/setup.sh` |

## Salesforce Concepts for Non-Salesforce Developers

If you've never touched Salesforce, here's the mental model:

### Orgs, Projects, and Environments

- **This repo** is an SFDX Project — a local representation of metadata. It is NOT "inside" any Salesforce org. Think of it like Terraform files that describe infrastructure.
- **Developer Edition Org** = a free, persistent Salesforce instance you sign up for. We enable it as a **Dev Hub**, giving it the ability to create scratch orgs.
- **Scratch Orgs** = ephemeral, disposable Salesforce instances (expire in 1-30 days). Each is a fully independent org with its own URL, data, and metadata. Used for dev/test.
- **Deploy/Retrieve cycle** = you `push` metadata from your local project to an org (deploy), and `pull` metadata from an org to your local project (retrieve). Like `terraform apply` and `terraform plan`.

### What Is "Metadata"?

Salesforce metadata is the **configuration** of the platform — not the data itself. Custom objects, fields, validation rules, automation flows, profiles, roles, page layouts. It's all expressed as XML files that the Metadata API can deploy and retrieve.

### Profiles vs. Roles

These are separate access control layers:
- **Profiles** = what you can DO (CRUD permissions on objects, field-level visibility). Like IAM policies.
- **Roles** = what you can SEE (record-level visibility via hierarchy). A VP sees everything their reports own.

## Project Structure

```
├── config/
│   └── project-scratch-def.json      # Scratch org definition (edition, features)
├── force-app/main/default/
│   ├── standardValueSets/            # Picklist values (Opportunity stages)
│   ├── objects/Opportunity/
│   │   ├── fields/                   # Custom fields (Deal_Source__c, etc.)
│   │   └── validationRules/          # Business logic enforcement
│   ├── roles/                        # Role hierarchy (VP → Manager → SDR)
│   ├── profiles/                     # Permission profiles per role
│   └── flows/                        # Declarative automation (Lead conversion)
├── scripts/
│   ├── setup.sh                      # Round-trip deployment test script
│   └── apex/
│       └── seed-data.apex            # Sample data generation script
├── data/                             # JSON seed data (alternative to Apex)
├── sfdx-project.json                 # SFDX project config
└── salesforce-metadata-poc-brief.md  # Original POC brief
```

## Prerequisites

1. **Node.js** (for Salesforce CLI)
2. **Salesforce CLI**: `brew install sf` or `npm install -g @salesforce/cli`
3. **A Salesforce Developer Edition org**: Free signup at https://developer.salesforce.com/signup
4. **Dev Hub enabled** in that org: Setup → Dev Hub → Enable

## Getting Started

### 1. Authenticate to your Dev Hub

```bash
# Opens a browser for OAuth login — this connects your CLI to Salesforce
sf org login web --set-default-dev-hub --alias devhub
```

### 2. Create a scratch org and deploy everything

```bash
# One command does it all: creates a scratch org, deploys metadata, loads sample data
./scripts/setup.sh --with-seed-data
```

Or step by step:

```bash
# Create a scratch org (ephemeral Salesforce instance, expires in 7 days)
sf org create scratch --set-default --definition-file config/project-scratch-def.json --alias poc-scratch --duration-days 7

# Deploy all metadata from this repo to the scratch org
sf project deploy start --target-org poc-scratch

# (Optional) Load sample data
sf apex run --file scripts/apex/seed-data.apex --target-org poc-scratch
```

### 3. Open the org in your browser

```bash
sf org open --target-org poc-scratch
```

### 4. Clean up when done

```bash
sf org delete scratch --target-org poc-scratch --no-prompt
```

## Making Changes

The workflow for modifying Salesforce configuration:

```bash
# 1. Make changes in the org UI (Setup → ...) or edit XML files directly
# 2. If you changed things in the org, retrieve the metadata:
sf project retrieve start --target-org poc-scratch

# 3. Review what changed
git diff

# 4. Commit
git add -A && git commit -m "Describe what changed and why"

# 5. Deploy to a fresh scratch org to verify
./scripts/setup.sh
```

## Seed Data

Two options for loading sample data:

| Method | Command | Records |
|---|---|---|
| **Apex script** (recommended) | `sf apex run --file scripts/apex/seed-data.apex` | 12 Accounts, 28 Contacts, 17 Opportunities, 16 Leads |
| **JSON import** (lighter) | `sf data import tree --plan data/sample-data-plan.json` | 5 Accounts, 9 Contacts, 6 Opportunities |

## Limitations and Notes

- Scratch orgs expire (max 30 days) — don't rely on them persisting
- Some metadata types can't be deployed to scratch orgs (certain org-level settings)
- The Flow metadata XML is verbose — this is normal, not a bug
- Profile metadata can be enormous in real orgs (hundreds of field permissions) — we're showing a minimal subset here
- Lead conversion Flows have known quirks with `ConvertedOpportunityId` field access timing
