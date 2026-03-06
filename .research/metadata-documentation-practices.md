# How Salesforce Teams Actually Document Their Metadata

Research compiled 2026-03-06. Focus: real practices with verifiable sources, not theoretical ideals.

---

## The Core Problem

XML comments in Salesforce metadata files get silently stripped on retrieve/deploy cycles. The Metadata API overwrites them. Salto's blog explicitly confirms this: "When you retrieve this metadata, Salesforce will override the XML and remove your comment." This means the most natural developer instinct -- adding comments alongside the code -- does not work in the Salesforce ecosystem.

**Source:** [Salesforce Metadata Reimagined -- Goodbye XML (Salto)](https://www.salto.io/blog-posts/salesforce-metadata-reimagined-goodbye-xml)

---

## What Teams Actually Do (Tier by Tier)

### Tier 1: Built-in Description Fields (The Baseline)

The most universally recommended practice is using Salesforce's own `<description>` element in metadata XML, plus `inlineHelpText` for fields. These survive deployment because they are first-class metadata properties.

**What this covers:**
- Custom Objects: `<description>` element in object-meta.xml
- Custom Fields: `<description>` and `<inlineHelpText>` in field-meta.xml
- Flows: description field on the flow itself and on individual flow elements
- Validation Rules: `<description>` element
- Approval Processes: description field
- Change Sets: description field

**What Salesforce officially recommends:**

The Salesforce Admin blog's "Ultimate Guide to Flow Best Practices" says: populate description fields, particularly for Flows used in production. Include what your flow does, the objects it touches, where it's invoked from, and which business processes it hooks into.

The Flow Architect blog identifies four documentation tools that work inside Salesforce:
1. Description fields (extractable, deployable)
2. In-line comments in formulas/validation rules using `/* */` syntax
3. Flow element descriptions
4. Reports on Screen Flows and Orchestrator runs

Salesforce's own blog post "5 Documentation Strategies to Improve Your Salesforce Org" recommends putting at minimum a ticket number in every description field to give future admins a reference point.

**Sources:**
- [The Ultimate Guide to Flow Best Practices and Standards (Salesforce Admins)](https://admin.salesforce.com/blog/2021/the-ultimate-guide-to-flow-best-practices-and-standards)
- [Documentation: What Can You Use Inside Salesforce? (The Flow Architect)](https://theflowarchitect.com/2023/03/documention-what-can-you-use-inside-salesforce/)
- [5 Documentation Strategies to Improve Your Salesforce Org (Salesforce)](https://www.salesforce.com/blog/documentation-strategies-to-improve-your-salesforce-org/)

### Tier 2: External Data Dictionaries (The Industry Standard)

The most common documentation artifact in the Salesforce ecosystem is the **data dictionary** -- a catalog of objects, fields, their purposes, owners, and relationships. This is maintained *outside* the metadata files.

**The spreadsheet era (still common, widely acknowledged as broken):**

Most teams start with a spreadsheet. Arovy's research shows this pattern fails at scale: "One admin alone can create 100+ metadata changes a month. Add developers, consultants, and integrations, and you're looking at hundreds to thousands of changes per quarter -- no spreadsheet can keep up." Their 6Sense case study documented 4 people spending 20+ hours/month manually maintaining an Excel data dictionary, with errors and breaks occurring regularly.

Ian Gotts (Elements.cloud founder) wrote a widely-cited LinkedIn article arguing "every Salesforce org needs a metadata dictionary" and that it must be kept in sync automatically via APIs, ideally nightly.

Salesforce Ben's 2026 article "Do Salesforce Data Dictionaries Still Matter in 2026?" (by Mehmet Orun, Salesforce MVP) confirms dictionaries matter more than ever with AI/Agentforce adoption, emphasizing: "The specific format doesn't matter as much as having clear definitions, ownership, and sensitivity classifications tied to your metadata."

**Sources:**
- [Your Salesforce Data Dictionary is Dead in Excel (Arovy)](https://www.arovy.com/resources/blog/your-salesforce-data-dictionary-is-dead-in-excel)
- [What every Salesforce Org needs -- a metadata dictionary (Ian Gotts, LinkedIn)](https://www.linkedin.com/pulse/what-every-salesforce-org-needs-meta-data-dictionary-ian-gotts)
- [Do Salesforce Data Dictionaries Still Matter in 2026? (Salesforce Ben)](https://www.salesforceben.com/do-salesforce-data-dictionaries-still-matter-in-2026/)
- [6Sense Case Study (Arovy)](https://www.arovy.com/case-studies/6sense-success-story)

### Tier 3: Wikis and Confluence (The "Real" Documentation)

Many teams document at a higher level in Confluence, Google Docs, or similar:

- Architecture decisions and data model rationale
- Process maps showing how metadata components relate
- Change logs recording what changed, why, who requested it, and when
- Integration documentation

Cloud Studio's guidance: "Documentation can be google docs, word documents, zoom recordings of strategy sessions, pictures of a whiteboard showing technical design sketches, and even internal chats. Basically, anything that helps illuminate why a certain part of the system was built the way it was."

Concret.io recommends documenting *why* metadata was included, not just listing it: "Documentation should include more than just a list of metadata added in a release -- you need to document why you included it."

**Sources:**
- [How to Document your Salesforce org (Cloud Studio)](https://www.cloudstudio.build/writings-1/how-to-document-your-salesforce-org)
- [Best Practices for Documenting Your Salesforce Org (Concret.io)](https://www.concret.io/blog/best-practices-for-documenting-salesforce-org)

### Tier 4: Automated Documentation Tools (The Growing Category)

A large and growing category of paid tools exists specifically because the gap is real. Their existence is evidence that native Salesforce metadata + source control is not considered sufficient by the market.

| Tool | What It Does | Notable Detail |
|------|-------------|----------------|
| **Elements.cloud** | Metadata dictionary, dependency analysis, process mapping, automated documentation. Links process maps to metadata. | AppExchange listing. Founded by Ian Gotts. Nightly API sync. |
| **Sweep.io** | AI-powered continuous metadata sync, auto-describes every component, dependency mapping, change tracking. | "Documents everything from standard objects to Apex triggers, CPQ configurations, validation rules, flows." |
| **Arovy** | Automated data dictionary, sensitivity classification, ownership tracking. Embeds into Slack/Confluence/Notion. | Focused on AI/Agentforce readiness. Replaced 20+ hrs/month manual work at 6Sense. |
| **Metazoa Snapshot** | Data dictionary reports, compliance documentation, org monitoring. Desktop app. | Free data dictionary report. Exports PDF/CSV. Can document every attribute of every custom field/object. |
| **Spekit** | In-app data dictionary overlaid on Salesforce via Chrome extension. Auto-imports metadata. | Surfaces documentation contextually where users work. |
| **Hubbl** | Org intelligence, benchmarks your metadata against thousands of orgs. | Focused on health scoring and roadmapping. |
| **Salto** | Replaces XML with NaCl (readable text format). Native impact analysis via unique IDs. | Fundamentally different approach -- makes metadata itself more readable/documentable. |
| **oAtlas (Cloud Studio)** | In-org documentation app. Ties docs to projects and metadata components via Chatter. | Built on an org "map" concept. |

**Sources:**
- [Elements.cloud AppExchange listing](https://appexchange.salesforce.com/appxListingDetail?listingId=a0N3A00000EJicYUAT)
- [Sweep.io](https://www.sweep.io/ai-powered-salesforce-documentation)
- [Arovy Data Dictionary](https://www.arovy.com/data-dictionary)
- [Metazoa Data Dictionary Report](https://www.metazoa.com/data-dictionary-report/)
- [Spekit Data Dictionary](https://www.spekit.com/features/data-dictionary)
- [Hubbl](https://www.hubbl.com)
- [Salto for Salesforce](https://www.salto.io/solution/salesforce)
- [oAtlas](https://www.cloudstudio.build/oatlas)

### Tier 5: CLI-Based Documentation Generation

Bob Buzzard (Keir Bowden, Salesforce MVP/CTO BrightGen) built an open-source Salesforce CLI plugin called **Org Documentor** (`bbdoc`) that generates HTML documentation (Bootstrap-styled) directly from local SFDX metadata files. It parses the XML, enriches field info from global/standard value sets, and produces a data dictionary.

This is the closest thing to "documentation from source control" that exists in the ecosystem -- it treats the SFDX project as the source of truth and generates docs from it.

**Sources:**
- [Documenting from the metadata source with a Salesforce CLI Plug-In - Part 1 (Bob Buzzard)](http://bobbuzzard.blogspot.com/2020/04/documenting-from-metadata-source-with.html)
- [Org Documentor (Bob Buzzard)](http://bobbuzzard.blogspot.com/p/org-documentor.html)
- [bbdoc on npm](https://www.skypack.dev/view/bbdoc)

---

## What Open-Source SFDX Projects Actually Do

Looking at Salesforce's own sample projects (like dreamhouse-sfdx from trailheadapps): they have a README covering setup/installation instructions, but **no in-repo metadata documentation**. No data dictionaries, no READMEs inside the objects/ directory, no companion docs explaining field purposes. The metadata XML files contain whatever description elements Salesforce put in them, and that's it.

This is consistent across the SFDX sample projects examined. The pattern is: metadata files are self-documenting to the extent that their XML properties allow, and everything else lives elsewhere.

**Source:** [dreamhouse-sfdx (GitHub)](https://github.com/trailheadapps/dreamhouse-sfdx)

---

## The Salesforce Well-Architected Framework on Documentation

The official Salesforce Well-Architected Framework (architect.salesforce.com) touches documentation indirectly:

- Release names should appear in "documentation, change logs, work descriptions, code comments, and branches of source control" for traceability
- Metadata dependencies must be managed (unlocked packages are the recommended vehicle)
- No specific guidance on how to document individual metadata components beyond what the platform provides

The framework is more about architecture patterns (Trusted, Easy, Adaptable pillars) than prescriptive documentation practices.

**Source:** [Well-Architected Framework Overview (Salesforce Architects)](https://architect.salesforce.com/docs/architect/well-architected/guide/overview.html)

---

## The DevOps Launchpad Perspective

DevOps Launchpad (a Salesforce DevOps education resource) recommends:

- Begin source-controlling frequently changed metadata first (objects, flows, page layouts)
- Capture dependencies and relationships between components
- Use visual diagrams for complex systems
- Record the reasoning behind key architectural decisions

But notably, their guidance is about documentation *around* the repo (diagrams, dependency maps) rather than documentation *in* the metadata files themselves.

**Source:** [Salesforce DevOps documentation best practices (DevOps Launchpad)](https://devopslaunchpad.com/blog/salesforce-devops-documentation-best-practices/)

---

## Summary: The Real-World Pattern

Here is what actually happens in practice, based on the evidence:

1. **Most teams underinvest in metadata documentation.** The existence of 8+ commercial tools specifically for this problem, plus consistent "you need a data dictionary" advocacy from the community, confirms this.

2. **Description fields are the only in-metadata documentation mechanism that works.** XML comments get stripped. There is no annotation system, no comment syntax, no sidecar file convention. You get `<description>`, `<inlineHelpText>`, and formula/validation `/* */` comments.

3. **The standard external artifact is a data dictionary** -- historically in Excel, increasingly in dedicated tools. It catalogs objects, fields, purposes, owners, and sensitivity classifications.

4. **Nobody documents metadata in-repo alongside the source.** No convention exists for README files in SFDX directories, sidecar documentation files, or markdown companions to metadata XML. Even Salesforce's own sample projects don't do it.

5. **Git commit history and PR descriptions are the de facto "why" documentation** for teams using source control. The Well-Architected Framework explicitly recommends release names in commit messages and change logs.

6. **Higher-level documentation (architecture, process maps, data models) lives in Confluence/wikis/Google Docs**, disconnected from the source repo.

7. **The gap between "what exists in the repo" and "what teams need to know" is filled by commercial tools** that sync with the org via API and auto-generate documentation.

---

## Implications for Our Project

Given that no in-repo documentation convention exists in the ecosystem, if we want to pioneer one, we are genuinely inventing something new. Options to consider:

- **Sidecar markdown files** alongside metadata (e.g., `Account.object-meta.md` next to `Account.object-meta.xml`) -- no precedent, but nothing preventing it
- **Directory-level READMEs** in objects/, flows/, etc. -- simple, git-friendly, no tooling needed
- **A dedicated docs/ or .docs/ directory** with a structured data dictionary in markdown/YAML
- **Maximizing built-in description elements** as the primary documentation vehicle, with git history providing the "why"
- **Generating documentation from metadata** using something like Bob Buzzard's approach, keeping generated docs in-repo or in CI artifacts

The key tradeoff: anything outside the metadata XML itself will drift from the actual org state unless there is a process to keep it in sync.
