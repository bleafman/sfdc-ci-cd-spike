// Grant field-level security for custom Opportunity fields to System Administrator
String psId = [SELECT Id FROM PermissionSet WHERE IsOwnedByProfile = true AND Profile.Name = 'System Administrator' LIMIT 1].Id;

List<FieldPermissions> fps = new List<FieldPermissions>();
for (String fieldName : new List<String>{'Opportunity.Deal_Source__c', 'Opportunity.Expected_Contract_Value__c', 'Opportunity.Next_Step__c'}) {
    fps.add(new FieldPermissions(
        SobjectType = 'Opportunity',
        Field = fieldName,
        PermissionsRead = true,
        PermissionsEdit = true,
        ParentId = psId
    ));
}
insert fps;
System.debug('FLS granted for ' + fps.size() + ' fields');
