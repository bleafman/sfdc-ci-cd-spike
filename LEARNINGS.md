# Learnings

Running log of discoveries, gotchas, and things that would bite you in production.

## Metadata XML Quirks

### XML comments break the SF CLI metadata converter
- Placing an XML comment (`<!-- ... -->`) between the `<?xml?>` declaration and the root element causes `sf project deploy start` to fail with: `Component conversion failed: Invalid XML tags or unable to find matching parent xml file`
- This is a local conversion error — it never even hits the org
- Impact: Can't use comments for inline documentation in metadata files. Need an alternative documentation strategy.
- Research in progress → see `.research/xml-comments.md` when available

### Standard objects need a full object-meta.xml
- You can't just drop custom field files under `objects/Opportunity/fields/` — the converter needs a parent `Opportunity.object-meta.xml`
- An empty stub (`<CustomObject/>`) does NOT work
- You need to retrieve the full object metadata from a scratch org first, which includes action overrides, search layouts, sharing model, etc.
- Implication: For standard objects, the retrieve-first workflow is mandatory. You can't just author fields from scratch.

### Role metadata: `<name>` not `<label>`, access levels use `Edit` not `ReadWrite`
- Roles use `<name>` for the display name (not `<label>` or `<fullName>`)
- Access level values are `Edit`, `Read`, `None` — NOT `ReadWrite` (despite what docs/examples suggest)
- `<description>` maps to `RollupDescription` with an 80-character max
- Using the wrong access level value gives an unhelpful "unexpected error" with no indication of what's wrong
- Best approach: create roles via Apex first, then retrieve to get the canonical XML format

### Retrieve pulls everything, not just your customizations
- `sf project retrieve start --metadata "Role"` retrieves ALL roles in the org, including 18+ default roles (CEO, CFO, MarketingTeam, etc.)
- Same likely applies to profiles, permission sets, and other metadata types
- This is a CI/CD consideration: you need a strategy for which metadata to include in source control vs. ignore
- `.forceignore` might help, but the blast radius of a retrieve is wide

### Element ordering matters in metadata XML
- Salesforce metadata has a strict XSD schema — elements must appear in a specific order
- `<label>` is not a valid element in Role or Profile metadata (even though it seems like it should be)
- `<trackHistory>` on custom fields requires the parent object to have history tracking enabled
- Error messages are decent: they tell you the element name and line number

### Roles don't have a `<label>` element
- The filename IS the API name, and `<fullName>` is also just the API name
- The display name shown in the UI comes from somewhere else (possibly just the fullName with underscores replaced)
- Profiles similarly don't use `<label>` — the filename is the identity

## Scratch Org Behavior

### Scratch org creation is fast
- Takes ~17 seconds from request to ready
- The `--wait` flag is generous — 10 minutes is way more than needed

### Edition casing warning
- `"edition": "Developer"` triggers a warning about expected values being lowercase
- Still works, but `"developer"` is the correct value going forward

## Workflow Patterns

### Retrieve-first for standard objects
- Best practice: create scratch org → retrieve standard object metadata → then add your customizations on top
- This ensures your object-meta.xml matches what the org expects
- The retrieve pulls down standard fields, action overrides, search layouts, etc.

### Deploy errors are informative
- The CLI gives you a nice table with Type, Name, Problem, and Line:Column
- Errors are per-component, so you can see exactly which pieces failed and which succeeded

### Deploying custom fields doesn't grant FLS to System Administrator
- Custom fields deployed via `sf project deploy` are visible in the Tooling API (FieldDefinition) but NOT accessible to Apex code
- The Apex compiler throws "Field does not exist" even though the field is technically in the org
- Root cause: FLS (field-level security) is only granted to profiles explicitly listed in the deploy — our Sales Manager and SDR profiles got it, but System Administrator didn't
- The scratch org's default user runs as System Administrator, so the seed data script couldn't see the fields
- Fix: either include Admin profile FLS in the deploy, or run an Apex script to grant FLS after deploy
- This is a major CI/CD consideration — your deploy script needs to handle admin FLS or your post-deploy scripts will fail

## Managed Packages (AppExchange)

### Managed package metadata is retrievable but NOT deployable
- After installing a managed package (e.g., DLRS with `dlrs__` namespace), `sf project retrieve start` pulls the package's custom objects, fields, web links, list views, etc. into your `force-app/` directory
- However, you CANNOT deploy this metadata back to another org via `sf project deploy start` — the org rejects it because it belongs to the managed package namespace
- The only way to get managed package metadata into an org is `sf package install --package <versionId>`
- This means managed package metadata should NOT be in your repo — it's noise that will break deploys

### .forceignore patterns for managed package metadata
- Add `**/dlrs__*` (or whatever namespace) to `.forceignore` to prevent retrieve from pulling managed package objects into the repo
- The glob pattern `**/namespace__*` catches objects, fields, web links, list views, etc.
- You still keep YOUR source that references the package (flows, layouts, etc.) — just not the package's own metadata

### The dependency manifest pattern
- Salesforce has no `package.json` equivalent for declaring managed package dependencies
- We invented `dependencies.json` at the project root to declare what packages an org needs
- The setup script reads this manifest and installs packages via `sf package install` before deploying source
- Each entry has: name, namespace, versionId (the 04t... subscriber package version ID), required flag, description
- Packages MUST be installed before deploying source that references them — otherwise the deploy fails with "unknown namespace" errors
- `sfdx-project.json` has a `packageAliases` field but it's for packages you're developing, not for dependencies you consume

### Package install ordering matters
- If package B depends on package A, you must install A first
- Our manifest is an ordered array — packages install in the order listed
- The `sf package install` command handles transitive dependencies within a single package, but cross-package dependencies are your problem

## Apex Testing Gotchas

### MIXED_DML_OPERATION in tests
- Apex tests that create both setup objects (User, Role, Profile) and non-setup objects (Account, Opportunity) in the same transaction get `MIXED_DML_OPERATION` errors
- Fix: wrap setup object DML in `System.runAs(new User(Id = UserInfo.getUserId())) { ... }` to force a separate transaction context
- This is a well-known Salesforce limitation but it's not obvious when you first hit it

## Admin Profile Metadata

### Don't commit the retrieved Admin profile
- `sf project retrieve start` for standard profiles like Admin pulls down a massive XML file (800+ lines) with every user permission in the org
- This file varies between org editions and installed packages — it's not stable across environments
- Including it in your repo can cause deploy failures when the target org doesn't have the same features/licenses
- Better approach: use the Apex FLS grant script for admin access, keep only custom profiles in the repo
