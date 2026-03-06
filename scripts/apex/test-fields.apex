// Test if custom fields are accessible in Apex
Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Opportunity.fields.getMap();
System.debug('Deal_Source__c exists: ' + fieldMap.containsKey('Deal_Source__c'));
System.debug('Expected_Contract_Value__c exists: ' + fieldMap.containsKey('Expected_Contract_Value__c'));
System.debug('Next_Step__c exists: ' + fieldMap.containsKey('Next_Step__c'));

// Try dynamic assignment
Opportunity o = new Opportunity();
o.put('Deal_Source__c', 'Inbound');
o.put('Expected_Contract_Value__c', 50000);
o.put('Next_Step__c', 'Test value');
System.debug('Dynamic assignment worked: ' + o);
