/**********************************************************************************************
* @Author:      Accenture 
* @Date:        14 Jul 2026
* @Description: The purpose of this class is to Retrieves eligible PHOCS Regulatory Codes and creates Business Application Regulatory Code junction records.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
                14 Jul -  PHOCS-4529        -  Accenture   -  creates Business Application Regulatory Code junction records
***********************************************************************************************/
public with sharing class PHOCSBLARegulatoryCodeController{
    public static final String CLASS_NAME = 'PHOCSBLARegulatoryCodeController';
    public static final String PHOCS_REGULATORY_CODE_RECORD_TYPE = 'PHOCSRegulatoryCode';
    public static final String CHILD_CARE_ACCOUNT_TYPE = 'Child Care';
    public static final String RESIDENTIAL_CARE_ACCOUNT_TYPE = 'Residential Care';
    public static final String CHILD_CARE_AUTHORITY = 'Child Care Licensing Regulation';
    public static final String RESIDENTIAL_CARE_AUTHORITY = 'Residential Care Regulation';
    public static final String COMMUNITY_CARE_AUTHORITY = 'Community Care & Assisted Living Act';
    
    /**
* @author: Deepak
* @date: 14 Jul 2026
* @description: The purpose of this method is to Match the Regulatory Authorities applicable to the Business License Application Account Type.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @AuraEnabled(cacheable=false)
    public static RegulatoryCodeResponse getEligibleRegulatoryCodes(Id businessLicenseApplicationId) {
        try {
            if (businessLicenseApplicationId == null) {
                throw new AuraHandledException(
                    'Business License Application Id is required.'
                );
            }
            
            BusinessLicenseApplication application = [SELECT Id, AccountId, Account.Name, Account.Type 
                                                      FROM BusinessLicenseApplication WHERE Id = :businessLicenseApplicationId LIMIT 1];
            
            if (application.AccountId == null) {
                throw new AuraHandledException('An Account is not associated with this ' + 'Business License Application.');
            }
            
            if (String.isBlank(application.Account.Type)) {
                throw new AuraHandledException('The Account Type is not populated.');
            }
            
            Set<String> regulatoryAuthorityNames = getApplicableRegulatoryAuthorities(application.Account.Type);
            Schema.RecordTypeInfo recordTypeInfo = Schema.SObjectType.RegulatoryCode .getRecordTypeInfosByDeveloperName().get(PHOCS_REGULATORY_CODE_RECORD_TYPE);
            
            if (recordTypeInfo == null) {
                throw new AuraHandledException('The PHOCSRegulatoryCode record type was not found.');
            }
            
            Id regulatoryCodeRecordTypeId = recordTypeInfo.getRecordTypeId();
            Set<Id> existingRegulatoryCodeIds = new Set<Id>();
            
            for (BusinessApplicationRegulatoryCode__c existingRecord : [SELECT RegulatoryCode__c FROM BusinessApplicationRegulatoryCode__c
                                                                        WHERE BusinessLicenseApplication__c =: businessLicenseApplicationId AND RegulatoryCode__c != NULL]){
                                                                            existingRegulatoryCodeIds.add(existingRecord.RegulatoryCode__c);
                                                                        }
            
            List<RegulatoryCode> regulatoryCodes;
            
            if (existingRegulatoryCodeIds.isEmpty()) {
                regulatoryCodes = [SELECT Id, RegulatoryAuthorityId, RegulatoryAuthority.Name, Name, Subject, Description, RegulatoryCodeDescription__c FROM RegulatoryCode
                                   WHERE Type = 'Exemption' AND RecordTypeId =: regulatoryCodeRecordTypeId AND RegulatoryAuthority.Name IN :regulatoryAuthorityNames
                                   ORDER BY RegulatoryAuthority.Name ASC, Name ASC];
            } else {
                regulatoryCodes = [SELECT Id, RegulatoryAuthorityId, RegulatoryAuthority.Name, Name, Subject, Description, RegulatoryCodeDescription__c FROM RegulatoryCode
                                   WHERE Type = 'Exemption' AND RecordTypeId =: regulatoryCodeRecordTypeId AND RegulatoryAuthority.Name IN :regulatoryAuthorityNames
                                   AND Id NOT IN :existingRegulatoryCodeIds ORDER BY RegulatoryAuthority.Name ASC, Name ASC];
            }
            
            List<RegulatoryCodeWrapper> regulatoryCodeWrappers = new List<RegulatoryCodeWrapper>();
            Set<String> retrievedAuthorityNames = new Set<String>();
            
            for (RegulatoryCode regulatoryCode : regulatoryCodes) {
                String regulatoryAuthorityName = regulatoryCode.RegulatoryAuthority != null ? regulatoryCode.RegulatoryAuthority.Name : null;
                regulatoryCodeWrappers.add(new RegulatoryCodeWrapper(regulatoryCode.Id, regulatoryAuthorityName, regulatoryCode.Name, regulatoryCode.Subject, regulatoryCode.RegulatoryCodeDescription__c));
                
                if (String.isNotBlank(regulatoryAuthorityName)) {
                    retrievedAuthorityNames.add(regulatoryAuthorityName);
                }
            }
            
            List<String> sortedAuthorityNames = new List<String>();
            sortedAuthorityNames.addAll(retrievedAuthorityNames);
            sortedAuthorityNames.sort();
            
            RegulatoryCodeResponse response = new RegulatoryCodeResponse();
            response.accountId = application.AccountId;
            response.accountName = application.Account.Name;
            response.accountType = application.Account.Type;
            response.regulatoryCodes = regulatoryCodeWrappers;
            response.regulatoryAuthorities = sortedAuthorityNames;
            return response;
            
        } catch (Exception ex){
            LogService.logAndPublish(CLASS_NAME, 'getEligibleRegulatoryCodes', null, ex);
            throw ex;
        }
    }
    
    /**
* @author: Deepak
* @date: 14 Jul 2026
* @description: The purpose of this method is to Creates BusinessApplicationRegulatoryCode__c records.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @AuraEnabled
    public static SaveRegulatoryCodeResponse saveRegulatoryCodes(Id businessLicenseApplicationId, List<Id> regulatoryCodeIds) {
        try {
            if (businessLicenseApplicationId == null) {
                throw new AuraHandledException('Business License Application Id is required.');
            }
            
            if (regulatoryCodeIds == null || regulatoryCodeIds.isEmpty()) {
                throw new AuraHandledException('Select at least one Regulatory Code.');
            }
            
            Set<Id> uniqueRegulatoryCodeIds = new Set<Id>();
            uniqueRegulatoryCodeIds.addAll(regulatoryCodeIds);
            Set<Id> existingRegulatoryCodeIds = new Set<Id>();
            
            for(BusinessApplicationRegulatoryCode__c existingRecord : [SELECT RegulatoryCode__c FROM BusinessApplicationRegulatoryCode__c
                                                                       WHERE BusinessLicenseApplication__c =: businessLicenseApplicationId AND RegulatoryCode__c IN: uniqueRegulatoryCodeIds]){
                                                                           existingRegulatoryCodeIds.add(existingRecord.RegulatoryCode__c);
                                                                       }
            
            List<BusinessApplicationRegulatoryCode__c>junctionRecords = new List<BusinessApplicationRegulatoryCode__c>();
            
            for (Id regulatoryCodeId : uniqueRegulatoryCodeIds) {
                if(existingRegulatoryCodeIds.contains(regulatoryCodeId)) {
                    continue;
                }
                
                junctionRecords.add(new BusinessApplicationRegulatoryCode__c(BusinessLicenseApplication__c = businessLicenseApplicationId, RegulatoryCode__c = regulatoryCodeId));
            }
            
            SaveRegulatoryCodeResponse response = new SaveRegulatoryCodeResponse();
            
            response.requestedCount = uniqueRegulatoryCodeIds.size();
            response.skippedDuplicateCount = existingRegulatoryCodeIds.size();
            response.successCount = 0;
            response.failureCount = 0;
            response.errors = new List<String>();
            
            if (junctionRecords.isEmpty()) {
                response.message = 'The selected Regulatory Codes are already ' + 'associated with this Business License Application.';
                return response;
            }
            
            Database.SaveResult[] saveResults = Database.insert(junctionRecords, false);
            for (Integer index = 0; index < saveResults.size(); index++) {
                Database.SaveResult saveResult = saveResults[index];
                
                if (saveResult.isSuccess()) {
                    response.successCount++;
                } else {
                    response.failureCount++;
                    
                    for (Database.Error databaseError : saveResult.getErrors()) {
                        response.errors.add(databaseError.getStatusCode() + ': ' + databaseError.getMessage());
                    }
                }
            }
            
            if (response.successCount > 0 && response.failureCount == 0){
                response.message = response.successCount + ' Regulatory Code record(s) were added successfully.';
            } else if (response.successCount > 0 && response.failureCount > 0) {
                response.message = response.successCount + ' Regulatory Code record(s) were added. ' + response.failureCount + ' record(s) failed.';
            } else {
                response.message = 'The selected Regulatory Codes could not be added.';
            }
            return response;
            
        } catch (Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'saveRegulatoryCodes', null, ex);
            throw ex;
        }
    }
    
    /**
* @author: Deepak
* @date: 14 Jul 2026
* @description: The purpose of this method is to Determines the applicable Regulatory Authorities using the Account Type.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static Set<String> getApplicableRegulatoryAuthorities(String accountType) {
        Set<String> authorityNames = new Set<String>();
        
        if (CHILD_CARE_ACCOUNT_TYPE.equalsIgnoreCase(accountType)) {
            authorityNames.add(CHILD_CARE_AUTHORITY);
            authorityNames.add(COMMUNITY_CARE_AUTHORITY);
        } else if (RESIDENTIAL_CARE_ACCOUNT_TYPE.equalsIgnoreCase(accountType)){
            authorityNames.add(RESIDENTIAL_CARE_AUTHORITY);
            authorityNames.add(COMMUNITY_CARE_AUTHORITY);
        } else {
            throw new AuraHandledException('Regulatory Codes are not configured for ' + 'Account Type: ' + accountType +'.');
        }
        return authorityNames;
    }
    
    
    public class RegulatoryCodeResponse {
        @AuraEnabled
        public Id accountId;
        @AuraEnabled
        public String accountName;
        @AuraEnabled
        public String accountType;
        @AuraEnabled
        public List<RegulatoryCodeWrapper> regulatoryCodes;
        @AuraEnabled
        public List<String> regulatoryAuthorities;
    }
    
    public class RegulatoryCodeWrapper {
        @AuraEnabled
        public Id regulatoryCodeId;
        @AuraEnabled
        public String regulatoryAuthority;
        @AuraEnabled
        public String regulatoryCode;
        @AuraEnabled
        public String subject;
        @AuraEnabled
        public String description;
        
        public RegulatoryCodeWrapper(Id regulatoryCodeId, String regulatoryAuthority, String regulatoryCode, String subject, String description) {
            this.regulatoryCodeId = regulatoryCodeId;
            this.regulatoryAuthority = regulatoryAuthority;
            this.regulatoryCode = regulatoryCode;
            this.subject = subject;
            this.description = description;
        }
    }
    
    public class SaveRegulatoryCodeResponse {
        @AuraEnabled
        public Integer requestedCount;
        @AuraEnabled
        public Integer successCount;
        @AuraEnabled
        public Integer failureCount;
        @AuraEnabled
        public Integer skippedDuplicateCount;
        @AuraEnabled
        public String message;
        @AuraEnabled
        public List<String> errors;
    }

}