# Gong.io Salesforce Integration: Metadata Impact Research

Research date: 2026-03-06

## Overview

Gong's Salesforce integration has **two distinct parts** that affect your org differently:

1. **CRM Connection** (API-level integration) -- connects Gong to Salesforce via OAuth for reading/writing standard object data
2. **Gong for Salesforce** (managed package from AppExchange) -- installs custom objects, flows, canvas apps, permission sets, reports, and dashboards into the org

You can use the CRM connection without the managed package. The managed package provides the richer in-Salesforce experience (viewing call data, transcripts, etc. inside Salesforce).

---

## 1. Managed Package on AppExchange

**Yes**, Gong has a managed package: [Gong.io on AppExchange](https://appexchange.salesforce.com/appxListingDetail?listingId=a0N3A00000FeGgcUAF)

- Listed as "Gong.io | The Revenue Intelligence Platform"
- Free app, requires Salesforce Enterprise edition or higher
- It is a **first-generation managed package** (1GP)

### Namespace Prefix

The exact namespace prefix is not published in Gong's public documentation. It would be visible in Setup > Installed Packages after installation. Based on typical patterns for Gong objects/fields referenced in documentation (e.g., the Conversation object and its child objects), the namespace prefix is applied to all package-owned custom objects and fields. You would see it as `<namespace>__Conversation__c`, `<namespace>__Participant__c`, etc.

**Action item**: If you install the package in a sandbox, check Setup > Installed Packages to confirm the exact namespace. The prefix will be visible on every managed object/field API name.

---

## 2. Custom Fields on Standard Objects

Gong creates custom fields on standard Salesforce objects in two ways:

### Managed Package Fields (auto-created on install)

The package requires **at least 3 free custom field slots**:
- **Opportunity**: 2 custom fields
- **Account**: 1 custom field

These are created automatically when the managed package is installed. Because they come from a managed package, they carry the namespace prefix.

### Unmanaged Custom Fields (for task/event export)

When you configure Gong to export activities as Salesforce Tasks, additional **unmanaged** custom fields may need to be created on the Task (or Event) object:

| Field API Name | Object | Purpose |
|---|---|---|
| `Gong_Associated_Opportunities__c` | Task | Lists opportunities linked to the activity |
| `Gong_Participants__c` | Task | Lists contacts associated with the activity |
| `Gong_Associated_Accounts__c` | Task | Lists associated accounts |

These can be created automatically by the managed package installer OR manually by an admin. If created by the package, they carry the namespace prefix. If created manually, they are unmanaged org-owned fields.

### Engage (Flows/Sequences) Fields

If you use Gong Engage, additional custom fields are installed on:
- **Lead** object
- **Contact** object

These track flow/sequence enrollment status in the CRM.

---

## 3. Custom Objects, Flows, Triggers, and Other Metadata

### Custom Objects (all namespaced, from managed package)

The managed package installs a full relational data model:

**Parent object:**
- **Conversation** -- main object; contains call title, date, duration, scope, AI-generated summaries, call brief, call highlights, key points

**Child objects** (one-to-many relationship with Conversation):
- **Participant** -- call participants (attended and invited-but-absent)
- **Tracker** -- smart tracker keyword/phrase matches
- **Topic** -- detected conversation topics
- **Note** -- call notes
- **Invitee** -- calendar invitees
- **Structure** -- call structure segments
- **Interaction Stats** -- talk ratios, engagement metrics
- **Related Account** -- junction to Account
- **Related Contact** -- junction to Contact
- **Related Lead** -- junction to Lead
- **Related Opportunity** -- junction to Opportunity

A single new Conversation record triggers creation of **~25-40 child records**.

### Apex Triggers

The package includes triggers -- notably, when a new Conversation record is created, a trigger parses JSON data from custom fields on the Conversation object and creates the child records (Participants, Trackers, Topics, etc.).

### Flows (Record-Triggered, shipped inactive)

The managed package includes **built-in flows as templates** (installed inactive, you activate what you need):

| Flow | Trigger | Purpose |
|---|---|---|
| Gong for Salesforce - Create Contact Role | New Participant record created | Identifies conversation participants who are Contacts in SF and adds them as Opportunity Contact Roles |
| Gong for Salesforce - Create Event | New Conversation record created | Creates a Salesforce Event with call details |

### Canvas App

- **Gong Deals Canvas App** -- displays call highlights and transcripts inline within Salesforce record pages. Requires Connected App OAuth policy configuration (Admin approved users are pre-authorized).

### Permission Sets

- **Gong Users** -- end-user access to Conversation object and all child objects
- **Gong API User (Salesforce Integration License)** -- for the dedicated integration user

### Reports and Dashboards

- Preset reports and dashboards for rep performance analysis, shipped with the package.

### Connected Apps

Two connected apps are registered (these show up in Setup > Connected Apps):
- **Gong Integration App** -- used for data ingest, enrichment, and the main Salesforce integration connection
- **Gong.io user connection** -- manages individual user connections for Deal Boards and Engage

---

## 4. Setup Steps

### Part A: CRM Connection (API integration)

1. In Gong admin: Settings > Integrations > Salesforce
2. Create a **dedicated integration user** in Salesforce with appropriate permissions
3. Click Connect; OAuth flow authenticates against Salesforce
4. Gong stores only the OAuth token (no credentials)
5. Configure **data import**: select which SF fields (standard + custom) on Account, Opportunity, Lead, Contact to sync into Gong
6. Configure **data export**: choose whether to push call logs as Tasks or Events back to Salesforce
7. Grant the integration user read access to: Lead, Contact, Account, Opportunity, OpportunityHistory, FieldHistory, Task, Organization (and write access for export)

### Part B: Managed Package Installation

1. Go to [Gong.io on AppExchange](https://appexchange.salesforce.com/appxListingDetail?listingId=a0N3A00000FeGgcUAF)
2. Click "Get It Now" (production) or "Try It Free" (sandbox)
3. Select "Install for All Users" and click Install
4. **Post-install configuration:**
   - Assign the **Gong Users** permission set to relevant users
   - Configure the **Gong Deals Canvas App** connected app: set OAuth Policies > Permitted Users to "Admin approved users are pre-authorized," then assign profiles
   - Add Gong Lightning components to relevant page layouts (Opportunity, Account, etc.)
   - Activate desired built-in flows (Contact Role creation, Event creation)
   - Add custom fields to Task/Event page layouts if using activity export

### References

- [Install Gong for Salesforce](https://help.gong.io/docs/install-gong-for-salesforce)
- [Connect Gong to Salesforce](https://help.gong.io/docs/connect-gong-to-salesforce)
- [Post installation configurations](https://help.gong.io/docs/post-installation-configurations)
- [Configure Gong for Salesforce](https://help.gong.io/docs/configure-gong-for-salesforce)
- [Set up Salesforce custom fields](https://help.gong.io/docs/set-up-salesforce-custom-fields)

---

## 5. API vs. Schema Modification

Gong does **both**:

### API-level (CRM Connection)
- **Reads** standard fields via REST API: Account, Contact, Lead, Opportunity, Task, OpportunityHistory, FieldHistory, Organization
- **Writes** Tasks or Events when exporting call activity data
- Reads whatever custom fields you configure for import
- This part does **not modify the org's schema** -- it only reads/writes data through standard APIs

### Schema modification (Managed Package)
- Installs 10+ custom objects with the package namespace
- Installs Apex triggers and classes
- Installs flows (inactive by default)
- Installs permission sets, canvas app, reports, dashboards
- May create custom fields on Opportunity, Account, Task, Lead, Contact

---

## 6. What Shows Up in `sf project retrieve`

### Managed package metadata (namespaced -- generally NOT retrieved)

By default, `sf project retrieve start` does **not** retrieve managed package components. The ~10+ custom objects, their fields, triggers, flows, Apex classes, permission sets, reports, and dashboards all live under Gong's namespace and are managed by Gong's package versioning. They would only appear if you explicitly retrieve by package name:

```bash
sf project retrieve start --package-name "Gong for Salesforce"
```

Even then, managed package source is read-only and not deployable -- you cannot modify or redeploy it.

### What DOES show up (unmanaged, org-owned changes)

These are the CI/CD-relevant metadata changes that would appear in your source repo after connecting Gong:

| Metadata Type | What Changed | Why |
|---|---|---|
| **Page Layouts** | `Opportunity-Opportunity Layout.layout-meta.xml`, `Account-Account Layout.layout-meta.xml`, etc. | If you add Gong Lightning components or namespaced fields to page layouts |
| **Custom Fields** | `Task.Gong_Associated_Opportunities__c`, `Task.Gong_Participants__c`, `Task.Gong_Associated_Accounts__c` | If manually created (unmanaged) for activity export |
| **Profiles / Permission Set Assignments** | Profile XML changes | If you modify profiles to grant access to Gong objects |
| **Connected App configurations** | Possibly connected app OAuth policy settings | If tracked in your org's metadata |
| **Lightning Record Pages (FlexiPages)** | `*.flexipage-meta.xml` | If you embed Gong canvas app or Lightning components on record pages |
| **Lightning App Pages** | App page configurations | If you add Gong tabs to apps |

### What does NOT show up

- All namespaced objects (`<ns>__Conversation__c`, `<ns>__Participant__c`, etc.) -- managed, not retrievable as source
- Apex triggers/classes from the package -- managed
- Package flows -- managed
- Package permission sets -- managed (though assignments to profiles do show up)
- Package reports/dashboards -- managed

---

## CI/CD Implications Summary

1. **The managed package itself is not source-trackable.** Install it manually or via script (`sf package install`) in each environment. It should be part of your environment setup runbook, not your source repo.

2. **Page layout changes are the biggest impact.** When someone adds Gong components to layouts in production, those layout XML changes need to be retrieved and committed. This is the most common "drift" from a Gong install.

3. **Manually-created custom fields** (for Task export) are unmanaged and should be committed to the repo if you create them.

4. **FlexiPage changes** from embedding Gong Lightning components need to be tracked.

5. **Profile/PermissionSet changes** granting access to Gong objects should be tracked.

6. **Connected App OAuth policies** are org-level config that may or may not be in your metadata tracking depending on your `package.xml` manifest.

7. **Recommended approach for the repo:**
   - Add a comment in `sfdx-project.json` or a runbook noting the Gong package dependency
   - Track page layouts, flexipages, profiles, and any manually-created custom fields
   - Use `sf package install` in your CI/CD pipeline to install the Gong managed package before deploying your source
   - Consider using `.forceignore` patterns if Gong-namespaced metadata leaks into retrieves

---

## Sources

- [Install Gong for Salesforce](https://help.gong.io/docs/install-gong-for-salesforce)
- [Connect Gong to Salesforce](https://help.gong.io/docs/connect-gong-to-salesforce)
- [Gong for Salesforce app object fields](https://help.gong.io/docs/gong-for-salesforce-app-object-fields)
- [Data model & structure](https://help.gong.io/docs/data-model-structure)
- [Set up Salesforce custom fields](https://help.gong.io/docs/set-up-salesforce-custom-fields)
- [Objects and fields Gong needs access to](https://help.gong.io/docs/salesforce-fields-the-integration-user-needs-access-to)
- [Built-in flows to enrich your Gong data in Salesforce](https://help.gong.io/docs/built-in-flows-to-enrich-your-gong-data-in-salesforce)
- [FAQs for Salesforce integration](https://help.gong.io/docs/faqs-for-salesforce-integration)
- [Post installation configurations](https://help.gong.io/docs/post-installation-configurations)
- [Configure Gong for Salesforce](https://help.gong.io/docs/configure-gong-for-salesforce)
- [What's new in Gong for Salesforce](https://help.gong.io/docs/whats-new-in-gong-for-salesforce)
- [Gong.io on AppExchange](https://appexchange.salesforce.com/appxListingDetail?listingId=a0N3A00000FeGgcUAF)
