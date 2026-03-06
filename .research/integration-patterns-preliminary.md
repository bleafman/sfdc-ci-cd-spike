# Integration Patterns: Preliminary Findings

**Status: PRELIMINARY** — based on agent research of public documentation, not verified by testing. Actual metadata impact may differ.

## Integration Spectrum

Research suggests four integration patterns with different CI/CD implications:

### Pattern 1: API-Only (e.g., Apollo)
- Connects via OAuth, reads/writes standard fields through REST API
- Zero metadata installed in the org
- CI/CD impact: None — nothing to track or deploy
- Custom fields only exist if your team creates them manually for mapping

### Pattern 2: Unmanaged Package (e.g., Outreach optional package)
- Core integration is API-based, but optional package adds custom fields/flows
- No namespace prefix — components look like your own metadata
- CI/CD impact: Medium — must retrieve, commit, and deploy like your own code
- Outreach's package reportedly adds ~29 custom fields, 4 flows, 3 reports
- **Untested question:** What does the retrieve actually look like? Do fields get interleaved with yours?

### Pattern 3: Managed Package, Light (e.g., LinkedIn Sales Navigator)
- Managed package with namespace prefix (`LID__`)
- Adds a handful of custom fields, Task record types, Lightning components
- CI/CD impact: Must install package before deploying source that references its components
- Side effects on YOUR metadata: page layouts, FlexiPages, profile permissions
- **Untested question:** Can you `.forceignore` the namespaced components cleanly? What about the side-effect metadata?

### Pattern 4: Managed Package, Heavy (e.g., Gong)
- Managed package with namespace prefix (unknown — need to install to confirm)
- Adds 10+ custom objects, Apex triggers, flows, canvas apps
- Also creates unmanaged fields on standard objects (e.g., Task)
- CI/CD impact: Highest — package dependency + significant metadata drift
- **Untested question:** How much of this shows up in a retrieve? Is there a clean boundary between "their stuff" and "your stuff"?

## Key Questions to Test

1. After installing a managed package, what exactly does `sf project retrieve start` pull down?
2. Are namespaced components (`prefix__FieldName__c`) retrievable? Deployable?
3. Do managed package installs modify existing metadata (profiles, layouts) in ways that show up as diffs?
4. Can `.forceignore` cleanly exclude managed package metadata?
5. What does the pipeline need to look like? `sf package install` before `sf project deploy`?
6. What happens if you deploy source that references a managed package component to an org where the package isn't installed?

## Next Step

Install a managed package (Salesforce Labs or DLRS) into a clean scratch org and answer these questions empirically.

## Source Material

Detailed research per tool in:
- `.research/outreach-integration.md`
- `.research/apollo-integration.md`
- `.research/gong-integration.md`
- `.research/linkedin-sales-navigator-integration.md`
