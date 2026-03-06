@isTest
private class OwnershipRulesTest {

    @TestSetup
    static void setup() {
        // Salesforce doesn't allow DML on "setup objects" (User) and
        // "non-setup objects" (Account, Opportunity) in the same transaction.
        // Wrapping User insert in System.runAs() creates a separate context.
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];

        Profile sdrProfile = [SELECT Id FROM Profile WHERE Name = 'SDR' LIMIT 1];
        UserRole sdrRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'SDR' LIMIT 1];

        User sdrUser;
        System.runAs(adminUser) {
            sdrUser = new User(
                FirstName = 'Test', LastName = 'SDR',
                Email = 'ownership.test.sdr@example.com',
                Username = 'ownership.test.sdr@' + System.now().getTime() + '.test',
                Alias = 'tsdr2',
                ProfileId = sdrProfile.Id, UserRoleId = sdrRole.Id,
                TimeZoneSidKey = 'America/New_York', LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US'
            );
            insert sdrUser;
        }

        // Now create test data (non-setup objects)
        Account a = new Account(Name = 'Test Account');
        insert a;

        List<Opportunity> opps = new List<Opportunity>{
            new Opportunity(
                Name = 'Test Closed Won', AccountId = a.Id,
                StageName = 'Closed Won', CloseDate = Date.today(),
                Amount = 100000, Next_Step__c = 'Completed'
            ),
            new Opportunity(
                Name = 'Test Prospecting', AccountId = a.Id,
                StageName = 'Prospecting', CloseDate = Date.today().addDays(30)
            ),
            new Opportunity(
                Name = 'Test Negotiation', AccountId = a.Id,
                StageName = 'Negotiation', CloseDate = Date.today().addDays(15),
                Next_Step__c = 'Contract review'
            )
        };
        insert opps;
    }

    static User getSDR() {
        return [SELECT Id FROM User WHERE Email = 'ownership.test.sdr@example.com' LIMIT 1];
    }

    @isTest
    static void sdrBlockedFromChangingClosedWonOwnership() {
        User sdr = getSDR();
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Closed Won'];

        Test.startTest();
        System.runAs(sdr) {
            try {
                opp.OwnerId = sdr.Id;
                update opp;
                System.assert(false, 'SDR should not be able to change Closed Won ownership');
            } catch (DmlException e) {
                System.assert(e.getDmlMessage(0).contains('Closed Won'), 'Expected Closed Won error message');
            }
        }
        Test.stopTest();
    }

    @isTest
    static void sdrBlockedFromEditingClosedWonAmount() {
        User sdr = getSDR();
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Closed Won'];

        Test.startTest();
        System.runAs(sdr) {
            try {
                opp.Amount = 999999;
                update opp;
                System.assert(false, 'SDR should not be able to edit Closed Won amount');
            } catch (DmlException e) {
                System.assert(e.getDmlMessage(0).contains('locked'), 'Expected locked error message');
            }
        }
        Test.stopTest();
    }

    @isTest
    static void sdrCanReassignProspectingOpp() {
        User sdr = getSDR();
        User admin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Prospecting'];

        Test.startTest();
        System.runAs(sdr) {
            opp.OwnerId = admin.Id;
            update opp;
        }
        Test.stopTest();

        Opportunity updated = [SELECT OwnerId FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(admin.Id, updated.OwnerId, 'Ownership should have changed');
    }

    @isTest
    static void sdrBlockedFromReassigningNegotiationOpp() {
        User sdr = getSDR();
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Negotiation'];

        Test.startTest();
        System.runAs(sdr) {
            try {
                opp.OwnerId = sdr.Id;
                update opp;
                System.assert(false, 'SDR should not be able to reassign Negotiation opp');
            } catch (DmlException e) {
                System.assert(e.getDmlMessage(0).contains('Prospecting or Discovery'), 'Expected stage restriction message');
            }
        }
        Test.stopTest();
    }

    @isTest
    static void sdrBlockedFromChangingAccountOwnership() {
        User sdr = getSDR();
        Account acct = [SELECT Id FROM Account WHERE Name = 'Test Account'];

        Test.startTest();
        System.runAs(sdr) {
            try {
                acct.OwnerId = sdr.Id;
                update acct;
                System.assert(false, 'SDR should not be able to change Account ownership');
            } catch (DmlException e) {
                System.assert(e.getDmlMessage(0).contains('administrator'), 'Expected admin-only message');
            }
        }
        Test.stopTest();
    }

    @isTest
    static void adminCanChangeClosedWonOwnership() {
        User admin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        Opportunity opp = [SELECT Id, OwnerId FROM Opportunity WHERE Name = 'Test Closed Won'];

        Test.startTest();
        opp.OwnerId = admin.Id;
        update opp;
        Test.stopTest();

        Opportunity updated = [SELECT OwnerId FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(admin.Id, updated.OwnerId, 'Admin should be able to change ownership');
    }

    @isTest
    static void adminCanChangeAccountOwnership() {
        User admin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        Account acct = [SELECT Id FROM Account WHERE Name = 'Test Account'];

        Test.startTest();
        acct.OwnerId = admin.Id;
        update acct;
        Test.stopTest();

        Account updated = [SELECT OwnerId FROM Account WHERE Id = :acct.Id];
        System.assertEquals(admin.Id, updated.OwnerId, 'Admin should be able to change ownership');
    }
}
