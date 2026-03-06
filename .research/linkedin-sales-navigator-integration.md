# LinkedIn Sales Navigator - Salesforce Integration Research

Research date: 2026-03-06

## Summary

LinkedIn Sales Navigator integrates with Salesforce through **two distinct mechanisms**: a Salesforce-native integration (built into the platform) and a managed AppExchange package. Most orgs use both. The integration primarily adds UI components, Task record types for activity writeback, and a small number of custom fields. It does **not** heavily modify org schema -- most data flows through API reads/writes to standard fields.

---

## 1. Managed Package on AppExchange

**Yes**, LinkedIn Sales Navigator has a managed package on AppExchange.

- **AppExchange listing**: [LinkedIn Sales Navigator for Salesforce](https://appexchange.salesforce.com/appxListingDetail?listingId=a0N4V00000H8VCxUAN)
- **Package name (as installed)**: "SN for SFDC"
- **Namespace prefix**: `LID`
- All managed components (Apex classes, Visualforce pages, custom fields, Lightning components) are prefixed with `LID__`

There is **also** a Salesforce-native integration (no package required) that provides embedded LinkedIn profiles in Lightning. The native integration is built into Salesforce and does not use the `LID` namespace.

### Native Integration vs. AppExchange Package

| Capability | Native Integration | AppExchange Package (`LID`) |
|---|---|---|
| Embedded profiles on Contact/Lead/Account/Opportunity | Yes (Lightning only) | Yes (Lightning + Classic) |
| InMail / Connection Request actions | Yes | Yes |
| Data Validation (flag stale contacts) | No | **Required** |
| Activity Write Back | No | **Required** |
| CRM Sync | Partial | Full |
| Salesforce Classic support | No | Yes |

**Recommendation from LinkedIn**: Install both. The AppExchange package is required for Data Validation and Activity Write Back features.

---

## 2. Custom Fields Created

The managed package creates a **limited** set of custom fields:

### On Contact
- `LID__LinkedIn_Member_Token__c` -- Stores the matched LinkedIn member identifier
- `LID__Not_At_Company_Flag__c` -- Auto-populated by Data Validation when a contact has left their company (checked every 24 hours)

### On Lead
- `LID__LinkedIn_Member_Token__c` -- Same as Contact, for lead matching

### On Account
- LinkedIn company matching fields (exact API names less well-documented, but follow the `LID__` pattern)

### Custom Field Mapping (Optional, Admin-Configured)
Admins can optionally create their **own** custom fields and map LinkedIn firmographic data to them using the Custom Field Mapping Tool. These are not package-managed -- they are org-specific fields the admin creates. Examples include mapping LinkedIn company data (industry, employee count, headquarters) to custom fields on Account records.

**Key point**: The package itself creates relatively few custom fields. Most "field mapping" is done by admins as a post-install configuration choice, writing to either standard fields or admin-created custom fields.

---

## 3. Custom Objects, Flows, Triggers, and Other Metadata

### Task Record Types (Major Impact)
The package creates **new Record Types on the Task object**:

- `LinkedIn Call`
- `LinkedIn InMail`
- `LinkedIn Message`
- `Smart Links Created`
- `Smart Links Viewed`

**Important side effect**: If your org has **never used Task Record Types before**, installing Sales Navigator activates record types on Task for the first time. This can hide certain Global Actions/Tasks. The Sales Navigator Installation Wizard (accessed via LinkedIn Admin Portal) can create a "general" record type to restore hidden actions.

### Apex Classes
Multiple Apex classes prefixed with `LID` are installed. These are managed (obfuscated) and cannot be viewed or modified. They handle:
- CRM Sync logic
- Activity Write Back processing
- Data Validation checks

### Visualforce Pages
Multiple Visualforce pages prefixed with `LID` are installed. These render the Sales Navigator embedded panels in Classic layouts. Profile permissions must explicitly enable access to `LID` Visualforce pages and Apex classes.

### Lightning Components
The package includes Lightning components for embedding Sales Navigator panels:
- Member Profile component ("Sales Navigator: Member Profile (LID)")
- Company Profile component
- These can be added to record pages via Lightning App Builder

### No Custom Objects
The package does **not** create standalone custom objects. It extends standard objects (Contact, Lead, Account, Task) with fields and record types.

### No Flows or Triggers (in the traditional sense)
The package does not install declarative Flows or Apex Triggers visible to admins. Sync and writeback logic is handled within the managed Apex code, not through admin-visible automation.

---

## 4. Setup Steps

### Prerequisites
- Salesforce Professional, Enterprise, Unlimited, Developer, or Performance edition
- LinkedIn Sales Navigator Advanced or Advanced Plus license
- Salesforce admin access

### Installation Sequence

1. **Install AppExchange Package**: Install "LinkedIn Sales Navigator for Salesforce" from AppExchange. Choose "Install for All Users" or specific profiles.

2. **Enable Native Integration**: In Salesforce Setup, navigate to Feature Settings > Sales > LinkedIn Sales Navigator. Toggle "Enable LinkedIn Sales Navigator" to On.

3. **Configure Profile Permissions**: For each profile that needs access:
   - Enable all Apex Classes starting with `LID`
   - Enable all Visualforce Pages starting with `LID`

4. **Add Lightning Components to Page Layouts**: Using Lightning App Builder, add Sales Navigator components to Contact, Lead, Account, and Opportunity record pages.

5. **Enable CRM Sync**: In LinkedIn Sales Navigator Admin Settings, connect the Salesforce org via OAuth. Configure sync direction and frequency.

6. **Enable Activity Write Back** (optional): Allow users to log InMails, messages, calls, and notes back to Salesforce as Task records.

7. **Enable Data Validation** (optional, Advanced Plus only): Automatically flags contacts who have left their company.

8. **Configure Custom Field Mapping** (optional): Map LinkedIn data points to Salesforce fields of your choosing.

---

## 5. API vs. Schema Modification

Sales Navigator **primarily works via API**:

- **CRM Sync** reads standard fields (Name, Email, Phone, Title, Company) from Contact/Lead/Account via the Salesforce REST API to match records in LinkedIn
- **Activity Write Back** creates Task records using standard Task fields plus the custom record types
- **Data Validation** writes to the `LID__Not_At_Company_Flag__c` custom field

The integration does **not** extensively modify org schema. It:
- Adds a handful of `LID__` namespaced custom fields
- Adds Task record types
- Installs managed Apex/VF/Lightning components
- Reads/writes mostly standard fields via API

---

## 6. What Shows Up in `sf project retrieve`

### Managed Package Components (Namespaced -- Usually Excluded)
These live under the `LID` namespace and are **typically excluded** from source tracking in CI/CD:
- `LID__LinkedIn_Member_Token__c` fields on Contact and Lead
- `LID__Not_At_Company_Flag__c` on Contact
- Managed Apex classes (obfuscated, cannot be deployed anyway)
- Managed Visualforce pages
- Managed Lightning components

### Org-Level Changes (Will Show in Retrieval)
These are the changes that **will** appear in your source and need CI/CD attention:

- **Task Record Types**: New record types on Task (`LinkedIn_Call`, `LinkedIn_InMail`, `LinkedIn_Message`, `Smart_Links_Created`, `Smart_Links_Viewed`)
- **Page Layout modifications**: If you add Sales Navigator components to Contact/Lead/Account/Opportunity page layouts, those layout XML files will change
- **Profile/Permission Set changes**: Apex class and Visualforce page access grants for `LID` components
- **Lightning Record Pages (FlexiPages)**: If you customize record pages via App Builder to include Sales Navigator components
- **Admin-created custom fields**: Any custom fields you create for Custom Field Mapping

### .forceignore Recommendations
To keep managed package noise out of your repo:
```
# LinkedIn Sales Navigator managed package
**/LID__*
```

However, you **will** want to track:
- Modified page layouts (even if they reference `LID` components)
- Task record types (these are org metadata, not namespaced)
- Profile changes granting access to `LID` components
- FlexiPages that embed Sales Navigator components
- Any custom fields you created for field mapping

---

## 7. Lightning Components, Page Layouts, and UI Metadata

### Lightning Components (via App Builder)
The package provides drag-and-drop Lightning components:
- **Sales Navigator: Member Profile** -- Shows LinkedIn profile for matched Contact/Lead
- **Sales Navigator: Company Profile** -- Shows LinkedIn company page for matched Account
- **Sales Navigator: Related Leads** -- Shows recommended leads at an Account

These are added to record pages via Lightning App Builder, which creates/modifies **FlexiPage** metadata.

### Native Lightning Components (no package needed)
Salesforce's native integration also provides LinkedIn components that can be added without the AppExchange package. These appear in the Lightning App Builder component palette after enabling the native integration in Setup.

### Lightning Actions
- **LinkedIn InMail** -- Quick action to send InMail from a record
- **LinkedIn Connection Request** -- Quick action to send connection request

These are added to page layouts in the "Salesforce Mobile and Lightning Experience Actions" section.

### Page Layout Impact
Adding Sales Navigator to your org typically modifies:
- `Contact-Contact Layout.layout-meta.xml`
- `Lead-Lead Layout.layout-meta.xml`
- `Account-Account Layout.layout-meta.xml`
- `Opportunity-Opportunity Layout.layout-meta.xml`
- Corresponding FlexiPage files for Lightning record pages

---

## CI/CD Implications Summary

| What Changes | Tracked in Repo? | Notes |
|---|---|---|
| `LID__` custom fields | Usually excluded via .forceignore | Managed; re-created by package install |
| `LID__` Apex/VF/LWC | Excluded | Managed and obfuscated |
| Task Record Types | **Yes, track these** | Org metadata, not namespaced |
| Page Layout XML changes | **Yes, track these** | Will reference `LID` components |
| FlexiPages | **Yes, track these** | Lightning record page customizations |
| Profile/PermSet changes | **Yes, track these** | `LID` class/page access grants |
| Admin-created custom fields | **Yes, track these** | Your own fields for mapping |
| CRM Sync configuration | No | Configured in LinkedIn admin, not Salesforce metadata |

### Deployment Pipeline Considerations

1. **Package must be installed first**: Before deploying page layouts or profiles that reference `LID` components, the managed package must already be installed in the target org. Add package installation as a pipeline prerequisite.

2. **Task Record Types may conflict**: If deploying to a fresh org, the Task record type changes may conflict with the package installation creating them. Sequence matters.

3. **Namespace references in layouts**: Page layout XML will contain references like `LID__LinkedIn_Member_Token__c`. These will fail deployment if the package is not installed. Consider maintaining separate layout files or using environment-specific deployment strategies.

4. **Profile metadata is fragile**: Profile XML containing `LID` Apex class access will fail deployment to orgs without the package. Permission Sets are more portable than Profiles for this reason.

---

## Sources

- [LinkedIn Sales Navigator for Salesforce - AppExchange](https://appexchange.salesforce.com/appxListingDetail?listingId=a0N4V00000H8VCxUAN)
- [SFDC Lightning Install Guide - LinkedIn](https://business.linkedin.com/sales-solutions/sales-navigator-customer-hub/resources/sfdc-lightning-install-guide)
- [Native Integration vs. AppExchange Package - LinkedIn Help](https://www.linkedin.com/help/sales-navigator/answer/a484790/native-integration-vs-appexchange-package-for-salesforce)
- [CRM Sync Salesforce Technical Guide - LinkedIn](https://business.linkedin.com/sales-solutions/sales-navigator-customer-hub/resources/crm-sync-salesforce-technical-guide)
- [SFDC Sync & Activity Write Back - LinkedIn](https://business.linkedin.com/sales-solutions/sales-navigator-customer-hub/resources/sfdc-sync-activity-write-back)
- [Data Validation for Salesforce - LinkedIn](https://business.linkedin.com/sales-solutions/sales-navigator-customer-hub/resources/data-validation-salesforce)
- [Set Up LinkedIn Sales Navigator - Salesforce Help](https://help.salesforce.com/s/articleView?id=sales.sc_linkedin_sales_navigator_setup.htm&language=en_US&type=5)
- [Add Sales Navigator Components - Salesforce Help](https://help.salesforce.com/s/articleView?id=sf.sc_linkedin_sales_navigator_setup_components.htm&language=en_US&type=5)
- [LinkedIn Sales Navigator Integration with Salesforce - Twistellar](https://twistellar.com/blog/linkedin-sales-navigator-integration-with-salesforce)
- [Sales Navigator for Salesforce Overview - LinkedIn Help](https://www.linkedin.com/help/sales-navigator/answer/a103029)
- [Lightning App Builder for Sales Navigator - LinkedIn Help](https://www.linkedin.com/help/sales-navigator/answer/a106084/salesforce-lightning-app-builder-for-sales-navigator)
- [CRM Sync Technical PDF - LinkedIn](https://business.linkedin.com/content/dam/me/business/en-us/sales-solutions/resources/pdfs/LinkedIn-Sales-Navigator-for-salesforce.pdf)
- [Excluding Source with .forceignore - Salesforce Developers](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_exclude_source.htm)
- [Salesforce CLI Issue: Managed Package Retrieval](https://github.com/forcedotcom/cli/issues/87)
