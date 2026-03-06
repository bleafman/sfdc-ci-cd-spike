# AppExchange Packages in Scratch Orgs: Research Findings

**Date:** 2026-03-06

---

## How to Install an AppExchange Package into a Scratch Org

### CLI Command

The primary command is:

```bash
sf package install --package <04t_PACKAGE_VERSION_ID> --target-org <scratch_org_alias> --wait 30
```

Key flags:
- `--package` (or `-p`): The subscriber package version ID (starts with `04t`)
- `--target-org` (or `-o`): Your scratch org alias or username
- `--wait` (or `-w`): Minutes to wait for installation to complete (default varies; 30 is safe)
- `--installation-key` (or `-k`): Required if the package has an installation password
- `--no-prompt`: Skip confirmation prompts (useful in CI)

Legacy equivalent (still works in many guides):
```bash
sfdx force:package:install -p 04tXXXXXXXXXXXXXXX -u myScratchOrg -w 30
```

### Finding the 04t Package Version ID

The 04t ID (subscriber package version ID) is how you identify a specific version of a managed package. To find it:

1. **From AppExchange UI:** Go to the app listing, click "Get It Now", select "Install in Production" or "Install in Sandbox". The URL will contain the ID: `...installPackage.apexp?p0=04tXXXXXXXXXXXXXXX`
2. **From GitHub/docs:** Many open-source Salesforce packages publish their 04t IDs in their README or INSTALLATION.md
3. **From an installed org:** Go to Setup > Installed Packages, and the version ID is visible in the package details

### Scratch Org Definition Requirements

Managed packages may require specific features enabled in `project-scratch-def.json`. Example:

```json
{
  "orgName": "Package Testing Org",
  "edition": "Developer",
  "features": [
    "EnableSetPasswordInApi"
  ],
  "settings": {
    "lightningExperienceSettings": {
      "enableS1DesktopEnabled": true
    }
  }
}
```

Common features that packages may need:
- `Communities` (for Experience Cloud packages)
- `ServiceCloud` (for service-related packages)
- `CPQ` (for Salesforce CPQ)
- `MaxApexCodeSize:10` (if package has lots of Apex)

Best practice: only add features that are absolutely required to avoid introducing accidental dependencies on paid or uncommon Salesforce features.

### Alternative: installedPackages Directory

You can also pre-declare packages in your SFDX project:

1. Create `force-app/main/default/installedPackages/`
2. Add a file named `NAMESPACE.installedPackage` with content like:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<InstalledPackage xmlns="http://soap.sforce.com/2006/04/metadata">
    <versionNumber>4.0</versionNumber>
</InstalledPackage>
```

Or declare dependencies in `sfdx-project.json`:
```json
{
  "packageDirectories": [{
    "path": "force-app",
    "default": true,
    "dependencies": [
      { "subscriberPackageVersionId": "04tXXXXXXXXXXXXXXX" }
    ]
  }]
}
```

---

## What Metadata Do Managed Packages Typically Add?

When a managed package installs, it can create any of the following (all namespaced):

| Metadata Type | Example | Notes |
|---|---|---|
| Custom Objects | `LeanData__Log__c` | Full object definitions with fields |
| Custom Fields | `Account.DLRS__RollupField__c` | On standard or custom objects |
| Custom Tabs | Tabs for custom objects | |
| Permission Sets | Package-specific permission sets | Best practice over profiles |
| Flows | Packaged flows and process builders | |
| Apex Classes/Triggers | Namespaced Apex code | Protected; cannot be modified |
| Lightning Components | Aura and LWC components | |
| Custom Metadata Types | Configuration records + schema | Records deploy with the package |
| Page Layouts | For custom objects | |
| Reports & Dashboards | Pre-built analytics | |
| Custom Settings | Org-wide or user-level config | |
| Custom Labels | | |
| Static Resources | | |
| Remote Site Settings | For callouts | |

Key distinction: Custom Objects deploy schema only (no data records). Custom Metadata Types deploy both schema and records.

---

## Name-Brand Sales/Marketing Apps: Scratch Org Viability

### The Bad News

Most name-brand sales engagement tools (Outreach, Salesloft, Gong, Apollo, Clay, Drift/Qualified) are **not practical** for this use case:

| App | AppExchange? | Free Install? | Scratch Org? | Verdict |
|---|---|---|---|---|
| **Outreach** | No native package | No | N/A | Not an AppExchange managed package |
| **Apollo** | No native package | No | N/A | Integration-only, no managed package |
| **Clay** | No | No | N/A | No Salesforce package at all |
| **Gong** | Yes (listed at $1) | Technically yes | Unclear | Requires Gong subscription; lightweight metadata |
| **Salesloft** | Limited | No free tier | Unclear | Requires license |
| **ZoomInfo** | Yes | No | Possibly | Requires ZoomInfo subscription |
| **Clearbit** | Deprecated | N/A | N/A | Acquired by HubSpot |
| **LeanData** | Yes (managed pkg) | No free tier | Possibly | Requires sales contact; creates substantial metadata |
| **Drift** | Rebranded to Qualified | No | N/A | Not straightforward |
| **Chorus** | Acquired by ZoomInfo | N/A | N/A | Folded into ZoomInfo |

**LeanData** is the most interesting of these -- it's a proper managed package that creates custom objects (e.g., `LeanData__Log__c`), fields on standard objects, and runs indexing jobs. But it requires a paid license or sales conversation.

**Gong** lists as $1 on AppExchange (the minimum allowed) but the Salesforce package is lightweight -- the real functionality lives in Gong's cloud. It won't create much interesting metadata.

### Bottom Line

For testing metadata impact from a third-party package without procurement friction, the name-brand sales tools are largely off the table. The practical path is free packages that happen to have rich metadata footprints.

---

## Recommended Free Packages for Testing Metadata Impact

### Tier 1: Best Candidates (Rich Metadata, Free, Scratch Org Compatible)

#### 1. Salesforce Labs - Action Plans V4
- **Publisher:** Salesforce Labs (by Salesforce employees)
- **Cost:** Free
- **AppExchange:** [Action Plans V4](https://appexchange.salesforce.com/appxListingDetail?listingId=a0N4V00000Gg6NVUAZ)
- **GitHub:** [SalesforceLabs/ActionPlansV4](https://github.com/SalesforceLabs/ActionPlansV4)
- **Scratch org support:** Explicitly documented in INSTALLATION.md
- **Metadata created:** Custom objects (Action Plan, Action Plan Template, AP Task, AP Template Task), custom fields, permission sets, Lightning components, Apex classes/triggers
- **Why it's good:** Open-source, well-documented, explicitly supports scratch org installation, creates multiple custom objects with relationships

#### 2. Declarative Lookup Rollup Summaries (DLRS)
- **Publisher:** Salesforce.org Community (open source)
- **Cost:** Free
- **AppExchange:** [DLRS](https://appexchange.salesforce.com/appxListingDetail?listingId=a0N3000000B45gWEAR)
- **Install:** [install.salesforce.org/products/dlrs](https://install.salesforce.org/products/dlrs)
- **GitHub:** [SFDO-Community/declarative-lookup-rollup-summaries](https://github.com/SFDO-Community/declarative-lookup-rollup-summaries)
- **Metadata created:** Custom metadata types (for rollup definitions), permission sets, Apex classes/triggers, custom settings, scheduled jobs infrastructure
- **Why it's good:** Widely used (one of the most popular free apps), passed security review, uses Custom Metadata Types (which means rollup configs deploy as metadata), managed package with namespace

#### 3. Salesforce Labs - Adoption Dashboards
- **Publisher:** Salesforce Labs
- **Cost:** Free
- **AppExchange:** [Adoption Dashboards](https://appexchange.salesforce.com/appxListingDetail?listingId=a0N30000004gHhLEAU)
- **Metadata created:** 42 reports, 6 custom fields, 3 dashboards, dedicated folders for dashboards and reports
- **Why it's good:** Substantial report/dashboard metadata, custom formula fields on standard objects. Good for testing how installed reports and dashboards appear in metadata

#### 4. Salesforce Labs - Record Hunter
- **Publisher:** Salesforce Labs
- **Cost:** Free
- **AppExchange:** Listed in Salesforce Labs collection
- **Metadata created:** Lightning components, custom objects for search configuration, permission sets
- **Why it's good:** Adds Lightning component metadata and custom objects

### Tier 2: Also Worth Considering

#### 5. Rollup Helper (Free Edition)
- **Publisher:** Passage Technology
- **Cost:** Free (limited to 3 rollups; paid tiers exist)
- **AppExchange:** [Rollup Helper](https://appexchange.salesforce.com/appxListingDetail?listingId=a0N30000009i3UpEAI)
- **Metadata created:** Custom fields (uses regular custom fields instead of rollup summary fields), custom objects, triggers on standard objects
- **Why it's good:** Creates real custom fields on your objects as part of its operation; widely installed (30,000+ orgs)

#### 6. Nonprofit Success Pack (NPSP)
- **Publisher:** Salesforce.org
- **Cost:** Free
- **Metadata created:** Massive -- 6+ interdependent packages, many custom objects, fields, flows, reports, dashboards
- **Scratch org support:** Supported via CumulusCI framework
- **Why it's good:** Heaviest metadata footprint of any free package
- **Caveat:** Complex -- installs 6 separate packages with dependencies. Use CumulusCI for scratch org setup (`cci task run update_dependencies`). May be overkill for a CI/CD test scenario

#### 7. Salesforce CPQ (Steelbrick)
- **Publisher:** Salesforce
- **Cost:** Requires CPQ license (not free)
- **04t example:** `04t61000000xAgoAAE` (older version)
- **Scratch org feature:** Add `"CPQ"` to features in scratch org def
- **Why it's interesting:** Creates massive metadata (100+ custom objects). But requires a license, so not viable without one

---

## Practical Recommendation for This Project

For the CI/CD POC, the best approach is:

### Start with Action Plans V4

1. It's explicitly built for scratch org installation
2. It's open-source on GitHub with clear install instructions
3. It creates a meaningful set of custom objects, fields, and Apex
4. It's made by Salesforce Labs, so it's trustworthy and stable

### Installation Steps

```bash
# 1. Find the current 04t ID from the AppExchange listing or GitHub releases
#    (Go to the listing, click Get It Now, grab the 04t from the install URL)

# 2. Create scratch org with appropriate features
sf org create scratch -f config/project-scratch-def.json -a pkg-test -d 7

# 3. Install the managed package
sf package install --package 04tXXXXXXXXXXXXXXX --target-org pkg-test --wait 30 --no-prompt

# 4. Verify installation
sf org open --target-org pkg-test
# Go to Setup > Installed Packages to confirm

# 5. Pull metadata to see what was installed
sf project retrieve start --target-org pkg-test
# Installed managed package metadata will appear with namespace prefix
```

### Then Layer On DLRS

Same process, second package. This gives you two different packages with different metadata patterns (custom objects vs custom metadata types) to test CI/CD behavior with.

### What to Look For in CI/CD Testing

After installing packages into a scratch org:
- Managed package metadata is **namespaced** (e.g., `ActionPlans__ActionPlan__c`)
- You generally **cannot modify** managed package components directly
- Your own metadata may **reference** managed package components (e.g., a flow that references a packaged object)
- Package metadata shows up in `sf project retrieve start` output but is typically excluded from version control via `.forceignore`
- Understanding how your CI/CD pipeline handles the boundary between "our metadata" and "installed package metadata" is the key insight

---

## Key Takeaways

1. **Any managed package can be installed via CLI** using `sf package install --package 04t...` -- you just need the version ID
2. **Scratch org definition may need features** enabled depending on what the package requires
3. **Name-brand sales tools mostly require paid licenses** and aren't practical for free testing
4. **Salesforce Labs apps are the sweet spot** -- free, well-built, substantial metadata, often with explicit scratch org support
5. **Action Plans V4 + DLRS** is the recommended combo for testing metadata impact in a CI/CD POC
6. **NPSP is the nuclear option** -- massive metadata footprint but complex multi-package installation

---

## Sources

- [Install Packages with the CLI - Salesforce Docs](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_unlocked_pkg_install_pkg_cli.htm)
- [Action Plans V4 - GitHub](https://github.com/SalesforceLabs/ActionPlansV4)
- [Action Plans V4 - AppExchange](https://appexchange.salesforce.com/appxListingDetail?listingId=a0N4V00000Gg6NVUAZ)
- [DLRS - AppExchange](https://appexchange.salesforce.com/appxListingDetail?listingId=a0N3000000B45gWEAR)
- [DLRS - Install via MetaDeploy](https://install.salesforce.org/products/dlrs)
- [DLRS - GitHub](https://github.com/SFDO-Community/declarative-lookup-rollup-summaries)
- [Salesforce Adoption Dashboards - AppExchange](https://appexchange.salesforce.com/appxListingDetail?listingId=a0N30000004gHhLEAU)
- [Install Managed Package in Scratch Org - Jitendra Zaa](https://www.jitendrazaa.com/blog/salesforce/install-manage-package-in-scratch-org-using-salesforce-dx/)
- [Scratch Org Features - Salesforce Docs](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_scratch_orgs_def_file_config_values.htm)
- [Salesforce Labs Collection - AppExchange](https://appexchange.salesforce.com/mktcollections/curated/salesforcelabsforce)
- [What Is Salesforce Labs? - Salesforce Ben](https://www.salesforceben.com/what-is-salesforce-labs/)
- [Create Scratch Org with AppExchange Apps - Developer Community](https://developer.salesforce.com/forums/?id=9062I000000DLIPQA4)
- [LeanData Managed App Install Guide](https://leandatahelp.zendesk.com/hc/en-us/articles/360016337994-LeanData-Managed-App-Install-Guide)
- [NPSP Scratch Org Setup](https://salesforcecodes.blogspot.com/2020/04/how-to-create-scratch-org-with-non.html)
- [Salesforce CPQ Scratch Org Install](http://sfdctuner.blogspot.com/2018/02/scratch-org-and-installing-cpq-package.html)
- [Get Started with Modern AppExchange Development - Salesforce Blog](https://developer.salesforce.com/blogs/2024/11/get-started-with-modern-appexchange-development)
- [Rollup Helper - AppExchange](https://appexchange.salesforce.com/appxListingDetail?listingId=a0N30000009i3UpEAI)
