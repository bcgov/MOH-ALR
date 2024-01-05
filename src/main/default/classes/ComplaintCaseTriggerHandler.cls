/**
* @Name              : ComplaintCaseTriggerHandler
* @Description       : TriggerHandler for CompliantCaseTrigger
* @Author            : Sri Teja (Accenture)
* @StoryNo           : ALR-509
**/


public class ComplaintCaseTriggerHandler {
    public static void handleBeforeInsert(List<Case> newCases) {
        Map<Id, List<Case>> casesByAccountId = new Map<Id, List<Case>>();
        Set<Id> accountIds = new Set<Id>();
        Set<String> licenseTypeSet = new Set<String>();
 
        for (Case newCase : newCases) {
            if (newCase.AccountId != null) {
                accountIds.add(newCase.AccountId);
                licenseTypeSet.add(getLicenseTypeCode(newCase.AccountId));
            }
        }
 
        Map<String, Id> recordTypeDeveloperNameToIdMap = getRecordTypeDeveloperNameToIdMap('PublicComplaintCase');
 
        // Query Record Types for 'PublicComplaintCase'
        Map<String, Id> recordTypeMap = getRecordTypesMap('PublicComplaintCase');
 
        for (Case newCase : newCases) {
            if (newCase.AccountId != null) {
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
 
    private static void generateComplaintCaseIDs(List<Case> cases, Set<String> licenseTypeSet) {
        Map<String, String> licenseTypeCodeMap = getLicenseTypeCodeMap(cases);
        Map<String, String> maxSequenceNumbers = getMaxSequenceNumbers(licenseTypeSet, System.today().year());
 
        for (Case newCase : cases) {
            String licenseTypeCode = licenseTypeCodeMap.get(newCase.AccountId);
            String sequenceNumber = maxSequenceNumbers.get(licenseTypeCode);
 
            String formattedSequenceNumber = getFormattedSequenceNumber(sequenceNumber);
            newCase.Complaint_Case_ID__c = 'C' + System.today().year() + '-' + licenseTypeCode + formattedSequenceNumber;
            System.debug('New Case Complaint_Case_ID__c: ' + newCase.Complaint_Case_ID__c);
        }
    }
 
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
 
    private static Map<String, String> getMaxSequenceNumbers(Set<String> licenseTypes, Integer year) {
        Map<String, String> maxSequenceNumbers = new Map<String, String>();
 
        for (String licenseType : licenseTypes) {
            maxSequenceNumbers.put(licenseType, getMaxSequenceNumber(licenseType, year));
        }
 
        return maxSequenceNumbers;
    }
 
    private static String getFormattedSequenceNumber(String sequenceNumber) {
        Integer numericSequenceNumber = 0;
 
        if (sequenceNumber != '0') {
            String numericPart = sequenceNumber.substring(8).replaceAll('[^0-9]', '');
            numericSequenceNumber = numericPart.length() > 2 ? Integer.valueOf(numericPart.substring(numericPart.length() - 3)) : 0;
        }
 
        return String.valueOf(++numericSequenceNumber).leftPad(3, '0');
    }
 
    private static Map<String, Id> getRecordTypesMap(String developerName) {
        Map<String, Id> result = new Map<String, Id>();
 
        for (RecordType rt : [SELECT Id, DeveloperName
                                FROM RecordType
                                WHERE SObjectType = 'Case'
                                AND DeveloperName = :developerName]) {
            result.put(rt.DeveloperName, rt.Id);
        }
 
        return result;
    }
 
    private static String getMaxSequenceNumber(String licenseType, Integer year) {
        String maxSequenceNumber = '0';
 
        try {
            AggregateResult maxResult = [
                SELECT MAX(Complaint_Case_ID__c) maxSequence
                FROM Case
                WHERE Account.LicenseType__r.RegulatoryAuthorizationCode__c = :licenseType
                    AND CreatedDate >= :Date.newInstance(year, 1, 1)
                    AND CreatedDate < :Date.newInstance(year + 1, 1, 1)
            ];
 
            if (maxResult.get('maxSequence') != null) {
                maxSequenceNumber = (String) maxResult.get('maxSequence');
            }
        } catch (Exception e) {
            System.debug('Error querying max sequence number: ' + e.getMessage());
        }
 
        return maxSequenceNumber;
    }
 
    private static String getLicenseTypeCode(Id accountId) {
        String licenseTypeCode = 'UNKNOWN';
 
        try {
            Account acc = [
                SELECT LicenseType__r.RegulatoryAuthorizationCode__c
                FROM Account
                WHERE Id = :accountId
                LIMIT 1
            ];
 
            if (acc != null && acc.LicenseType__r != null) {
                licenseTypeCode = acc.LicenseType__r.RegulatoryAuthorizationCode__c;
            }
        } catch (Exception e) {
            System.debug('Error querying LicenseTypeCode: ' + e.getMessage());
        }
 
        return licenseTypeCode;
    }
 
    private static Map<String, Id> getRecordTypeDeveloperNameToIdMap(String developerName) {
        Map<String, Id> result = new Map<String, Id>();
 
        try {
            List<RecordType> recordTypes = [
                SELECT Id, DeveloperName
                FROM RecordType
                WHERE SObjectType = 'Case'
                AND DeveloperName = :developerName
            ];
 
            for (RecordType rt : recordTypes) {
                result.put(rt.DeveloperName, rt.Id);
            }
        } catch (Exception e) {
            System.debug('Error querying RecordTypeDeveloperNameToIdMap: ' + e.getMessage());
        }
 
        return result;
    }
}