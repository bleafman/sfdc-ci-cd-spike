Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Opportunity.fields.getMap();
for (String key : fieldMap.keySet()) {
    if (key.contains('__c') || key.contains('deal') || key.contains('next') || key.contains('expected')) {
        System.debug('Found field: ' + key);
    }
}
System.debug('Total fields: ' + fieldMap.size());
