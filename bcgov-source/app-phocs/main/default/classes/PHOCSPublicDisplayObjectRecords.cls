global without sharing class PHOCSPublicDisplayObjectRecords implements Callable{

    global Object call(String action, Map<String,Object> args){
        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');
        // METHODS FOR GUEST USERS
        if(action == 'getRecordsList'){
            List<Object> lstSobjects =  getRecordsList(String.valueof(input.get('configName')));
            output.put('result', lstSobjects);
            return output;
        }
        if(action == 'getRelatedList'){
            List<Object> lstSobjects =  getRelatedList(String.valueof(input.get('recordId')),String.valueof(input.get('configName')));
            output.put('result',lstSobjects);
            return output;
        }
        if(action == 'getRecordDetails'){
            List<Object> lstSobjects =  getRecordDetails(String.valueof(input.get('recordId')), String.valueof(input.get('configName')));
            output.put('result',lstSobjects);
            return output;
        }
        if(action == 'getFacilityList'){
            List<Object> lstSobjects =  getFacilityList(String.valueof(input.get('programArea')) , String.valueof(input.get('filterItems')));
            output.put('result', lstSobjects);
            return output;
        }
        // METHODS FOR PORTAL USERS
        // Methods to call for Portal user in class PHOCSOperatorPortalDisplayRecords  to imply portal user sharing rules.
         if(action == 'getRecordsListPortal'){
            List<Object> lstSobjects =  PHOCSOperatorPortalDisplayRecords.getRecordsList(String.valueof(input.get('configName')));
            output.put('result', lstSobjects);
            return output;
        }
         if(action == 'getRecordDetailsPortal'){
            List<Object> lstSobjects = PHOCSOperatorPortalDisplayRecords.getRecordDetails(String.valueof(input.get('recordId')), String.valueof(input.get('configName')));
            output.put('result',lstSobjects);
            return output;
        }
        if(action == 'getRelatedListPortal'){
            List<Object> lstSobjects = PHOCSOperatorPortalDisplayRecords.getRelatedList(String.valueof(input.get('recordId')), String.valueof(input.get('configName')));
            output.put('result',lstSobjects);
            return output;
        }

        return invokeMethod(action, input, output, options);
        
    }
    private Object invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
         List<SObject> lstSobject = new List<SObject>();
        if(methodName == 'getInspectionDetails'){
            lstSobject =  getDynamicQueryResults(String.valueof(inputMap.get('objectAPIName')));
        }
        if(methodName == 'getRecordById'){
            lstSobject =  getRecordById(String.valueof(inputMap.get('recordId')));
        }
         if(methodName == 'getRelatedListById'){
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

        List<SObject> results = Database.query(queryConfig.ObjectQuery__c);  // NOPMD

        return results;
    }

     //Method to get Sobject record for record detail page
     public static List<SObject> getRecordById(Id recordId) {
        if (recordId == null) {
            throw new AuraHandledException('Record ID is required.');
        }
         String objectName = recordId.getSObjectType().getDescribe().getName();
         
         PHOCSSobjectVsQuery__mdt queryConfig = [
                 SELECT ObjectQuery__c ,ParentFieldAPIName__c
                 FROM PHOCSSobjectVsQuery__mdt 
                 WHERE Type__c = 'Record' AND SobjectAPIName__c = :objectName 
                 LIMIT 1
             ];

        if (queryConfig == null || String.isBlank(queryConfig.ObjectQuery__c)) {
            throw new QueryException('No SOQL query found for object: ' + objectName);
        }

        String soqlQuery = queryConfig.ObjectQuery__c;
        String query = soqlQuery;
        if(soqlQuery.indexOf('LIMIT') == -1){
            if(string.isNotBlank(queryConfig.ParentFieldAPIName__c)){
                 query = soqlQuery + ' AND ' + queryConfig.ParentFieldAPIName__c + ' = :recordId';
            }else if(soqlQuery.indexOf('WHERE') == -1){
                  query = soqlQuery + ' WHERE Id = :recordId LIMIT 1';
            }
        }

        List<SObject> results = Database.query(query); // NOPMD
        return results;
    }
    //Method to get Sobject related list 
     public static List<SObject> getRelatedListById(Id recordId, String childSobjectAPIName) {
        if (recordId == null || childSobjectAPIName == Null) {
            throw new AuraHandledException('Record ID is required.');
        }
         String parentSObjectName = recordId.getSObjectType().getDescribe().getName();

         PHOCSSobjectVsQuery__mdt queryConfig = [
                 SELECT ObjectQuery__c, ParentFieldAPIName__c 
                 FROM PHOCSSobjectVsQuery__mdt 
                 WHERE Type__c = 'Related' AND 
                       ParentSobjectAPIName__c =:parentSObjectName AND 
                       ChildSobjectAPIName__c = :childSobjectAPIName AND 
                       SobjectAPIName__c = :childSobjectAPIName 
                LIMIT 1
             ];

        if (queryConfig == null || String.isBlank(queryConfig.ObjectQuery__c)) {
            throw new QueryException('No SOQL query found for object: ' + childSobjectAPIName);
        }

         String soqlQuery = queryConfig.ObjectQuery__c;

         if(string.isNotBlank(queryConfig.ParentFieldAPIName__c)){
            soqlQuery = soqlQuery + ' WHERE ' + queryConfig.ParentFieldAPIName__c + ' = :recordId';
         }
         if(parentSObjectName == 'Account' &&  childSobjectAPIName == 'Visit'){  //Inspection Related List for Account
            soqlQuery = soqlQuery + ' AND AccountId = :recordId';  
         }         

        List<SObject> results = Database.query(soqlQuery);// NOPMD
        return results;
    }
    
     // === Record Details with Wrapper ==
     public static List<Object> getRecordDetails(Id recordId, string configName) {
        if (recordId == null) {
            throw new AuraHandledException('Record ID is required.');
        }
        
        List<Object> results = new List<Object>(); 
        Map<String, SObjectWrapper> wrapperRegistry = new Map<String, SObjectWrapper>{
            'Account' => new AccountDetailsWrapper(),
            'LabTestRequisition__c' => new LabTestRequisitionDetailsWrapper(),
            'Case' => new CaseDetailsWrapper(),
            'RegulatoryTrxnFeeItem' => new RegulatoryTrxnFeeItemDetailsWrapper()
        };
            
         String objectName = recordId.getSObjectType().getDescribe().getName();
         SObjectWrapper wrapper = wrapperRegistry.get(objectName);
         
         String soqlQuery;        
         if(string.isNotBlank(configName)){
            PHOCSSobjectVsQuery__mdt queryConfig = [
                 SELECT ObjectQuery__c 
                 FROM PHOCSSobjectVsQuery__mdt 
                 WHERE Type__c = 'Record' AND DeveloperName= :configName 
                 LIMIT 1
             ];
             soqlQuery = queryConfig.ObjectQuery__c;
         }else{
             soqlQuery = getRecordDetailsQuery(recordId);
         }

        List<SObject> queryResults = Database.query(soqlQuery);// NOPMD
        if(!queryResults.isEmpty()){
            if(wrapper != null){
                results.add(wrapper.wrap(queryResults[0]));
            }else{
                results.add(queryResults[0]);
            }
        }
        return results;
    }
    
    // === RELATED LIST QUERY WITH WRAPPER ===
    public static List<Object> getRelatedList(Id recordId, string configName) {

        Map<String, SObjectWrapper> wrapperRegistry = new Map<String, SObjectWrapper>{
            'LabTestRequired__c' => new LabTestRequiredListWrapper(),
            'InspectionAssessmentInd' => new InspectionAssessmentIndDetailsWrapper(),
            'Visit' => new InspectionListWrapper()
        };
        
        if (recordId == null) {
            throw new AuraHandledException('Record ID required.');
        }

        String parentSObjectName = recordId.getSObjectType().getDescribe().getName();
        PHOCSSobjectVsQuery__mdt queryConfig = [
            SELECT ObjectQuery__c, ParentFieldAPIName__c, ChildSobjectAPIName__c
            FROM PHOCSSobjectVsQuery__mdt 
            WHERE Type__c = 'Related'AND 
                  DeveloperName= :configName
            LIMIT 1
        ];
        if (queryConfig == null || String.isBlank(queryConfig.ObjectQuery__c)) {
            throw new QueryException('No SOQL query found for related list object');
        }

        SObjectWrapper wrapper = wrapperRegistry.get(queryConfig.ChildSobjectAPIName__c);
        List<Object> results = new List<Object>();
        
        List<SObject> queryResults = Database.query(queryConfig.ObjectQuery__c);// NOPMD
        for (SObject sObj : queryResults) {        
            if (wrapper != null) {
                results.add(wrapper.wrap(sObj));
            } else {
                results.add(sObj);
            }
        }
        return results;
    }
    
    // === RELATED LIST QUERY WITH WRAPPER ===
    public static List<Object> getRecordsList(string configName) {

        Map<String, SObjectWrapper> wrapperRegistry = new Map<String, SObjectWrapper>{
            'FacilitiesList' => new FacilityWrapper()        
        };
        PHOCSSobjectVsQuery__mdt queryConfig = [
            SELECT ObjectQuery__c, ParentFieldAPIName__c, ChildSobjectAPIName__c,SobjectAPIName__c,DeveloperName
            FROM PHOCSSobjectVsQuery__mdt 
            WHERE Type__c = 'List'AND 
                  DeveloperName= :configName
            LIMIT 1
        ];
        if (queryConfig == null || String.isBlank(queryConfig.ObjectQuery__c)) {
            throw new QueryException('No SOQL query found for related list object');
        }

        SObjectWrapper wrapper = wrapperRegistry.get(queryConfig.DeveloperName);
        List<Object> results = new List<Object>();
        for (SObject sObj : Database.query(queryConfig.ObjectQuery__c)) {        // NOPMD
            if (wrapper != null) {
                results.add(wrapper.wrap(sObj)); 
            } else {
                results.add(sObj);
            }
        }
        return results; 
    }
    
     public static String getRecordDetailsQuery(Id recordId) {
        SObjectType objType = recordId.getSObjectType();
        DescribeSObjectResult describeResult = objType.getDescribe();
        String objectName = describeResult.getName();

        Map<String, Schema.SObjectField> fieldsMap = describeResult.fields.getMap();

        List<String> fieldNames = new List<String>();
        for (String fieldName : fieldsMap.keySet()) {
            fieldNames.add(fieldName);
        }

        String query = 'SELECT ' + String.join(fieldNames, ', ') + ' FROM ' + objectName + ' WHERE Id = \'' + recordId + '\'';
        return query;
    }
    
    
    public static List<Object> getFacilityList(string programArea,string filterItems) {
        system.debug('filterItems--------->'+ filterItems);
        List<Object> results = new List<Object>();
        FacilityWrapper wrapper = new FacilityWrapper();
        String query;
        system.debug('-----filterItems---'+filterItems);
        if(filterItems == null){
         query = 'SELECT Id,Name,Type,Physical_Address__City__s, CategoryL1__c,CategoryL2__c,HealthAuthority__c,Phone,ParentAccount__r.Name,' +
                              'FacilityCHSAText__c,Physical_Address__c, PHOCSNumberOfInspections__c,' +
                              'PHOCSOutstandingViolations__c, PHOCSLastInspectionDate__c ' +
                        'FROM Account';
        }else{
            query = 'SELECT Id, Name, Type, Physical_Address__City__s, CategoryL1__c, CategoryL2__c, HealthAuthority__c, Phone, ParentAccount__r.Name, ' +
                'Physical_Address__c, FacilityCHSAText__c,PHOCSNumberOfInspections__c, ' +
                'PHOCSOutstandingViolations__c, PHOCSLastInspectionDate__c ' +
                'FROM Account ' ;
        }
            system.debug('-----query---'+query);
            query += getFacilitiesFilter(programArea,filterItems);
                    system.debug('-----query---'+query);

        for (Account sObj : Database.query(query)) {  // NOPMD      
           results.add(wrapper.wrap(sObj));
        }
        system.debug('----->'+results);
        return results;
    }
                                                                
    private static string getFacilitiesFilter(string programArea, String filterItems){
        String returnQuery;
        switch on programArea {
            when 'food' {
               returnQuery = ' Where RecordType.DeveloperName=\'Facility\' AND Type=\'Food\' AND Status__c = \'Open\'';
               returnQuery = addFlexCardFilters(filterItems,returnQuery);
               return returnQuery;
            }   
            when 'drinkingwatersystem' { 
               returnQuery = ' Where RecordType.DeveloperName=\'DrinkingWaterSystem\' AND Type=\'Drinking Water\' AND Status__c = \'Open\'';
               returnQuery = addFlexCardFilters(filterItems,returnQuery);
               return returnQuery;
            }
            when 'residentialcare' {
               returnQuery = ' Where RecordType.DeveloperName=\'Facility\' AND  Status__c = \'Open\' AND Type=\'Residential Care\''; // Rahul Patle : 13-04-26 :  removed as part of 3165 - AND CategoryL1__c IN (\'Licensing - Residential\',\'Unlawful – Residential Licensing\',\'Hospital Act\')
               returnQuery = addFlexCardFilters(filterItems,returnQuery);
			   return returnQuery;
            }
            when 'hospital' {
                returnQuery =' Where RecordType.DeveloperName=\'Facility\' AND  Status__c = \'Open\' AND Type=\'Residential Care\' AND CategoryL1__c=\'Hospital Act\''; 
				returnQuery = addFlexCardFilters(filterItems,returnQuery);
                return returnQuery;
            }
            when 'childcare' {
               returnQuery =  ' Where RecordType.DeveloperName=\'Facility\' AND  Status__c = \'Open\' AND Type=\'Child Care\'';
			   returnQuery = addFlexCardFilters(filterItems,returnQuery);
               return returnQuery;
            }
            when 'personalservices' {
               returnQuery = ' Where RecordType.DeveloperName=\'Facility\' AND  Status__c = \'Open\' AND Type=\'Personal Services\'';
			   returnQuery = addFlexCardFilters(filterItems,returnQuery);
               return returnQuery;
            }   
            when 'tobaccovapour' {     
               returnQuery = ' Where RecordType.DeveloperName=\'Facility\' AND  Status__c = \'Open\' AND Type=\'Tobacco and Vapour\'';
			   returnQuery = addFlexCardFilters(filterItems,returnQuery);
               return returnQuery;
            }
            when 'recreationalwater' {
               returnQuery =  ' Where RecordType.DeveloperName=\'Facility\' AND Status__c = \'Open\' AND Type=\'Recreational Water\'';
			   returnQuery = addFlexCardFilters(filterItems,returnQuery);
               return returnQuery;
            }
            when 'industrial-camps' {
               returnQuery = ' Where RecordType.DeveloperName=\'Facility\' AND Status__c = \'Open\' AND Type=\'Industrial Camps\'';
			   returnQuery = addFlexCardFilters(filterItems,returnQuery);
               return returnQuery;
            }
            when 'sewerage-facilities' {
               returnQuery = ' Where RecordType.DeveloperName=\'Facility\' AND Status__c = \'Open\' AND Type=\'Sewerage\'';
			   returnQuery = addFlexCardFilters(filterItems,returnQuery);
               return returnQuery;
            }
            when 'childcareowl'{
               returnQuery = ' Where RecordType.DeveloperName=\'Facility\' AND Status__c = \'closed\' AND Type=\'Child Care\' AND OWLPublicRetentionActive__c = true';
			   returnQuery = addFlexCardFilters(filterItems,returnQuery);
               return returnQuery;
            }
            when 'residentialcareowl'{
               returnQuery = ' Where RecordType.DeveloperName=\'Facility\' AND Status__c = \'closed\' AND Type=\'Residential Care\' AND OWLPublicRetentionActive__c = true';
			   returnQuery = addFlexCardFilters(filterItems,returnQuery);
               return returnQuery;
            }
        }
        return '';
    }
    
    private static string getAddress(Address physicalAddress){
        string[] returnAddress = new string[]{};
        if(physicalAddress != null){
            if(string.isNotBlank(physicalAddress.getStreet())){
                returnAddress.add(physicalAddress.getStreet()); 
            }
            if(string.isNotBlank(physicalAddress.getCity())){
                returnAddress.add(physicalAddress.getCity()); 
            }
            if(string.isNotBlank(physicalAddress.getState())){
                returnAddress.add(physicalAddress.getState()); 
            }
            if(string.isNotBlank(physicalAddress.getCountry())){
                returnAddress.add(physicalAddress.getCountry()); 
            }
            if(string.isNotBlank(physicalAddress.getPostalCode())){
                returnAddress.add(physicalAddress.getPostalCode()); 
            }
            return String.join(returnAddress, ',');
        }
        return '';
    }
    public interface SObjectWrapper {
        Object wrap(SObject record);
    }

   public class AccountDetailsWrapper implements SObjectWrapper {
        public Object wrap(SObject record) {
            Account accRecord = (Account) record;
            Map<String, Object> result = new Map<String, Object>{
                'Id' => accRecord.Id,
                'Name' => accRecord.Name,
                'Type'=> accRecord.Type,
                'CategoryL1__c'=> accRecord.CategoryL1__c,
                'CategoryL2__c'=> accRecord.CategoryL2__c,
                'HealthAuthority__c'=> accRecord.HealthAuthority__c,
                'Phone'=> accRecord.Phone,
                'ParentAccount' => accRecord.ParentAccount__r.Name,
                'PHOCSOutstandingViolations__c'=> accRecord.PHOCSOutstandingViolations__c,
                'OperatingMonths__c'=> accRecord.OperatingMonths__c,
                'FacilityCHSAText__c'=> accRecord.FacilityCHSAText__c,
                'PhysicalAddress' => getAddress(accRecord.Physical_Address__c),
                'PhysicalAddressStreet'=> accRecord.Physical_Address__c?.getStreet(),
                'PhysicalAddressPostalCode'=> accRecord.Physical_Address__c?.getPostalCode(),
                'PhysicalAddressCity'=> accRecord.Physical_Address__c?.getCity(),
                'PhysicalAddressState'=> accRecord.Physical_Address__c?.getState(),
                'PhysicalAddressStateCode'=> accRecord.Physical_Address__c?.getStateCode(),
                'PhysicalAddressCountry'=> accRecord.Physical_Address__c?.getCountry(),
                'PhysicalAddressCountryCode'=> accRecord.Physical_Address__c?.getCountryCode()
            };
            return result;
        }
    }
    public class FacilityWrapper implements SObjectWrapper {
        public Object wrap(SObject record) {
            Date phocsLastInspectionDate ;
            Account accRecord = (Account) record;
            if(accRecord.PHOCSLastInspectionDate__c != null){
                Datetime dt =  accRecord.PHOCSLastInspectionDate__c;
                phocsLastInspectionDate = dt.date();
            }

	            Map<String, Object> result = new Map<String, Object>{
                'Id' => accRecord.Id,
                'Type'=> accRecord.Type,
                'CategoryL1__c'=> accRecord.CategoryL1__c,
                'CategoryL2__c'=> accRecord.CategoryL2__c,
                'FacilityCHSAText__c'=> accRecord.FacilityCHSAText__c,
                'HealthAuthority__c'=> accRecord.HealthAuthority__c, 
                'LastInspectionDate__c ' => phocsLastInspectionDate,
                'Name' => accRecord.Name,
                'PHOCSNumberOfInspections__c' => accRecord.PHOCSNumberOfInspections__c,
                'PHOCSOutstandingViolations__c'=> accRecord.PHOCSOutstandingViolations__c,
                'PhysicalAddress' => getAddress(accRecord.Physical_Address__c),
                'PhysicalAddressStreet'=> accRecord.Physical_Address__c?.getStreet(),
                'PhysicalAddressCity'=> accRecord.Physical_Address__c?.getCity(),
                'PhysicalAddressState'=> accRecord.Physical_Address__c?.getState(),
                'PhysicalAddressCountry'=> accRecord.Physical_Address__c?.getCountry(),
                'PhysicalAddressPostalCode'=> accRecord.Physical_Address__c?.getPostalCode()
            };
            return result;
        }
    } 
    
    public class CaseDetailsWrapper implements SObjectWrapper {
        public Object wrap(SObject record) {
            Case caseRecord = (Case) record;
            Map<String, Object> result = new Map<String, Object>{
                'Id' => caseRecord.Id,
                'CaseNumber' => caseRecord.CaseNumber,
                'TypeOfAdvisory' => caseRecord.TypeOfAdvisory__c,
                'LastModifiedDate'=> caseRecord.LastModifiedDate,
                'ReasonForAdvisory'=> caseRecord.ReasonForAdvisory__c,
                'AccountId' => caseRecord.AccountId,
                'AccountName'=> caseRecord.Account.Name,
                'AccountPhone'=> caseRecord.Account.Phone,
                'AccountWebsite'=> caseRecord.Account.Website,
                'PopulationServedper24hrs' => caseRecord.Account.PopulationServedper24hrs__c 
            };
            return result;
        }
    } 
    public class LabTestRequisitionDetailsWrapper implements SObjectWrapper {
        public Object wrap(SObject record) {
            LabTestRequisition__c lab = (LabTestRequisition__c) record;
            Map<String, Object> result = new Map<String, Object>{
                'Name' => lab.Name,
                'FacilityName' => lab.FacilityName__r?.Name,
                'FacilityAccountId' => lab.FacilityName__c,
                'PhysicalAddressStreet'=> lab.FacilityName__r?.Physical_Address__c?.getStreet(),
                'PhysicalAddressCity'=> lab.FacilityName__r?.Physical_Address__c?.getCity(),
                'PhysicalAddressState'=> lab.FacilityName__r?.Physical_Address__c?.getState(),
                'PhysicalAddressCountry'=> lab.FacilityName__r?.Physical_Address__c?.getCountry(),
                'PhysicalAddressPostalCode'=> lab.FacilityName__r?.Physical_Address__c?.getPostalCode(),
                'SamplingSiteName' => lab.SamplingSite__r?.Name,
                'CollectionDateTime' => lab.CollectionDateTime__c
            };
            return result;
        }
    }
    
     public class RegulatoryTrxnFeeItemDetailsWrapper implements SObjectWrapper {
        public Object wrap(SObject record) {
            RegulatoryTrxnFeeItem regulatoryTrxnFeeItemRecord = (RegulatoryTrxnFeeItem) record;
            Map<String, Object> result = new Map<String, Object>{
                'Id' => regulatoryTrxnFeeItemRecord.Id,
                'Name' => regulatoryTrxnFeeItemRecord.Name,
                'FeeAmount'=> regulatoryTrxnFeeItemRecord.FeeAmount,
                'RegulatoryTrxnFeeId'=> regulatoryTrxnFeeItemRecord.RegulatoryTrxnFee.Id,
                'RegulatoryTrxnFeeName'=> regulatoryTrxnFeeItemRecord.RegulatoryTrxnFee.Name,
                'Comments'=> regulatoryTrxnFeeItemRecord.Comments
            };
            return result;
        }
    }

    public class InspectionListWrapper implements SObjectWrapper {
        public Object wrap(SObject record) {
            Visit inspection = (Visit) record;
            Map<String, Object> result = new Map<String, Object>{
                'Id' => inspection.Id,
                'Name' => inspection.Name,
                'AccountName' => inspection.Account.Name,
                'ActualVisitStartTime' => inspection.ActualVisitStartTime,
                'InspectionType' => inspection.VisitType.Name,
                'PHOCSViolationCount' => inspection.PHOCSViolationCount__c
            };
            return result;
        }
    }
    public class LabTestRequiredListWrapper implements SObjectWrapper {
        public Object wrap(SObject record) {
            LabTestRequired__c lab = (LabTestRequired__c) record;
            Map<String, Object> result = new Map<String, Object>{
                'Name' => lab.Name,
                'TestCategory' => lab.TestCategory__c,
                'UnitOfMeasure' => lab.UnitOfMeasure__c,
                'ResultValue' => lab.ResultValue__c,
                'TestId' => lab.Test__c,
                'TestName' => lab.Test__r?.Name
            };
            return result;
        }
    }
     public class InspectionAssessmentIndDetailsWrapper implements SObjectWrapper {
        public Object wrap(SObject record) {
            InspectionAssessmentInd iaiRecord = (InspectionAssessmentInd) record;
            Map<String, Object> result = new Map<String, Object>{
                'Id' => iaiRecord.Id,
                'AssessmentIndDefinitionCategory' => iaiRecord.AssessmentIndDefinition.Category__c,
                'AssessmentIndDefinitionName'=> iaiRecord.AssessmentIndDefinition.Name,
                'TextFieldResponse'=> iaiRecord.TextFieldResponse,
                'Result'=> iaiRecord.Result
            };
            return result;
        }
    }
    private static String addFlexCardFilters(String filterItems, String returnQuery){
        String filters  = filterItems == null ? returnQuery : returnQuery + ' AND ( HealthAuthority__c = \''+filterItems+'\' OR Physical_Address__city__s  = \''+filterItems+'\')';
        return filters;
    }
}