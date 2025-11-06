public with sharing class PHOCSOperatorPortalDisplayRecords{
            
    public static Id getAccountIdForCommunityUser() {
        User currentUser = [SELECT Id, Profile.Name, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Boolean isCommunityUser = currentUser.Profile.Name.contains('Customer Community Operator');
        if (isCommunityUser && currentUser.ContactId != null) {
            Contact con = [SELECT Id, AccountId FROM Contact WHERE Id = :currentUser.ContactId LIMIT 1];
            return con.AccountId;
        }
        return null;
    }

    public static List<Object> getRecordsList(string configName) {

        Map<String, SObjectWrapper> wrapperRegistry = new Map<String, SObjectWrapper>{
            'BusinessLicense' => new BusinessLicenseListWrapper(),
            'BusinessLicenseApplication' => new BusinessLicenseApplicationListWrapper()
        };

        PHOCSSobjectVsQuery__mdt queryConfig = [
            SELECT ObjectQuery__c,SobjectAPIName__c,DeveloperName
            FROM PHOCSSobjectVsQuery__mdt 
            WHERE Type__c = 'List' AND 
                  DeveloperName =:configName
            LIMIT 1
        ];
        if (queryConfig == null || String.isBlank(queryConfig.ObjectQuery__c)) {
            throw new QueryException('No SOQL query found for record list object');
        }
        system.debug('QueryFormed------->'+queryConfig.ObjectQuery__c);

        SObjectWrapper wrapper = wrapperRegistry.get(queryConfig.SobjectAPIName__c);
        List<Object> results = new List<Object>();
        
        List<SObject> queryResults = Database.query(queryConfig.ObjectQuery__c);
        for (SObject sObj : queryResults) {        
            if (wrapper != null) {
                results.add(wrapper.wrap(sObj));
            } else {
                results.add(sObj);
            }
        }
        return results;
    }
    
     public static List<Object> getRecordDetails(Id recordId, string configName) {
        if (recordId == null) {
            throw new AuraHandledException('Record ID is required.');
        }
        List<Object> results = new List<Object>(); 
        Map<String, SObjectWrapper> wrapperRegistry = new Map<String, SObjectWrapper>{
            'PortalBLADetail' => new BusinessLicenseListApplicationDetailWrapper()
        };
            
        SObjectWrapper wrapper = wrapperRegistry.get(configName);
         
        String soqlQuery;        
        if(string.isNotBlank(configName)){
           PHOCSSobjectVsQuery__mdt queryConfig = [
                 SELECT ObjectQuery__c 
                 FROM PHOCSSobjectVsQuery__mdt 
                 WHERE Type__c = 'Record' AND DeveloperName= :configName 
                 LIMIT 1
           ];
           soqlQuery = queryConfig.ObjectQuery__c;
        }

        List<SObject> queryResults = Database.query(soqlQuery);// NOPMD
        if(!queryResults.isEmpty()){
            if(wrapper != null){
            	results.add(wrapper.wrap(queryResults[0]));
            }else{
                results.add(queryResults[0]);
            }
        }
        System.debug('results'+results);
        return results;
    }

         public static List<Object> getRelatedList(Id recordId, string configName) {

        Map<String, SObjectWrapper> wrapperRegistry = new Map<String, SObjectWrapper>{
            'BusinessLicenseApplication' => new BusinessLicenseApplicationListWrapper()
        };
        
        if (recordId == null) {
            throw new AuraHandledException('Record ID required.');
        }

        String parentSObjectName = recordId.getSObjectType().getDescribe().getName();
        PHOCSSobjectVsQuery__mdt queryConfig = [
            SELECT ObjectQuery__c, ParentFieldAPIName__c, ChildSobjectAPIName__c
            FROM PHOCSSobjectVsQuery__mdt 
            WHERE Type__c = 'Related' AND 
                  DeveloperName= :configName
            LIMIT 1
        ];
        if (queryConfig == null || String.isBlank(queryConfig.ObjectQuery__c)) {
            throw new QueryException('No SOQL query found for related list object');
        }
        system.debug('QueryFormed------->'+queryConfig.ObjectQuery__c);

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
	
    private static string getBLAStatusSummary(string status){
        Map<string, string> statusSummary = new Map<string,string>{
            'Submitted' => 'Your application has been submitted and is pending internal review.You can upload or replace supporting documents, but all other information is locked',
     		'Investigator Review' => 'Your application is currently under investigator review.You may update supporting documents if requested.',
            'Admin Review' => 'Your application is currently under administrative review. You can view your details, but no changes are allowed.',
            'Technical Review' => 'Your application is under technical review by the health authority.You can view details only.',
            'Closed' => 'This application has been closed. No further changes are permitted.'
        };
        if(statusSummary.containsKey(status)){
            return statusSummary.get(status);
        }
        return '';
    }
    
    public interface SObjectWrapper {
        Object wrap(SObject record);
    }
    
    public class BusinessLicenseListWrapper implements SObjectWrapper {
        public Object wrap(SObject record) {
            BusinessLicense BL = (BusinessLicense) record;
            Map<String, Object> result = new Map<String, Object>{
                'Id'=> BL.Id,
                'Identifier' => BL.Identifier,
                'RATname' => BL.RegulatoryAuthorizationType.Name,
                'Facility/AccountName' => BL.Account__r.Name,
                'PeriodStart' => BL.PeriodStart,
                'PeriodEnd' => BL.PeriodEnd,
                'Status' => BL.Status
            };
            return result;
        }
    }

	public class BusinessLicenseListApplicationListWrapper implements SObjectWrapper {
        public Object wrap(SObject record) {
            BusinessLicenseApplication BLA = (BusinessLicenseApplication) record;
            Map<String, Object> result = new Map<String, Object>{
                'Status' => BLA.Status
            };
            return result;
        }
    }
    
    public class BusinessLicenseListApplicationDetailWrapper implements SObjectWrapper {
        public Object wrap(SObject record) {
            BusinessLicenseApplication BLA = (BusinessLicenseApplication) record;
            Map<String, Object> result = new Map<String, Object>{
            	'Id' => BLA.Id,
            	'Name' => BLA.Name,
                'LicenseTypeName' => BLA.LicenseType != null ? BLA.LicenseType.Name : '',
            	'Status' => BLA.Status,
                'StatusSummary' => getBLAStatusSummary(BLA.Status),
            	'AppliedDate' => BLA.AppliedDate,
            	'LastModifiedDate' => BLA.LastModifiedDate,
            	'EstimatedConstructionCost' => BLA.EstimatedConstructionCost__c,
            	'DescriptionOfProposedWorks' => BLA.DescriptionOfProposedWorks__c,
            	'DesignEngineerOfRecord' => BLA.DesignEngineerOfRecord__c,
            	'AccordanceWithBCDesignGuidelines' => BLA.AccordanceWithBCDesignGuidelines__c,
            	'PlansDrawingsSignedSealedByPEng' => BLA.PlansDrawingsSignedSealedByPEng__c != null ? (BLA.PlansDrawingsSignedSealedByPEng__c == true  ? 'Yes' : 'No') : '', 
            	'WaterQuantitySufficient' => BLA.WaterQuantitySufficient__c,
           		'WaterMainExtension' => BLA.WaterMainExtension__c,
           		'ServiceConnectionSeparations' => BLA.ServiceConnectionSeparations__c != null ? (BLA.ServiceConnectionSeparations__c ? 'Yes' : 'No') : '',
            	'HorizontalSeperationFromSewers' => BLA.HorizontalSeperationFromSewers__c,

            	// Account fields
            	'AccountId' => BLA.AccountId,
            	'AccountName' => BLA.Account?.Name,
            	'AccountType' => BLA.Account?.Type,
           		'AccountCategoryL1' => BLA.Account?.CategoryL1__c,
           		'AccountPhone' => BLA.Account?.Phone,
            	'AccountWebsite' => BLA.Account?.Website,
            	'AccountOperationStartDate' => BLA.Account?.OperationStartDate__c,
            	'AccountPhysicalAddress' =>  getAddress(BLA.Account?.Physical_Address__c),
                'AccountPhysicalAddressStreet'=>  BLA.Account?.Physical_Address__c?.getStreet(),
                'AccountPhysicalAddressPostalCode'=> BLA.Account?.Physical_Address__c?.getPostalCode(),
                'AccountPhysicalAddressCity'=>  BLA.Account?.Physical_Address__c?.getCity(),
                'AccountPhysicalAddressState'=>  BLA.Account?.Physical_Address__c?.getState(),
                'AccountPhysicalAddressStateCode'=>  BLA.Account?.Physical_Address__c?.getStateCode(),
                'AccountPhysicalAddressCountry'=>  BLA.Account?.Physical_Address__c?.getCountry(),
                'AccountPhysicalAddressCountryCode'=>  BLA.Account?.Physical_Address__c?.getCountryCode(),
                'AccountPhysicalAddressLatitude' => BLA.Account?.Physical_Address__c?.getLatitude(),
                'AccountPhysicalAddressLongitude' => BLA.Account?.Physical_Address__c?.getLongitude(),
            	'AccountWaterSupply' =>  BLA.Account?.WaterSupply__c,
            	'AccountWasteDisposal' =>  BLA.Account?.WasteDisposal__c ,
            	'AccountMonthsOfOperation' =>  BLA.Account?.MonthsOfOperation__c                  
            };
            return result;
        }
    }
    
    public class BusinessLicenseApplicationListWrapper implements SObjectWrapper {
        public Object wrap(SObject record) {
            BusinessLicenseApplication BLA = (BusinessLicenseApplication) record;
            Map<String, Object> result = new Map<String, Object>{
                'Id' => BLA.Id,
                'Name' => BLA.Name,
                'LicenseTypeId' => BLA.LicenseType.Name,
                'AccountId' => BLA.Account.Name,
                'AppliedDate' => BLA.AppliedDate,
                'LastModifiedDate' => BLA.LastModifiedDate,
                'Status' => BLA.Status,
                'ClosureReason' => BLA.ClosureReason__c
            };
            return result;
        }
    }  
    
}