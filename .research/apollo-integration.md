# Apollo.io Salesforce Integration: Metadata Impact Analysis

Research date: 2026-03-06

## Summary

Apollo.io's Salesforce integration is **primarily API-based** (OAuth). It does **not** install a traditional managed package with a namespace prefix. There is an optional "Apollo Connector" AppExchange listing, but the core integration works through OAuth authentication and Salesforce's standard APIs. The metadata footprint is minimal and mostly **user-driven** (you choose which custom fields to create), not automatically imposed by Apollo.

---

## 1. Managed Package / AppExchange Presence

**No traditional managed package with a namespace prefix.** Apollo does have an "Apollo Connector" listing on AppExchange, but based on all available documentation, this appears to be a connected app registration rather than a managed package that installs custom objects, Apex classes, or triggers.

- No namespace prefix (e.g., no `apollo__` prefixed fields or objects)
- No evidence of installed Apex triggers, classes, or flows
- The AppExchange listing primarily facilitates the OAuth connected app authorization

This is fundamentally different from tools like Pardot (`pardot__`), Conga (`APXTConga4__`), or nCino (`nCino__`) that ship heavy managed packages.

## 2. How the Integration Works

Apollo connects via **OAuth 2.0** tied to a dedicated Salesforce integration user. The architecture:

1. **Authentication**: OAuth-based connected app. Apollo's integration user needs read/write permissions on synced objects and fields.
2. **Data sync**: Apollo reads/writes data through the Salesforce REST/SOAP API using standard and custom field API names.
3. **No server-side code**: Apollo does not install triggers, flows, process builders, or Apex in your org. All logic runs on Apollo's servers.
4. **Dynamic IPs**: Apollo does not support fixed IP ranges; their IPs are dynamic.

### Objects Apollo Reads/Writes (via API)

| Object | Read | Write | Notes |
|--------|------|-------|-------|
| Lead | Yes | Yes | Creates new Leads when pushing prospects |
| Contact | Yes | Yes | Creates new Contacts when pushing prospects |
| Account | Yes | Yes | Creates/updates Accounts |
| Opportunity | Yes | Yes | Bidirectional deal sync |
| Task | No | Yes | Logs emails, calls, meetings as Activities |
| Event | No | Yes | Logs meetings/calendar events |

Apollo operates on **standard objects only**. Custom objects are not supported by the native connector.

## 3. Custom Fields: What Gets Created and By Whom

**Apollo does not auto-create custom fields in Salesforce.** The field creation is a manual, user-driven process:

- Apollo maps to **existing standard fields** by default (First Name, Last Name, Email, Title, Phone, Company, Address, Owner, etc.)
- If you want to sync Apollo-specific data (e.g., Apollo enrichment data, sequences, intent signals), **you** create custom fields in Salesforce and then map them in Apollo's field mapping UI
- Apollo's docs state: "you need to create a custom field in Salesforce and then link that field to a custom field in Apollo"

### Typical Custom Fields Teams Create (Optional, Not Auto-Installed)

These are fields teams commonly add manually to support Apollo workflows:

**On Lead/Contact:**
- Apollo enrichment fields (e.g., `Apollo_Source__c`, `Apollo_Sequence__c`)
- Technology/intent data fields
- Any custom fields you want to sync bidirectionally

**On Account:**
- Enrichment fields (employee count, technologies, etc.)

**Key point**: None of these are required. The default mapping uses only standard Salesforce fields. Custom fields are added at the team's discretion.

### Auto-Created Custom Fields in Apollo (Not Salesforce)

If CRM fields don't have a corresponding Apollo field, **Apollo automatically creates a custom field in Apollo** (not in Salesforce) during field mapping. This is the reverse direction and has no Salesforce metadata impact.

## 4. Optional: Visualforce iFrame Component

Apollo offers an optional Visualforce page that embeds Apollo's prospecting UI inside Salesforce Account pages. This is **manually created** by an admin, not auto-installed:

### Setup Steps

1. Create a Visualforce Page named "Apollo" with this markup:
   ```xml
   <apex:page standardController="Account">
     <apex:iframe src="https://app.apollo.io/#/embedded-crm/account?crm_object_id={!account.id}"/>
   </apex:page>
   ```
2. Edit the Account Lightning page layout
3. Add a custom tab, drag in a Visualforce component, select the Apollo page
4. Set height to 450, save

### Metadata Created

- `pages/Apollo.page` (Visualforce Page)
- `pages/Apollo.page-meta.xml`
- Lightning page layout change (FlexiPage) for Account

## 5. Setup Steps (Complete Flow)

1. **In Salesforce**: Ensure OAuth username-password flows are allowed (Setup > OAuth and OpenID Connect Settings)
2. **In Apollo**: Settings > Integrations > Salesforce > Connect
3. **Authorize**: Enter Salesforce credentials, authorize the OAuth connection
4. **6-hour config window** (paid plans): After enabling, you have 6 hours to configure before sync begins
5. **Configure Push Settings**: Choose whether Apollo creates Leads or Contacts, enable Account/Activity sync
6. **Configure Pull Settings**: Apollo pulls existing Contacts, Accounts, Deals from Salesforce
7. **Map Fields**: Map Apollo's default fields to Salesforce fields, add custom mappings as needed
8. **Map Stages**: Apollo auto-reads Opportunity stages from Salesforce (does not create/modify stages)
9. **Set Team Sync Credentials**: Assign a Salesforce user with admin-level read/write permissions
10. **(Optional)**: Create the Visualforce iFrame page for embedded Apollo on Account pages

## 6. What Shows Up in `sf project retrieve`

### Almost Nothing (by default)

Since Apollo works via API and OAuth, a vanilla Apollo integration adds **zero retrievable metadata** to your org. There is no package to retrieve.

### What MIGHT show up (if team configures optional components)

| Metadata Type | When It Appears | Example |
|---------------|----------------|---------|
| CustomField | Only if team manually creates custom fields for Apollo mapping | `Lead.Apollo_Source__c` |
| ApexPage | Only if team creates the Visualforce iFrame | `pages/Apollo.page` |
| FlexiPage | Only if team modifies Account page layout for Visualforce embed | `flexipages/Account_Record_Page.flexipage` |
| ConnectedApp | The OAuth connected app registration may appear | Unlikely to be in your source — managed by Apollo |

### What Will NOT Show Up

- No custom objects
- No Apex classes or triggers
- No flows or process builders
- No permission sets (beyond what you create yourself)
- No Lightning Web Components
- No managed package metadata (no namespace prefix)

## 7. CI/CD Implications

### Low Impact

Apollo is one of the **least intrusive** sales tools from a Salesforce metadata perspective. The CI/CD implications are:

1. **No package version tracking needed**: Unlike managed packages, there's no version to pin or track in `sfdx-project.json`
2. **Custom fields are yours**: Any custom fields created for Apollo mapping are your own unmanaged metadata. They should be committed to the repo like any other custom field.
3. **Visualforce page (if used)**: Should be committed to the repo if the team creates it.
4. **No deployment dependencies**: Apollo does not create dependencies that could break deployments.
5. **Connected App**: The OAuth connected app is registered on Apollo's side. You may see a Connected App reference in your org, but it's typically not something you'd source-control.
6. **Field-level security**: If you create custom fields for Apollo, their FLS settings on profiles/permission sets should be tracked in source.

### Recommended Approach

- Track any custom fields created for Apollo in your repo (they're just standard custom field metadata)
- Track the Visualforce page if one is created
- No need for a package dependency or special handling
- Document which fields are "Apollo fields" via field descriptions or a naming convention (e.g., prefix with `Apollo_`)

## Sources

- [Integrate Salesforce with Apollo (Official Docs)](https://knowledge.apollo.io/hc/en-us/articles/4414356051725-Integrate-Salesforce-with-Apollo)
- [Important Information about the Salesforce Integration](https://knowledge.apollo.io/hc/en-us/articles/7525314188173-Important-Information-about-the-Salesforce-Integration)
- [Map Default Apollo Fields to Salesforce](https://knowledge.apollo.io/hc/en-us/articles/7699404190221-Map-Default-Apollo-Fields-to-Salesforce)
- [Follow Apollo's Recommended Default Field Mapping](https://knowledge.apollo.io/hc/en-us/articles/20336914916365-Follow-Apollo-s-Recommended-Default-Field-Mapping)
- [Link Custom Salesforce Fields to Custom Apollo Fields](https://knowledge.apollo.io/hc/en-us/articles/4412668190733-Link-Custom-Salesforce-Fields-to-Custom-Apollo-Fields)
- [Configure Salesforce Push Settings](https://knowledge.apollo.io/hc/en-us/articles/4414469523981-Configure-Salesforce-Push-Settings)
- [Configure Salesforce Pull Settings](https://knowledge.apollo.io/hc/en-us/articles/4414496822797-Configure-Salesforce-Pull-Settings)
- [Automatically Create and Map Stages Between Salesforce and Apollo](https://knowledge.apollo.io/hc/en-us/articles/4416454481805-Automatically-Create-and-Map-Stages-Between-Salesforce-and-Apollo)
- [Salesforce Section (Knowledge Base)](https://knowledge.apollo.io/hc/en-us/sections/4409216721549-Salesforce)
- [Apollo Release Notes 2025](https://knowledge.apollo.io/hc/en-us/articles/34072157047309-Release-Notes-2025)
