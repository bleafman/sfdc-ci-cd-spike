# Salesforce Metadata-as-Code Spike

A spike exploring whether a Salesforce org's configuration can be fully managed as version-controlled code, deployed via CLI, and fit into a standard Git-based release flow. Built collaboratively with [Claude Code](https://claude.ai/claude-code).

**The short version:** For pure Salesforce, yes — you can express your entire org config as code and reconstitute it from scratch. But the real-world picture is more complicated, and the gaps are significant enough that you'd be building a lot of tooling yourself.

## What We Found

### What works

- **Pure Salesforce metadata round-trips cleanly.** Custom objects, fields, validation rules, flows, profiles, roles, picklist values — all expressible as XML, all deployable from a git repo to a fresh org.
- **You can reconstitute an org from zero.** Our `setup.sh` script creates a scratch org, installs dependencies, deploys all metadata, grants permissions, and loads seed data. One command, clean org.
- **The SF CLI is functional.** `sf project deploy start` and `sf project retrieve start` work. The error messages are decent. The tooling exists.

### Where it diverges from mature IaC

- **Managed packages blow up the model.** Any AppExchange app (Gong, DLRS, LinkedIn Sales Navigator, etc.) can write custom fields, objects, and configuration to your org's metadata. You can retrieve this metadata but you can't deploy it — it belongs to the package's namespace. So reconstituting an org means installing packages first, in the right order, before deploying your source. Salesforce has no built-in dependency manifest. We invented one (`dependencies.json`) but you're managing this yourself.

- **There's no `terraform plan`.** You can deploy metadata and you can retrieve metadata, but there's no built-in way to preview what a deploy will change before it lands. No diff, no dry-run that shows you "these 14 fields will be modified." `--check-only` validates that a deploy *would succeed* and lists which components would be pushed, but doesn't show you the diff between what's in the org and what you're deploying. Drift detection — did someone modify prod directly? — is also something you'd have to build.

- **The CLI authenticates as *you*.** The default path is `sf org login web` — it opens a browser, you log in as yourself, and the CLI gets your permissions. If you're an admin, the CLI is a full admin. Salesforce does offer API integration users (every plan comes with some free ones, then ~$10/month), and for CI/CD you'd want JWT bearer flow with a Connected App and dedicated integration users with restricted permissions. But none of this is the happy path — the tooling defaults set you up in the pit of despair, not the pit of success.

- **The realistic release flow isn't CI/CD.** Based on what we found, the practical approach would be: manage config as code in feature branches → create a sandbox (which copies production *including data*) → apply your changes to the sandbox → test → promote to production via Salesforce's UI. That's not continuous deployment — it's more like a gated, sandbox-based release process. Full CI/CD with scratch orgs is possible but you'd be wiring up a lot of the plumbing yourself.

- **Reconciliation is an unsolved problem.** If someone makes a change directly in production (ClickOps), there's no built-in way to detect it, diff it against your repo, and reconcile. Tools like Gearset and Copado exist specifically to fill this gap, but they're of course rediculously expensive and also clickops, which tells you something about how well Salesforce handles it natively.

## What This Repo Contains

This repo holds the configuration of a Salesforce sales org expressed as XML metadata files — the output of testing five scenarios:

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

- **This repo** is an SFDX Project — a local representation of metadata. It is NOT "inside" any Salesforce org. Think of it like Terraform files that describe infrastructure, except without `terraform plan` or state management.
- **Developer Edition Org** = a free, persistent Salesforce instance you sign up for. We enable it as a **Dev Hub**, giving it the ability to create scratch orgs.
- **Scratch Orgs** = ephemeral, disposable Salesforce instances (expire in 1-30 days). Each is a fully independent org with its own URL, data, and metadata. Used for dev/test. Not a copy of production — they start empty.
- **Sandboxes** = copies of a production org (including data). Only available with paid Salesforce licenses. This is what you'd actually use for a realistic release flow, but we couldn't test with them in this spike.
- **Deploy/Retrieve cycle** = you `push` metadata from your local project to an org (deploy), and `pull` metadata from an org to your local project (retrieve). Deploy is blind — it applies changes without showing you a diff first.

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
│   ├── setup.sh                      # Round-trip deployment script
│   └── apex/
│       └── seed-data.apex            # Sample data generation script
├── data/                             # JSON seed data (alternative to Apex)
├── dependencies.json                 # Managed package dependency manifest (DIY)
├── sfdx-project.json                 # SFDX project config
└── salesforce-metadata-poc-brief.md  # Original spike brief
```

## Running It Yourself

If you want to reproduce this or use it as a starting point:

### Prerequisites

1. **Node.js** (for Salesforce CLI)
2. **Salesforce CLI**: `brew install sf` or `npm install -g @salesforce/cli`
3. **A Salesforce Developer Edition org**: Free signup at https://developer.salesforce.com/signup
4. **Dev Hub enabled** in that org: Setup → Dev Hub → Enable

### Deploy to a scratch org

```bash
# Authenticate (opens a browser — you log in as yourself, CLI gets your permissions)
sf org login web --set-default-dev-hub --alias devhub

# Create a scratch org and deploy everything
./scripts/setup.sh --with-seed-data

# Open it
sf org open --target-org poc-test

# Clean up when done (scratch orgs expire anyway, but this is immediate)
sf org delete scratch --target-org poc-test --no-prompt
```

## Seed Data

Two options for loading sample data:

| Method | Command | Records |
|---|---|---|
| **Apex script** (recommended) | `sf apex run --file scripts/apex/seed-data.apex` | 12 Accounts, 28 Contacts, 17 Opportunities, 16 Leads |
| **JSON import** (lighter) | `sf data import tree --plan data/sample-data-plan.json` | 5 Accounts, 9 Contacts, 6 Opportunities |

## On Drift Detection

If you continued down this path, the obvious next step is detecting when someone changes production directly (ClickOps) and reconciling those changes with what's in git. The rough idea:

- A GitHub Action on a cron schedule that authenticates to the target org, runs `sf project retrieve start`, and diffs the result against `main`
- If there's a diff, open a PR or issue with the changes for review

In practice this is clunky. Salesforce metadata is verbose XML with strict element ordering, so "reconciliation" means resolving merge conflicts in XML every time someone clicks a button in Setup. An LLM like Claude could probably handle the conflict resolution with enough repo context, but it's not clean — you're essentially building a bespoke merge tool for a format that wasn't designed for diffing. Tools like Gearset and Copado exist because this problem is genuinely hard to solve well with native Salesforce tooling alone.

## See Also

- **[LEARNINGS.md](LEARNINGS.md)** — Detailed gotchas discovered during the spike (XML quirks, deploy behavior, managed package issues, Apex testing pitfalls)
- **[PLAN.md](PLAN.md)** — What we planned vs. what we actually got to
- **[salesforce-metadata-poc-brief.md](salesforce-metadata-poc-brief.md)** — The original spike spec
- **[.research/](.research/)** — Integration research for Gong, Apollo, LinkedIn Sales Navigator, Outreach
