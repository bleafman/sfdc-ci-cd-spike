// Test ownership and edit rules for different user profiles
// Verifies that validation rules enforce the expected restrictions

User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
User sdrUser = [SELECT Id FROM User WHERE Profile.Name = 'SDR' LIMIT 1];

// Get a Closed Won opportunity and a Prospecting opportunity
Opportunity closedOpp = [SELECT Id, OwnerId, StageName, Amount FROM Opportunity WHERE StageName = 'Closed Won' LIMIT 1];
Opportunity earlyOpp = [SELECT Id, OwnerId, StageName FROM Opportunity WHERE StageName = 'Prospecting' LIMIT 1];
Opportunity lateOpp = [SELECT Id, OwnerId, StageName FROM Opportunity WHERE StageName = 'Negotiation' LIMIT 1];
Account testAccount = [SELECT Id, OwnerId FROM Account LIMIT 1];

Integer passed = 0;
Integer failed = 0;

// --- Test 1: SDR tries to change Closed Won Opp ownership → SHOULD FAIL ---
System.runAs(sdrUser) {
    try {
        Opportunity o = new Opportunity(Id = closedOpp.Id, OwnerId = sdrUser.Id);
        update o;
        System.debug('FAIL - Test 1: SDR was able to change Closed Won Opp ownership');
        failed++;
    } catch (DmlException e) {
        System.debug('PASS - Test 1: SDR blocked from changing Closed Won Opp ownership');
        System.debug('  Error: ' + e.getDmlMessage(0));
        passed++;
    }
}

// --- Test 2: SDR tries to edit Closed Won Opp amount → SHOULD FAIL ---
System.runAs(sdrUser) {
    try {
        Opportunity o = new Opportunity(Id = closedOpp.Id, Amount = 999999);
        update o;
        System.debug('FAIL - Test 2: SDR was able to edit Closed Won Opp amount');
        failed++;
    } catch (DmlException e) {
        System.debug('PASS - Test 2: SDR blocked from editing Closed Won Opp amount');
        System.debug('  Error: ' + e.getDmlMessage(0));
        passed++;
    }
}

// --- Test 3: SDR reassigns early-stage Opp → SHOULD SUCCEED ---
System.runAs(sdrUser) {
    try {
        Opportunity o = new Opportunity(Id = earlyOpp.Id, OwnerId = adminUser.Id);
        update o;
        System.debug('PASS - Test 3: SDR reassigned Prospecting Opp ownership');
        passed++;
        // Restore original owner
        o.OwnerId = earlyOpp.OwnerId;
        update o;
    } catch (DmlException e) {
        System.debug('FAIL - Test 3: SDR was blocked from reassigning Prospecting Opp');
        System.debug('  Error: ' + e.getDmlMessage(0));
        failed++;
    }
}

// --- Test 4: SDR tries to reassign Negotiation-stage Opp → SHOULD FAIL ---
System.runAs(sdrUser) {
    try {
        Opportunity o = new Opportunity(Id = lateOpp.Id, OwnerId = sdrUser.Id);
        update o;
        System.debug('FAIL - Test 4: SDR was able to reassign Negotiation Opp');
        failed++;
    } catch (DmlException e) {
        System.debug('PASS - Test 4: SDR blocked from reassigning Negotiation Opp');
        System.debug('  Error: ' + e.getDmlMessage(0));
        passed++;
    }
}

// --- Test 5: SDR tries to change Account ownership → SHOULD FAIL ---
System.runAs(sdrUser) {
    try {
        Account a = new Account(Id = testAccount.Id, OwnerId = sdrUser.Id);
        update a;
        System.debug('FAIL - Test 5: SDR was able to change Account ownership');
        failed++;
    } catch (DmlException e) {
        System.debug('PASS - Test 5: SDR blocked from changing Account ownership');
        System.debug('  Error: ' + e.getDmlMessage(0));
        passed++;
    }
}

// --- Test 6: Admin changes Closed Won Opp ownership → SHOULD SUCCEED ---
try {
    Opportunity o = new Opportunity(Id = closedOpp.Id, OwnerId = adminUser.Id);
    update o;
    System.debug('PASS - Test 6: Admin changed Closed Won Opp ownership');
    passed++;
    // Restore
    o.OwnerId = closedOpp.OwnerId;
    update o;
} catch (DmlException e) {
    System.debug('FAIL - Test 6: Admin was blocked from changing Closed Won Opp ownership');
    System.debug('  Error: ' + e.getDmlMessage(0));
    failed++;
}

// --- Test 7: Admin changes Account ownership → SHOULD SUCCEED ---
try {
    Account a = new Account(Id = testAccount.Id, OwnerId = adminUser.Id);
    update a;
    System.debug('PASS - Test 7: Admin changed Account ownership');
    passed++;
} catch (DmlException e) {
    System.debug('FAIL - Test 7: Admin was blocked from changing Account ownership');
    System.debug('  Error: ' + e.getDmlMessage(0));
    failed++;
}

System.debug('========================================');
System.debug('Results: ' + passed + '/' + (passed + failed) + ' tests passed');
if (failed > 0) {
    System.debug('WARNING: ' + failed + ' test(s) failed!');
}
