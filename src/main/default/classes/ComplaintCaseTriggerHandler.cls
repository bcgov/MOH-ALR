/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Class is for TriggerHandler for CompliantCaseTrigger
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
                          ALR-509             Sri Teja       Public complaints/Cases additional changes
                          ALR-762             ACN-ALR        Error Thrown on creation of Reportable Incident Case 
***********************************************************************************************/
public with sharing class ComplaintCaseTriggerHandler {
    static String className = 'ComplaintCaseTriggerHandler';

/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is for ComplaintCaseTriggerHandler
* @return:  void
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static void handleBeforeInsert(List<Case> newCases) {
        Map<Id, List<Case>> casesByAccountId = new Map<Id, List<Case>>();
        Set<Id> accountIds = new Set<Id>();
        Set<String> licenseTypeSet = new Set<String>();
        String pubCompCaseTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('PublicComplaintCase').getRecordTypeId();//ALR-762
        
        for (Case newCase : newCases) {
            if (newCase.AccountId != null && newCase.RecordTypeId == pubCompCaseTypeId) {//ALR-762 - added recordtypeId check
                accountIds.add(newCase.AccountId);
                licenseTypeSet.add(getLicenseTypeCode(newCase.AccountId));
            }
        }
        
        Map<String, Id> recordTypeDeveloperNameToIdMap = getRecordTypeDeveloperNameToIdMap('PublicComplaintCase');
        
        // Query Record Types for 'PublicComplaintCase'
        Map<String, Id> recordTypeMap = getRecordTypesMap('PublicComplaintCase');
        
        for (Case newCase : newCases) {
            if (newCase.AccountId != null && newCase.RecordTypeId == pubCompCaseTypeId) {//ALR-762 - added recordtypeId check
                Id recordTypeId = recordTypeMap.get('PublicComplaintCase');
                
                if (recordTypeId != null) {
                    newCase.RecordTypeId = recordTypeId;
                    
                    if (!casesByAccountId.containsKey(newCase.AccountId)) {
                        casesByAccountId.put(newCase.AccountId, new List<Case>());
                    }
                    casesByAccountId.get(newCase.AccountId).add(newCase);
                }
            }
        }
        
        for (Id accountId : casesByAccountId.keySet()) {
            generateComplaintCaseIDs(casesByAccountId.get(accountId), licenseTypeSet);
        }
    }

/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is for ComplaintCaseTriggerHandler
* @return:  void
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static void generateComplaintCaseIDs(List<Case> cases, Set<String> licenseTypeSet) {
        Map<String, String> licenseTypeCodeMap = getLicenseTypeCodeMap(cases);
        Map<String, String> maxSequenceNumbers = getMaxSequenceNumbers(licenseTypeSet, System.today().year());
        
        for (Case newCase : cases) {
            String licenseTypeCode = licenseTypeCodeMap.get(newCase.AccountId);
            String sequenceNumber = maxSequenceNumbers.get(licenseTypeCode);
            String formattedSequenceNumber = getFormattedSequenceNumber(sequenceNumber);
            newCase.Complaint_Case_ID__c = 'C' + System.today().year() + '-' + licenseTypeCode + formattedSequenceNumber;
        }
    }

/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is for ComplaintCaseTriggerHandler
* @return:  Map<String, String>
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static Map<String, String> getLicenseTypeCodeMap(List<Case> cases) {
        Map<String, String> licenseTypeCodeMap = new Map<String, String>();
        Set<Id> accountIds = new Set<Id>();
        
        for (Case newCase : cases) {
            accountIds.add(newCase.AccountId);
        }
        
        for (Account acc : [SELECT Id, LicenseType__r.RegulatoryAuthorizationCode__c
                            FROM Account
                            WHERE Id IN :accountIds]) {
                                licenseTypeCodeMap.put(acc.Id, acc.LicenseType__r.RegulatoryAuthorizationCode__c);
                            }
        return licenseTypeCodeMap;
    }

/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is for ComplaintCaseTriggerHandler
* @return:  Map<String, String>
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static Map<String, String> getMaxSequenceNumbers(Set<String> licenseTypes, Integer year) {
        Map<String, String> maxSequenceNumbers = new Map<String, String>();
        
        for (String licenseType : licenseTypes) {
            maxSequenceNumbers.put(licenseType, getMaxSequenceNumber(licenseType, year));
        }
        return maxSequenceNumbers;
    }

/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is for ComplaintCaseTriggerHandler
* @return:  String
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static String getFormattedSequenceNumber(String sequenceNumber) {
        Integer numericSequenceNumber = 0;

        if (sequenceNumber != null && sequenceNumber != '0') {
            String numericPart = sequenceNumber.substring(8).replaceAll('[^0-9]', '');
            numericSequenceNumber = numericPart.length() > 2 ? Integer.valueOf(numericPart.substring(numericPart.length() - 3)) : 0;
        }
        return String.valueOf(++numericSequenceNumber).leftPad(3, '0');
    }

/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is for ComplaintCaseTriggerHandler
* @return:  Map<String, Id>
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static Map<String, Id> getRecordTypesMap(String developerName) {
        Map<String, Id> result = new Map<String, Id>();
        
        for (RecordType rt : [SELECT Id, DeveloperName
                              FROM RecordType
                              WHERE SObjectType = 'Case'
                              AND DeveloperName = :developerName WITH SECURITY_ENFORCED]) {
                                  result.put(rt.DeveloperName, rt.Id);
                              }
        return result;
    }

/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is for ComplaintCaseTriggerHandler
* @return:  String
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static String getMaxSequenceNumber(String licenseType, Integer year) {
        String maxSequenceNumber = '0';
        try {
            AggregateResult maxResult = [
                SELECT MAX(Complaint_Case_ID__c) maxSequence
                FROM Case
                WHERE Account.LicenseType__r.RegulatoryAuthorizationCode__c = :licenseType
                AND CreatedDate >= :Date.newInstance(year, 1, 1)
                AND CreatedDate < :Date.newInstance(year + 1, 1, 1) WITH SECURITY_ENFORCED
            ];
            
            if (maxResult.get('maxSequence') != null) {
                maxSequenceNumber = (String) maxResult.get('maxSequence');
            }
        } catch (Exception e) {
            LogService.logAndPublish(className, 'getMaxSequenceNumber', '', e);
        }
        return maxSequenceNumber;
    }

/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is for ComplaintCaseTriggerHandler
* @return:  String
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static String getLicenseTypeCode(Id accountId) {
        String licenseTypeCode = 'UNKNOWN';
        try {
            Account acc = [
                SELECT LicenseType__r.RegulatoryAuthorizationCode__c
                FROM Account
                WHERE Id = :accountId WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            if (acc != null && acc.LicenseType__r != null) {
                licenseTypeCode = acc.LicenseType__r.RegulatoryAuthorizationCode__c;
            }
        } catch (Exception e) {
            LogService.logAndPublish(className, 'getLicenseTypeCode', '', e);
        }
        return licenseTypeCode;
    }

/**
* @Author: Accenture_ALR Dev Team
* @date: Map<String, Id>
* @description: The purpose of this method is for ComplaintCaseTriggerHandler
* @return:  
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static Map<String, Id> getRecordTypeDeveloperNameToIdMap(String developerName) {
        Map<String, Id> result = new Map<String, Id>();
        try {
            List<RecordType> recordTypes = [
                SELECT Id, DeveloperName
                FROM RecordType
                WHERE SObjectType = 'Case'
                AND DeveloperName = :developerName WITH SECURITY_ENFORCED
            ];
            for (RecordType rt : recordTypes) {
                result.put(rt.DeveloperName, rt.Id);
            }
        } catch (Exception e) {
            LogService.logAndPublish(className, 'getRecordTypeDeveloperNameToIdMap', '', e);
        }
        return result;
    }
}