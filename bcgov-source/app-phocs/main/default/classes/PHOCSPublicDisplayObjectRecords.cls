global without sharing class PHOCSPublicDisplayObjectRecords implements Callable{
    global Object call(String action, Map<String,Object> args){
        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');
        
        return invokeMethod(action, input, output, options);
        
    }
    private Object invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
         List<SObject> lstSobject = new List<SObject>();
        if(methodName == 'getInspectionDetails'){
            system.debug('options'+options);
			system.debug('InputMAP'+inputMap);
            lstSobject =  getDynamicQueryResults(String.valueof(inputMap.get('objectAPIName')));
        }
        if(methodName == 'getRecordById'){
            system.debug('options'+options);
			system.debug('InputMAP'+inputMap);
            lstSobject =  getRecordById(String.valueof(inputMap.get('recordId')));
        }
         if(methodName == 'getRelatedListById'){
            system.debug('options'+options);
			system.debug('InputMAP'+inputMap);
            lstSobject =  getRelatedListById(String.valueof(inputMap.get('recordId')),String.valueof(inputMap.get('childSobjectAPIName')));
        }
        return outMap.put('result',lstSobject);
    }
    
    //Method to get Sobject Details as list of records for list view
     public static List<SObject> getDynamicQueryResults(String objectName) {
        PHOCSSobjectVsQuery__mdt queryConfig = [
            SELECT ObjectQuery__c 
            FROM PHOCSSobjectVsQuery__mdt 
            WHERE Type__c = 'List' AND SobjectAPIName__c = :objectName 
            LIMIT 1
        ];

        if (queryConfig == null || String.isBlank(queryConfig.ObjectQuery__c)) {
            throw new QueryException('No SOQL query found for object: ' + objectName);
        }

        String soqlQuery = queryConfig.ObjectQuery__c;

        List<SObject> results = Database.query(soqlQuery);
		//results = Security.stripInaccessible(AccessType.READABLE, results).getRecords();//To Enforce Read Access on fields.

        return results;
    }
     //Method to get Sobject record for record detail page
     public static List<SObject> getRecordById(Id recordId) {
        if (recordId == null) {
            throw new AuraHandledException('Record ID is required.');
        }
         String objectName = recordId.getSObjectType().getDescribe().getName();
         system.debug('ObjectName'+objectName);
         
         PHOCSSobjectVsQuery__mdt queryConfig = [
                 SELECT ObjectQuery__c 
                 FROM PHOCSSobjectVsQuery__mdt 
                 WHERE Type__c = 'Record' AND SobjectAPIName__c = :objectName 
                 LIMIT 1
             ];

        if (queryConfig == null || String.isBlank(queryConfig.ObjectQuery__c)) {
            throw new QueryException('No SOQL query found for object: ' + objectName);
        }

        String soqlQuery = queryConfig.ObjectQuery__c;
        String query = soqlQuery + ' WHERE Id = :recordId LIMIT 1';
        System.debug('query' + query);

        List<SObject> results = Database.query(query);
        return results;
    }
    //Method to get Sobject related list 
     public static List<SObject> getRelatedListById(Id recordId, String childSobjectAPIName) {
        if (recordId == null || childSobjectAPIName == Null) {
            throw new AuraHandledException('Record ID is required.');
        }
         String parentSObjectName = recordId.getSObjectType().getDescribe().getName();
         system.debug('ParentObjectName'+parentSObjectName);
         system.debug('ChildObjectName'+childSobjectAPIName);
         
         
         PHOCSSobjectVsQuery__mdt queryConfig = [
                 SELECT ObjectQuery__c 
                 FROM PHOCSSobjectVsQuery__mdt 
                 WHERE Type__c = 'Related' AND ParentSobjectAPIName__c =:parentSObjectName AND ChildSobjectAPIName__c = :childSobjectAPIName AND SobjectAPIName__c = :childSobjectAPIName 
             
             ];

        if (queryConfig == null || String.isBlank(queryConfig.ObjectQuery__c)) {
            throw new QueryException('No SOQL query found for object: ' + childSobjectAPIName);
        }

         String soqlQuery = queryConfig.ObjectQuery__c;
         //RegulatoryCodeViolation Related List for Visit
         if(parentSObjectName == 'Visit' &&  childSobjectAPIName == 'RegulatoryCodeViolation'){
             soqlQuery = soqlQuery + ' WHERE InspectionId = :recordId';
             
         }
		 //Inspection Related List for Account
         if(parentSObjectName == 'Account' &&  childSobjectAPIName == 'Visit'){
             soqlQuery = soqlQuery + ' AND AccountId = :recordId';
             
         }
          //Violation Enforcement Actions Related List for Regulatory Code Violation
         if(parentSObjectName == 'RegulatoryCodeViolation' &&  childSobjectAPIName == 'ViolationEnforcementAction'){
             soqlQuery = soqlQuery + ' WHERE violationId = :recordId ';
             
         }
         System.debug('query' + soqlQuery);

        List<SObject> results = Database.query(soqlQuery);
         system.debug('Results-------------->'+results);
        return results;
    }
    
}