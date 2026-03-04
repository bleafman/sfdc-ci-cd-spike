/**
 * seed-data.apex — Anonymous Apex script to populate a scratch org with realistic sample data.
 *
 * HOW TO RUN:
 *   sf apex run --file scripts/apex/seed-data.apex
 *
 * WHAT THIS DOES:
 *   Creates a realistic B2B sales dataset: Accounts, Contacts, Opportunities, and Leads.
 *   Designed to exercise the custom metadata defined in this project (custom Opportunity stages,
 *   custom fields on Opportunity, validation rules, etc.).
 *
 * WHY ANONYMOUS APEX?
 *   Salesforce has two main ways to seed data: JSON import (sf data import tree) and Anonymous Apex.
 *   Apex gives us programmatic control — we can set up parent-child relationships (Account -> Contact,
 *   Account -> Opportunity) in a single transaction and reference IDs immediately after insert.
 *   The JSON approach requires pre-defined reference IDs and separate files per object. Apex is
 *   simpler for complex relationship graphs.
 *
 * SALESFORCE DATA MODEL PRIMER (for non-Salesforce devs):
 *   - Account = a company/organization. The central object in B2B Salesforce.
 *   - Contact = a person at an Account. Contacts belong to Accounts (many-to-one).
 *   - Opportunity = a potential deal. Belongs to an Account. Moves through pipeline stages.
 *   - Lead = an unqualified prospect (person + company in one record). When qualified, a Lead
 *     gets "converted" into an Account + Contact + Opportunity — Salesforce handles this natively.
 *
 * IMPORTANT ASSUMPTIONS:
 *   - The scratch org has the custom Opportunity stages deployed (Prospecting, Discovery, Proposal,
 *     Negotiation, Closed Won, Closed Lost) — these come from the standardValueSets metadata.
 *   - The custom fields on Opportunity are deployed: Deal_Source__c, Expected_Contract_Value__c,
 *     Next_Step__c.
 *   - The validation rule requiring Next_Step__c on Proposal+ stages is active.
 *   Deploy all metadata BEFORE running this script:
 *     sf project deploy start
 *     sf apex run --file scripts/apex/seed-data.apex
 *
 * IDEMPOTENCY:
 *   This script is NOT idempotent. Running it twice will create duplicate records.
 *   For a scratch org that's fine — scratch orgs are disposable. If you need a clean slate,
 *   just spin up a new scratch org.
 */

// ============================================================================
// ACCOUNTS
// ============================================================================
// In Salesforce, Account is the anchor object. Contacts and Opportunities both
// reference an Account via a lookup/master-detail relationship. We insert
// Accounts first so we have their IDs for child records.
//
// The "Industry" and "NumberOfEmployees" fields are standard Salesforce fields —
// they ship with every org. Industry is a picklist with predefined values;
// NumberOfEmployees is a simple integer.
// ============================================================================

List<Account> accounts = new List<Account>{
    // --- Enterprise accounts (1000+ employees) ---
    new Account(
        Name = 'Meridian Financial Group',
        Industry = 'Financial Services',
        NumberOfEmployees = 4200,
        BillingCity = 'New York',
        BillingState = 'NY',
        Website = 'https://www.meridianfg.example.com',
        Description = 'Full-service financial advisory firm. Fortune 500.'
    ),
    new Account(
        Name = 'Apex Manufacturing Corp',
        Industry = 'Manufacturing',
        NumberOfEmployees = 8500,
        BillingCity = 'Detroit',
        BillingState = 'MI',
        Website = 'https://www.apexmfg.example.com',
        Description = 'Industrial equipment manufacturer with global distribution.'
    ),
    new Account(
        Name = 'Constellation Health Systems',
        Industry = 'Healthcare',
        NumberOfEmployees = 12000,
        BillingCity = 'Boston',
        BillingState = 'MA',
        Website = 'https://www.constellationhs.example.com',
        Description = 'Regional healthcare network. 15 hospitals, 200+ clinics.'
    ),
    new Account(
        Name = 'TerraVerde Energy',
        Industry = 'Energy',
        NumberOfEmployees = 3100,
        BillingCity = 'Houston',
        BillingState = 'TX',
        Website = 'https://www.terraverde.example.com',
        Description = 'Renewable energy provider. Wind and solar installations.'
    ),

    // --- Mid-market accounts (100-999 employees) ---
    new Account(
        Name = 'Nimbus Analytics',
        Industry = 'Technology',
        NumberOfEmployees = 350,
        BillingCity = 'Austin',
        BillingState = 'TX',
        Website = 'https://www.nimbusanalytics.example.com',
        Description = 'Business intelligence and data analytics platform.'
    ),
    new Account(
        Name = 'Redwood Legal Partners',
        Industry = 'Professional Services',
        NumberOfEmployees = 180,
        BillingCity = 'San Francisco',
        BillingState = 'CA',
        Description = 'Mid-size law firm specializing in tech and IP law.'
    ),
    new Account(
        Name = 'Catalyst Education',
        Industry = 'Education',
        NumberOfEmployees = 420,
        BillingCity = 'Chicago',
        BillingState = 'IL',
        Description = 'EdTech company. SaaS platform for K-12 school districts.'
    ),
    new Account(
        Name = 'Iron Bridge Logistics',
        Industry = 'Transportation',
        NumberOfEmployees = 600,
        BillingCity = 'Memphis',
        BillingState = 'TN',
        Description = 'Regional freight and last-mile delivery services.'
    ),
    new Account(
        Name = 'Prism Media Group',
        Industry = 'Media',
        NumberOfEmployees = 275,
        BillingCity = 'Los Angeles',
        BillingState = 'CA',
        Description = 'Digital advertising and content marketing agency.'
    ),

    // --- Startups (under 100 employees) ---
    new Account(
        Name = 'Velox AI',
        Industry = 'Technology',
        NumberOfEmployees = 45,
        BillingCity = 'San Francisco',
        BillingState = 'CA',
        Description = 'Series B startup. ML-powered document processing.'
    ),
    new Account(
        Name = 'GreenThread Apparel',
        Industry = 'Retail',
        NumberOfEmployees = 28,
        BillingCity = 'Portland',
        BillingState = 'OR',
        Description = 'Sustainable fashion DTC brand. Pre-Series A.'
    ),
    new Account(
        Name = 'Helix Biotech',
        Industry = 'Biotechnology',
        NumberOfEmployees = 65,
        BillingCity = 'Cambridge',
        BillingState = 'MA',
        Description = 'Early-stage biotech. CRISPR-based diagnostic tools.'
    )
};

// DML (Data Manipulation Language) is Salesforce's term for database write operations.
// insert/update/delete/upsert are the DML verbs. After insert, each record's Id field
// is automatically populated — we reference those IDs when creating child records below.
insert accounts;
System.debug('Inserted ' + accounts.size() + ' Accounts');


// ============================================================================
// CONTACTS
// ============================================================================
// Contacts belong to Accounts via the AccountId lookup field. In Salesforce, this is
// a standard relationship — not a junction object, just a foreign key.
//
// We create 2-3 contacts per account. In the real world, a sales team cares about
// knowing the right people at each company: the economic buyer (CFO, VP), the champion
// (day-to-day user), and the technical evaluator.
// ============================================================================

List<Contact> contacts = new List<Contact>();

// Helper: add contacts for a given account. We use the accounts list by index
// because after insert, each element has a valid Id.

// Meridian Financial Group (Enterprise)
contacts.add(new Contact(AccountId = accounts[0].Id, FirstName = 'David', LastName = 'Chen', Title = 'Chief Financial Officer', Email = 'dchen@meridianfg.example.com', Phone = '212-555-0101'));
contacts.add(new Contact(AccountId = accounts[0].Id, FirstName = 'Sarah', LastName = 'Okafor', Title = 'VP of Operations', Email = 'sokafor@meridianfg.example.com', Phone = '212-555-0102'));
contacts.add(new Contact(AccountId = accounts[0].Id, FirstName = 'James', LastName = 'Rivera', Title = 'Director of Technology', Email = 'jrivera@meridianfg.example.com', Phone = '212-555-0103'));

// Apex Manufacturing Corp (Enterprise)
contacts.add(new Contact(AccountId = accounts[1].Id, FirstName = 'Linda', LastName = 'Johansson', Title = 'CEO', Email = 'ljohansson@apexmfg.example.com', Phone = '313-555-0201'));
contacts.add(new Contact(AccountId = accounts[1].Id, FirstName = 'Marcus', LastName = 'Thompson', Title = 'VP of Sales', Email = 'mthompson@apexmfg.example.com', Phone = '313-555-0202'));

// Constellation Health Systems (Enterprise)
contacts.add(new Contact(AccountId = accounts[2].Id, FirstName = 'Patricia', LastName = 'Nguyen', Title = 'Chief Operating Officer', Email = 'pnguyen@constellationhs.example.com', Phone = '617-555-0301'));
contacts.add(new Contact(AccountId = accounts[2].Id, FirstName = 'Robert', LastName = 'Kim', Title = 'Director of IT', Email = 'rkim@constellationhs.example.com', Phone = '617-555-0302'));
contacts.add(new Contact(AccountId = accounts[2].Id, FirstName = 'Angela', LastName = 'Patel', Title = 'VP of Clinical Operations', Email = 'apatel@constellationhs.example.com', Phone = '617-555-0303'));

// TerraVerde Energy (Enterprise)
contacts.add(new Contact(AccountId = accounts[3].Id, FirstName = 'Carlos', LastName = 'Mendez', Title = 'VP of Business Development', Email = 'cmendez@terraverde.example.com', Phone = '713-555-0401'));
contacts.add(new Contact(AccountId = accounts[3].Id, FirstName = 'Rachel', LastName = 'Foster', Title = 'Director of Procurement', Email = 'rfoster@terraverde.example.com', Phone = '713-555-0402'));

// Nimbus Analytics (Mid-market)
contacts.add(new Contact(AccountId = accounts[4].Id, FirstName = 'Alex', LastName = 'Petrov', Title = 'CEO', Email = 'apetrov@nimbusanalytics.example.com', Phone = '512-555-0501'));
contacts.add(new Contact(AccountId = accounts[4].Id, FirstName = 'Maya', LastName = 'Singh', Title = 'Head of Engineering', Email = 'msingh@nimbusanalytics.example.com', Phone = '512-555-0502'));

// Redwood Legal Partners (Mid-market)
contacts.add(new Contact(AccountId = accounts[5].Id, FirstName = 'Jonathan', LastName = 'Wu', Title = 'Managing Partner', Email = 'jwu@redwoodlegal.example.com', Phone = '415-555-0601'));
contacts.add(new Contact(AccountId = accounts[5].Id, FirstName = 'Diane', LastName = 'Calloway', Title = 'Director of Operations', Email = 'dcalloway@redwoodlegal.example.com', Phone = '415-555-0602'));

// Catalyst Education (Mid-market)
contacts.add(new Contact(AccountId = accounts[6].Id, FirstName = 'Kevin', LastName = 'Park', Title = 'VP of Sales', Email = 'kpark@catalysted.example.com', Phone = '312-555-0701'));
contacts.add(new Contact(AccountId = accounts[6].Id, FirstName = 'Samantha', LastName = 'Brooks', Title = 'Product Manager', Email = 'sbrooks@catalysted.example.com', Phone = '312-555-0702'));

// Iron Bridge Logistics (Mid-market)
contacts.add(new Contact(AccountId = accounts[7].Id, FirstName = 'Thomas', LastName = 'Grant', Title = 'Chief Revenue Officer', Email = 'tgrant@ironbridge.example.com', Phone = '901-555-0801'));
contacts.add(new Contact(AccountId = accounts[7].Id, FirstName = 'Natalie', LastName = 'Cruz', Title = 'Operations Manager', Email = 'ncruz@ironbridge.example.com', Phone = '901-555-0802'));

// Prism Media Group (Mid-market)
contacts.add(new Contact(AccountId = accounts[8].Id, FirstName = 'Derek', LastName = 'Washington', Title = 'Founder & CEO', Email = 'dwashington@prismmedia.example.com', Phone = '310-555-0901'));
contacts.add(new Contact(AccountId = accounts[8].Id, FirstName = 'Lauren', LastName = 'Ellis', Title = 'VP of Client Services', Email = 'lellis@prismmedia.example.com', Phone = '310-555-0902'));

// Velox AI (Startup)
contacts.add(new Contact(AccountId = accounts[9].Id, FirstName = 'Arjun', LastName = 'Kapoor', Title = 'Co-founder & CEO', Email = 'akapoor@veloxai.example.com', Phone = '415-555-1001'));
contacts.add(new Contact(AccountId = accounts[9].Id, FirstName = 'Emily', LastName = 'Zhang', Title = 'Co-founder & CTO', Email = 'ezhang@veloxai.example.com', Phone = '415-555-1002'));

// GreenThread Apparel (Startup)
contacts.add(new Contact(AccountId = accounts[10].Id, FirstName = 'Olivia', LastName = 'Hart', Title = 'Founder & CEO', Email = 'ohart@greenthread.example.com', Phone = '503-555-1101'));
contacts.add(new Contact(AccountId = accounts[10].Id, FirstName = 'Ryan', LastName = 'Tanaka', Title = 'Head of Growth', Email = 'rtanaka@greenthread.example.com', Phone = '503-555-1102'));

// Helix Biotech (Startup)
contacts.add(new Contact(AccountId = accounts[11].Id, FirstName = 'Dr. Fatima', LastName = 'Al-Rashid', Title = 'Chief Science Officer', Email = 'falrashid@helixbio.example.com', Phone = '617-555-1201'));
contacts.add(new Contact(AccountId = accounts[11].Id, FirstName = 'Brian', LastName = 'Doyle', Title = 'VP of Commercial Strategy', Email = 'bdoyle@helixbio.example.com', Phone = '617-555-1202'));
contacts.add(new Contact(AccountId = accounts[11].Id, FirstName = 'Nina', LastName = 'Vasquez', Title = 'Director of Regulatory Affairs', Email = 'nvasquez@helixbio.example.com', Phone = '617-555-1203'));

insert contacts;
System.debug('Inserted ' + contacts.size() + ' Contacts');


// ============================================================================
// OPPORTUNITIES
// ============================================================================
// Opportunities represent deals in the pipeline. Each Opportunity belongs to an Account
// and moves through stages (our custom stages: Prospecting -> Discovery -> Proposal ->
// Negotiation -> Closed Won / Closed Lost).
//
// KEY FIELDS:
//   StageName    — which pipeline stage the deal is in. This is a standard picklist
//                  whose values we customized via standardValueSets metadata.
//   CloseDate    — expected close date. Required by Salesforce on every Opportunity.
//   Amount       — the deal value. Standard currency field.
//   Probability  — auto-set by Salesforce based on stage (we configured this in metadata),
//                  but can be overridden per record.
//
// CUSTOM FIELDS (defined in this project's metadata):
//   Deal_Source__c              — picklist: how the deal originated
//   Expected_Contract_Value__c  — currency: total expected contract value (may differ from Amount
//                                 which often represents first-year or one-time value)
//   Next_Step__c                — text: the next action item for this deal
//
// VALIDATION RULE:
//   Our metadata includes a validation rule that requires Next_Step__c to be populated
//   when StageName is "Proposal" or later. The data below respects this constraint —
//   every Opp at Proposal/Negotiation/Closed Won has a Next_Step__c value.
// ============================================================================

// Date.today() returns the current date in the running user's timezone.
// We use it to generate realistic close dates relative to "now."
Date today = Date.today();

List<Opportunity> opportunities = new List<Opportunity>{

    // --- Closed Won deals (past close dates, completed) ---
    new Opportunity(
        AccountId = accounts[0].Id,
        Name = 'Meridian Financial - Platform License',
        StageName = 'Closed Won',
        CloseDate = today.addDays(-45),
        Amount = 285000,
        Deal_Source__c = 'Inbound',
        Expected_Contract_Value__c = 855000,
        Next_Step__c = 'Completed — contract signed. Kickoff scheduled.'
    ),
    new Opportunity(
        AccountId = accounts[4].Id,
        Name = 'Nimbus Analytics - Annual Subscription',
        StageName = 'Closed Won',
        CloseDate = today.addDays(-30),
        Amount = 72000,
        Deal_Source__c = 'Partner',
        Expected_Contract_Value__c = 216000,
        Next_Step__c = 'Completed — onboarding in progress.'
    ),
    new Opportunity(
        AccountId = accounts[7].Id,
        Name = 'Iron Bridge - Fleet Management Module',
        StageName = 'Closed Won',
        CloseDate = today.addDays(-15),
        Amount = 95000,
        Deal_Source__c = 'Outbound',
        Expected_Contract_Value__c = 285000,
        Next_Step__c = 'Completed — implementation phase 1 started.'
    ),

    // --- Closed Lost deals (past close dates, did not convert) ---
    new Opportunity(
        AccountId = accounts[10].Id,
        Name = 'GreenThread - E-commerce Integration',
        StageName = 'Closed Lost',
        CloseDate = today.addDays(-60),
        Amount = 18000,
        Deal_Source__c = 'Inbound',
        Expected_Contract_Value__c = 54000,
        Next_Step__c = 'Lost — budget constraints. Revisit in Q3.'
    ),
    new Opportunity(
        AccountId = accounts[8].Id,
        Name = 'Prism Media - Campaign Analytics Suite',
        StageName = 'Closed Lost',
        CloseDate = today.addDays(-20),
        Amount = 45000,
        Deal_Source__c = 'Referral',
        Expected_Contract_Value__c = 135000,
        Next_Step__c = 'Lost — chose competitor. Maintain relationship.'
    ),

    // --- Negotiation stage (late-stage, close dates coming up) ---
    new Opportunity(
        AccountId = accounts[1].Id,
        Name = 'Apex Manufacturing - Enterprise Rollout',
        StageName = 'Negotiation',
        CloseDate = today.addDays(14),
        Amount = 520000,
        Deal_Source__c = 'Outbound',
        Expected_Contract_Value__c = 1560000,
        Next_Step__c = 'Legal review of MSA. Procurement meeting Friday.'
    ),
    new Opportunity(
        AccountId = accounts[2].Id,
        Name = 'Constellation Health - Clinical Data Platform',
        StageName = 'Negotiation',
        CloseDate = today.addDays(21),
        Amount = 380000,
        Deal_Source__c = 'Inbound',
        Expected_Contract_Value__c = 1140000,
        Next_Step__c = 'Security review with IT team. BAA signature pending.'
    ),

    // --- Proposal stage (mid-pipeline, active deals) ---
    new Opportunity(
        AccountId = accounts[3].Id,
        Name = 'TerraVerde - Asset Monitoring System',
        StageName = 'Proposal',
        CloseDate = today.addDays(35),
        Amount = 210000,
        Deal_Source__c = 'Partner',
        Expected_Contract_Value__c = 630000,
        Next_Step__c = 'Present revised proposal to VP of Engineering.'
    ),
    new Opportunity(
        AccountId = accounts[5].Id,
        Name = 'Redwood Legal - Document Management',
        StageName = 'Proposal',
        CloseDate = today.addDays(28),
        Amount = 48000,
        Deal_Source__c = 'Referral',
        Expected_Contract_Value__c = 144000,
        Next_Step__c = 'Demo with associates next Tuesday. Send pricing comparison.'
    ),
    new Opportunity(
        AccountId = accounts[9].Id,
        Name = 'Velox AI - Startup Program License',
        StageName = 'Proposal',
        CloseDate = today.addDays(42),
        Amount = 36000,
        Deal_Source__c = 'Inbound',
        Expected_Contract_Value__c = 108000,
        Next_Step__c = 'CTO technical evaluation. Send API documentation.'
    ),

    // --- Discovery stage (early-mid pipeline) ---
    new Opportunity(
        AccountId = accounts[6].Id,
        Name = 'Catalyst Education - District Analytics Package',
        StageName = 'Discovery',
        CloseDate = today.addDays(60),
        Amount = 125000,
        Deal_Source__c = 'Inbound',
        Expected_Contract_Value__c = 375000
        // No Next_Step__c required — Discovery is before Proposal in the pipeline
    ),
    new Opportunity(
        AccountId = accounts[11].Id,
        Name = 'Helix Biotech - Lab Data Integration',
        StageName = 'Discovery',
        CloseDate = today.addDays(75),
        Amount = 88000,
        Deal_Source__c = 'Partner',
        Expected_Contract_Value__c = 264000
    ),
    new Opportunity(
        AccountId = accounts[0].Id,
        Name = 'Meridian Financial - Risk Analytics Add-on',
        StageName = 'Discovery',
        CloseDate = today.addDays(50),
        Amount = 150000,
        Deal_Source__c = 'Outbound',
        Expected_Contract_Value__c = 450000
    ),

    // --- Prospecting stage (very early pipeline) ---
    new Opportunity(
        AccountId = accounts[1].Id,
        Name = 'Apex Manufacturing - Quality Control Module',
        StageName = 'Prospecting',
        CloseDate = today.addDays(90),
        Amount = 175000,
        Deal_Source__c = 'Referral',
        Expected_Contract_Value__c = 525000
    ),
    new Opportunity(
        AccountId = accounts[3].Id,
        Name = 'TerraVerde - Compliance Reporting Tool',
        StageName = 'Prospecting',
        CloseDate = today.addDays(120),
        Amount = 65000,
        Deal_Source__c = 'Outbound',
        Expected_Contract_Value__c = 195000
    ),
    new Opportunity(
        AccountId = accounts[8].Id,
        Name = 'Prism Media - Audience Insights Platform',
        StageName = 'Prospecting',
        CloseDate = today.addDays(100),
        Amount = 55000,
        Deal_Source__c = 'Inbound',
        Expected_Contract_Value__c = 165000
    ),
    new Opportunity(
        AccountId = accounts[2].Id,
        Name = 'Constellation Health - Patient Portal Upgrade',
        StageName = 'Prospecting',
        CloseDate = today.addDays(110),
        Amount = 240000,
        Deal_Source__c = 'Outbound',
        Expected_Contract_Value__c = 720000
    )
};

insert opportunities;
System.debug('Inserted ' + opportunities.size() + ' Opportunities');


// ============================================================================
// LEADS
// ============================================================================
// Leads are standalone records — they don't belong to an Account. A Lead represents
// an unqualified prospect: a person + company combo that hasn't been vetted yet.
//
// When a sales rep qualifies a Lead, Salesforce "converts" it — automatically creating
// an Account, Contact, and optionally an Opportunity from the Lead data. This is a
// built-in Salesforce process, not custom code.
//
// KEY FIELDS:
//   Status       — standard picklist tracking where the Lead is in qualification.
//                  Default values: Open, Contacted, Qualified, Unqualified.
//   LeadSource   — standard picklist indicating where the lead came from.
//   Rating       — standard picklist: Hot, Warm, Cold. Indicates sales-readiness.
//   Company      — required field on Lead (since Leads aren't linked to Accounts yet,
//                  the company name lives directly on the Lead record).
// ============================================================================

List<Lead> leads = new List<Lead>{

    // --- Hot leads (ready for conversion) ---
    new Lead(
        FirstName = 'Michael',
        LastName = 'Brennan',
        Company = 'Pinnacle Consulting Group',
        Title = 'VP of Digital Transformation',
        Email = 'mbrennan@pinnaclecg.example.com',
        Phone = '646-555-2001',
        LeadSource = 'Web',
        Status = 'Qualified',
        Rating = 'Hot',
        Industry = 'Consulting',
        NumberOfEmployees = 500,
        Description = 'Requested enterprise demo. Budget approved for Q2.'
    ),
    new Lead(
        FirstName = 'Sandra',
        LastName = 'Liu',
        Company = 'Quantum Dynamics',
        Title = 'Director of Engineering',
        Email = 'sliu@quantumdyn.example.com',
        Phone = '408-555-2002',
        LeadSource = 'Partner Referral',
        Status = 'Qualified',
        Rating = 'Hot',
        Industry = 'Technology',
        NumberOfEmployees = 220,
        Description = 'Referred by AWS partner team. Needs integration with existing stack.'
    ),
    new Lead(
        FirstName = 'Victor',
        LastName = 'Osei',
        Company = 'Atlas Freight Solutions',
        Title = 'Chief Operating Officer',
        Email = 'vosei@atlasfreight.example.com',
        Phone = '404-555-2003',
        LeadSource = 'Trade Show',
        Status = 'Qualified',
        Rating = 'Hot',
        Industry = 'Transportation',
        NumberOfEmployees = 850,
        Description = 'Met at LogiTech 2026 conference. Immediate need for route optimization.'
    ),

    // --- Warm leads (engaged but not yet qualified) ---
    new Lead(
        FirstName = 'Catherine',
        LastName = 'Morales',
        Company = 'Elevate Wellness',
        Title = 'Head of Product',
        Email = 'cmorales@elevatewellness.example.com',
        Phone = '303-555-2004',
        LeadSource = 'Web',
        Status = 'Contacted',
        Rating = 'Warm',
        Industry = 'Healthcare',
        NumberOfEmployees = 75,
        Description = 'Downloaded whitepaper. Responded to follow-up email. Discovery call scheduled.'
    ),
    new Lead(
        FirstName = 'Andre',
        LastName = 'Williams',
        Company = 'Brightpath Financial',
        Title = 'SVP of Wealth Management',
        Email = 'awilliams@brightpath.example.com',
        Phone = '312-555-2005',
        LeadSource = 'Advertisement',
        Status = 'Contacted',
        Rating = 'Warm',
        Industry = 'Financial Services',
        NumberOfEmployees = 1200,
        Description = 'Clicked on LinkedIn ad campaign. Initial call completed — exploring options.'
    ),
    new Lead(
        FirstName = 'Priya',
        LastName = 'Sharma',
        Company = 'NovaCraft Studios',
        Title = 'Creative Director',
        Email = 'psharma@novacraft.example.com',
        Phone = '323-555-2006',
        LeadSource = 'Partner Referral',
        Status = 'Contacted',
        Rating = 'Warm',
        Industry = 'Media',
        NumberOfEmployees = 40,
        Description = 'Referral from existing customer (Prism Media). Interested in content tools.'
    ),
    new Lead(
        FirstName = 'Daniel',
        LastName = 'O\'Brien',
        Company = 'Stonewall Construction',
        Title = 'Project Director',
        Email = 'dobrien@stonewall.example.com',
        Phone = '215-555-2007',
        LeadSource = 'Web',
        Status = 'Contacted',
        Rating = 'Warm',
        Industry = 'Construction',
        NumberOfEmployees = 340,
        Description = 'Attended webinar on project management tools. Asked about pricing.'
    ),

    // --- Cold / early-stage leads (new, minimal engagement) ---
    new Lead(
        FirstName = 'Yuki',
        LastName = 'Tanaka',
        Company = 'Sakura Robotics',
        Title = 'R&D Manager',
        Email = 'ytanaka@sakurarobotics.example.com',
        Phone = '650-555-2008',
        LeadSource = 'Web',
        Status = 'Open - Not Contacted',
        Rating = 'Cold',
        Industry = 'Technology',
        NumberOfEmployees = 90,
        Description = 'Form fill on website. No engagement yet.'
    ),
    new Lead(
        FirstName = 'Rebecca',
        LastName = 'Johansson',
        Company = 'Nordic Supply Chain AB',
        Title = 'Logistics Manager',
        Email = 'rjohansson@nordicsupply.example.com',
        Phone = '917-555-2009',
        LeadSource = 'Other',
        Status = 'Open - Not Contacted',
        Rating = 'Cold',
        Industry = 'Transportation',
        NumberOfEmployees = 150,
        Description = 'Imported from purchased list. No outreach attempted.'
    ),
    new Lead(
        FirstName = 'Hassan',
        LastName = 'El-Amin',
        Company = 'CrescentTech Solutions',
        Title = 'IT Director',
        Email = 'helamin@crescenttech.example.com',
        Phone = '571-555-2010',
        LeadSource = 'Web',
        Status = 'Open - Not Contacted',
        Rating = 'Cold',
        Industry = 'Technology',
        NumberOfEmployees = 180,
        Description = 'Visited pricing page twice. No form submission — identified via marketing automation.'
    ),
    new Lead(
        FirstName = 'Gabriela',
        LastName = 'Ferreira',
        Company = 'Verde Agritech',
        Title = 'Director of Sustainability',
        Email = 'gferreira@verdeagri.example.com',
        Phone = '786-555-2011',
        LeadSource = 'Trade Show',
        Status = 'Open - Not Contacted',
        Rating = 'Cold',
        Industry = 'Agriculture',
        NumberOfEmployees = 200,
        Description = 'Scanned badge at sustainability expo booth. No follow-up yet.'
    ),
    new Lead(
        FirstName = 'Marcus',
        LastName = 'Hoffman',
        Company = 'Precision Optics Inc',
        Title = 'VP of Manufacturing',
        Email = 'mhoffman@precisionoptics.example.com',
        Phone = '585-555-2012',
        LeadSource = 'Web',
        Status = 'Open - Not Contacted',
        Rating = 'Cold',
        Industry = 'Manufacturing',
        NumberOfEmployees = 310,
        Description = 'Organic search visitor. Downloaded case study PDF.'
    ),

    // --- Disqualified leads (for realistic pipeline data) ---
    new Lead(
        FirstName = 'Trevor',
        LastName = 'Nash',
        Company = 'Nash & Associates',
        Title = 'Sole Proprietor',
        Email = 'tnash@nashassoc.example.com',
        Phone = '502-555-2013',
        LeadSource = 'Web',
        Status = 'Unqualified',
        Rating = 'Cold',
        Industry = 'Consulting',
        NumberOfEmployees = 1,
        Description = 'Too small — solo consultant. Not a fit for enterprise product.'
    ),
    new Lead(
        FirstName = 'Isabelle',
        LastName = 'Fontaine',
        Company = 'Fontaine Design Studio',
        Title = 'Principal Designer',
        Email = 'ifontaine@fontainedesign.example.com',
        Phone = '206-555-2014',
        LeadSource = 'Web',
        Status = 'Unqualified',
        Rating = 'Cold',
        Industry = 'Media',
        NumberOfEmployees = 5,
        Description = 'Looking for a free tool. No budget for paid solutions.'
    ),
    new Lead(
        FirstName = 'Raj',
        LastName = 'Gupta',
        Company = 'IndoTech Global Services',
        Title = 'Procurement Officer',
        Email = 'rgupta@indotech.example.com',
        Phone = '201-555-2015',
        LeadSource = 'Other',
        Status = 'Open - Not Contacted',
        Rating = 'Cold',
        Industry = 'Technology',
        NumberOfEmployees = 5000,
        Description = 'Large company but unclear use case. Needs qualification call.'
    )
};

insert leads;
System.debug('Inserted ' + leads.size() + ' Leads');


// ============================================================================
// SUMMARY
// ============================================================================
System.debug('=== Seed Data Summary ===');
System.debug('Accounts:      ' + accounts.size());
System.debug('Contacts:      ' + contacts.size());
System.debug('Opportunities: ' + opportunities.size());
System.debug('Leads:         ' + leads.size());
System.debug('Total records: ' + (accounts.size() + contacts.size() + opportunities.size() + leads.size()));
System.debug('=========================');
