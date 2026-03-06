# Outreach.io Salesforce Integration: Metadata Impact and CI/CD Implications

Research date: 2026-03-06

## TL;DR

Outreach does **not** have a managed package on AppExchange. The core integration is API-only via OAuth, meaning it reads/writes standard Salesforce objects through REST API without modifying your org's schema. However, Outreach provides an **optional unmanaged package** that installs custom fields, Flow Builder automations, and reports into your org. That unmanaged package is where the CI/CD implications live.

---

## 1. Managed Package / AppExchange Presence

**Outreach does not have a managed package on AppExchange.** There is no namespace prefix.

The integration is configured entirely from within Outreach's admin settings (Settings > System Configuration > Plugins > Add > Salesforce). Authentication uses OAuth 2.0 -- the connecting user authorizes Outreach to access Salesforce REST APIs.

There is an Outreach marketplace listing at `marketplace.outreach.io/apps/salesforce` but this is Outreach's own marketplace, not Salesforce AppExchange.

## 2. Core Integration: API-Only (No Schema Changes)

The base Outreach-Salesforce connection is purely API-based:

- **Protocol:** Salesforce REST API with OAuth 2.0 authentication
- **Sync method:** Bi-directional polling, pulling updates every ~10 minutes by default
- **Objects touched:** Accounts, Contacts, Leads, Opportunities, Tasks/Events, User Roles
- **Schema impact:** None. The core plugin reads and writes to existing standard and custom fields. It does not create fields, objects, or automations on its own.

The connecting user needs a profile with "API Enabled" under System Permissions. Salesforce Enterprise/Unlimited editions include REST API access; Professional Edition requires the Web API Package add-on.

## 3. Optional Unmanaged Package: "Last Touch Sequence Attribution"

This is where schema changes happen. Outreach provides an **unmanaged package** that admins can optionally install. It is sometimes called the "Engagement Panel & Sequence Attribution Package."

### What it installs

**29 custom fields total:**
- 12 fields on **Lead**
- 12 fields on **Contact**
- 4 fields on **Opportunity**
- 1 field on **Activity** (Task/Event)

All fields use the API name prefix `outreach_`. Key fields include:

| Outreach Field | API Name Pattern | Objects |
|---|---|---|
| Current Sequence Name | `outreach_current_sequence_name__c` | Lead, Contact |
| Finished Sequences | `outreach_finished_sequences__c` | Lead, Contact |
| Actively Being Sequenced | `outreach_actively_being_sequenced__c` | Lead, Contact |
| Sequence State/Status | `outreach_sequence_state__c` | Lead, Contact |
| Sequence Step Type | `outreach_sequence_step_type__c` | Lead, Contact |
| Step Due Date | `outreach_step_due_date__c` | Lead, Contact |
| Sequence Owner | `outreach_sequence_owner__c` | Lead, Contact |
| Last Touch Sequence fields | `outreach_last_touch_*__c` | Opportunity |
| Date Added to Sequence | `outreach_date_added_to_sequence__c` | Lead, Contact |

(Note: Exact API names may vary slightly. The `outreach_` prefix is consistent. Since this is an unmanaged package, field names become regular custom fields in your org -- no namespace prefix.)

**4 Flow Builder automations:**
- Outreach - Update Last Touch Field (No Contact Role)
- Outreach - Update Last Touch + Finished Sequence Fields
- Outreach - Fill/Update Date Added to Sequence (Contacts)
- Outreach - Fill/Update Date Added to Sequence (Leads)

**1 Report Folder** named "Outreach" containing 3 pre-configured reports.

### Important: Unmanaged = Your Responsibility

Because this is an unmanaged package (not managed), once installed:
- The components become regular org metadata with no namespace
- Outreach cannot push updates to them
- You own them completely, like any other custom field or flow
- They must be tracked in version control like any other metadata

## 4. Activity/Task Logging

Even without the unmanaged package, Outreach creates **Task records** in Salesforce via API when reps perform actions:

- Emails sent/received get logged as Tasks
- Calls get logged as Tasks (with call duration, recording links if configured)
- Tasks have an `[Outreach]` tag in the Subject line by default
- Subject line format is customizable by admins

This uses **standard Task fields** -- no custom fields required. However, with "Advanced Task Mapping" enabled, Outreach can populate additional detail (call duration, sequence name, email opens) which may require custom fields that the admin creates manually.

## 5. Setup Steps (Summary)

1. **In Outreach:** Settings > System Configuration > Plugins > Add > Select "Salesforce" (or "Salesforce Sandbox")
2. **Authenticate:** Log in with a Salesforce user that has API Enabled permission
3. **Configure field mappings:** In Outreach's CRM integration settings, map Outreach fields to Salesforce fields on each object (Lead, Contact, Account, Opportunity)
4. **Optionally install unmanaged package:** For the Engagement Panel and Sequence Attribution fields/flows
5. **Add Engagement Panel to page layouts:** Create a section on Lead/Contact layouts and add the `outreach_*` fields
6. **Configure sync settings:** Set sync direction (Outreach-to-SF, SF-to-Outreach, or bidirectional) per field, set sync frequency
7. **Enable Advanced Task Mapping** (optional): For granular activity logging to Task objects
8. **Test in sandbox first:** Outreach recommends connecting to a Salesforce Sandbox, syncing 20-30 test records before going to production

## 6. What Would Show Up in `sf project retrieve`

### If only the core API integration is connected (no unmanaged package):

**Nothing.** The integration is entirely external. Outreach reads/writes data through REST API using existing fields. No metadata changes occur in the org.

The only trace would be the Connected App / OAuth authorization, which may appear under Setup > Connected Apps > OAuth Usage but is not deployable metadata.

### If the unmanaged package is installed:

You would retrieve:

```
force-app/main/default/
  objects/
    Lead/
      fields/
        outreach_current_sequence_name__c.field-meta.xml
        outreach_finished_sequences__c.field-meta.xml
        outreach_actively_being_sequenced__c.field-meta.xml
        outreach_sequence_state__c.field-meta.xml
        outreach_step_due_date__c.field-meta.xml
        outreach_sequence_owner__c.field-meta.xml
        ... (12 fields total)
    Contact/
      fields/
        outreach_current_sequence_name__c.field-meta.xml
        outreach_finished_sequences__c.field-meta.xml
        ... (12 fields matching Lead)
    Opportunity/
      fields/
        outreach_last_touch_*__c.field-meta.xml
        ... (4 fields)
    Task/
      fields/
        outreach_*__c.field-meta.xml  (1 field)
  flows/
    Outreach_Update_Last_Touch_Field.flow-meta.xml
    Outreach_Update_Last_Touch_Finished_Sequence.flow-meta.xml
    Outreach_Date_Added_Contacts.flow-meta.xml
    Outreach_Date_Added_Leads.flow-meta.xml
  reports/
    Outreach/
      ... (3 report files)
  layouts/
    Lead-*.layout-meta.xml  (if Engagement Panel section was added)
    Contact-*.layout-meta.xml  (if Engagement Panel section was added)
```

### If admin manually created custom fields for Advanced Task Mapping:

Any manually created custom fields (for call duration, sequence name on tasks, etc.) would also appear. These would not have the `outreach_` prefix unless the admin chose to name them that way.

## 7. CI/CD Implications

### Low risk (API-only connection):
- The base integration creates zero metadata. Nothing to commit.
- Data changes (new Tasks, updated Lead fields) happen at the data layer, not the metadata layer.

### Medium risk (unmanaged package installed):
- **29 custom fields** across 4 objects must be committed to the repo
- **4 Flows** must be committed and tracked
- **3 Reports** in the Outreach folder
- **Page layout changes** if the Engagement Panel section was added
- Since unmanaged, there is no namespace -- these look like any other custom fields
- The `outreach_` prefix makes them easy to identify and filter

### Recommended approach:
1. Install the unmanaged package in a sandbox first
2. Retrieve the metadata: `sf project retrieve start -m CustomField:Lead.outreach_* -m CustomField:Contact.outreach_* -m CustomField:Opportunity.outreach_* -m CustomField:Task.outreach_* -m Flow:Outreach*`
3. Commit all retrieved metadata to the repo
4. Deploy through your normal CI/CD pipeline to other environments
5. Do NOT install the unmanaged package directly in production -- deploy from source control instead

### What to add to .gitignore or .forceignore:
Nothing specific needed. The `outreach_*` fields are regular custom fields and should be tracked.

### What to watch for:
- Admins modifying the Outreach flows directly in production (since they are unmanaged, there is no upgrade path -- changes must be pulled back to source)
- New custom fields created manually for Advanced Task Mapping that do not follow the `outreach_` naming convention
- Page layout drift if the Engagement Panel is added/modified in production outside of CI/CD

---

## Sources

- [Outreach & CRM Connection Overview (Official)](https://support.outreach.io/hc/en-us/articles/204659768-Outreach-CRM-Connection-Overview)
- [Salesforce Configuration for Outreach: End to End Guide (Official)](https://support.outreach.io/hc/en-us/articles/13056326486427-Salesforce-Configuration-for-Outreach-End-to-End-Guide-Best-Practice)
- [Last Touch Sequence Attribution Unmanaged Package Guide (Official)](https://support.outreach.io/hc/en-us/articles/360023687473-Last-Touch-Sequence-Attribution-Unmanaged-Package-Guide)
- [Last Touch Sequence Attribution Unmanaged Package FAQs (Official)](https://support.outreach.io/hc/en-us/articles/360026249254-Last-Touch-Sequence-Attribution-Unmanaged-Package-FAQs)
- [How To Map Outreach Engagement Fields (Official)](https://support.outreach.io/hc/en-us/articles/360048234774-How-To-Map-Outreach-Engagement-Fields-to-Corresponding-Salesforce-Fields)
- [Reporting Outreach Data in Salesforce (Official)](https://support.outreach.io/hc/en-us/articles/13256601055643-Reporting-Outreach-Data-in-Salesforce)
- [Standard Task Mapping Overview (Official)](https://support.outreach.io/hc/en-us/articles/216788418-Standard-Task-Mapping-Overview)
- [Outreach University: Installing the Engagement Panel Package](https://university.outreach.io/installing-the-engagement-panel-sequence-attribution-package-for-admins)
- [Outreach Marketplace: Salesforce](https://marketplace.outreach.io/apps/salesforce?store=public)
- [Acoustic Selling: Outreach Basic Unmanaged Package](https://www.acousticselling.com/blog/outreach-unmanaged-package)
- [Kicksaw: Integrating Outreach with Salesforce](https://www.kicksaw.com/resources/integrating-outreach-with-salesforce)
- [MassMailer: Outreach Salesforce Integration Guide 2025](https://massmailer.io/blog/outreach-salesforce-integration-guide/)
- [Lane Four: 5 Best Practices for Salesforce Integration in Outreach](https://lanefour.com/revenue-ops/salesforce-integration-in-outreach-best-practices/)
- [FoundHQ: Ultimate Guide to Integrating Salesforce with Outreach](https://www.foundhq.com/salesforce-integration/outreach)
