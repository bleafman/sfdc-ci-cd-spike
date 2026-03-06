// Create a test SDR user to verify permission rules
// Only 2 Salesforce licenses in scratch orgs (1 used by admin), so we can only make 1 more

Profile sdrProfile = [SELECT Id FROM Profile WHERE Name = 'SDR' LIMIT 1];
UserRole sdrRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'SDR' LIMIT 1];

String orgDomain = [SELECT Username FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1].Username.substringAfter('@');

User sdrUser = new User(
    FirstName = 'Test',
    LastName = 'SDR',
    Email = 'test.sdr@' + orgDomain,
    Username = 'test.sdr@' + orgDomain,
    Alias = 'tsdr',
    ProfileId = sdrProfile.Id,
    UserRoleId = sdrRole.Id,
    TimeZoneSidKey = 'America/New_York',
    LocaleSidKey = 'en_US',
    EmailEncodingKey = 'UTF-8',
    LanguageLocaleKey = 'en_US'
);
insert sdrUser;

System.debug('Created SDR user: ' + sdrUser.Username + ' (ID: ' + sdrUser.Id + ')');
System.debug('Login as this user: sf org open --target-org poc-scratch --as-user ' + sdrUser.Username);
