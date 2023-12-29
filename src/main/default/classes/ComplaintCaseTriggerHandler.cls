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
        for (Case newCase : newCases) {
            if (newCase.AccountId != null) {
                accountIds.add(newCase.AccountId);
            }
        }
 
        Map<String, Id> recordTypeDeveloperNameToIdMap = getRecordTypeDeveloperNameToIdMap('PublicComplaintCase');
        for (Case newCase : newCases) {
            if (newCase.AccountId != null) {
                String recordTypeDeveloperName = 'PublicComplaintCase';
                Id recordTypeId = recordTypeDeveloperNameToIdMap.get(recordTypeDeveloperName);
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
            generateComplaintCaseIDs(casesByAccountId.get(accountId));
        }
    }
 
    private static void generateComplaintCaseIDs(List<Case> cases) {
        Map<Id, String> accountLicenseTypeCodeMap = new Map<Id, String>();
        Integer numericSequenceNumber;
        String yearPrefix = String.valueOf(System.today().year());
 
        for (Case newCase : cases) {
            String licenseTypeCode = getLicenseTypeCode(newCase.AccountId);
            accountLicenseTypeCodeMap.put(newCase.AccountId, licenseTypeCode);
 
            String sequenceNumber = getMaxSequenceNumber(licenseTypeCode, System.today().year());
            System.debug('New Case: ' + newCase);
            System.debug('Sequence Number: ' + sequenceNumber);
 
            if (sequenceNumber != '0') {
                String numericPart = sequenceNumber.substring(8).replaceAll('[^0-9]', '');
                numericSequenceNumber = numericPart.length() > 2 ? Integer.valueOf(numericPart.substring(numericPart.length() - 3)) : 0;
 
                String formattedSequenceNumber = String.valueOf(++numericSequenceNumber).leftPad(3, '0');
                newCase.Complaint_Case_ID__c = 'C' + yearPrefix + '-' + licenseTypeCode + formattedSequenceNumber;
                System.debug('New Case Complaint_Case_ID__c: ' + newCase.Complaint_Case_ID__c);
            } else {
                newCase.Complaint_Case_ID__c = 'C' + yearPrefix + '-' + licenseTypeCode + '001';
                System.debug('New Case Complaint_Case_ID__c: ' + newCase.Complaint_Case_ID__c);
            }
        }
    }
 
    private static String getMaxSequenceNumber(String licenseType, Integer year) {
        String maxSequenceNumber = '0';
        System.debug('License Type: ' + licenseType);
 
        try {
            AggregateResult maxResult = [
                SELECT MAX(Complaint_Case_ID__c) maxSequence
                FROM Case
                WHERE Account.LicenseType__r.RegulatoryAuthorizationCode__c = :licenseType
                AND CreatedDate >= :Date.newInstance(year, 1, 1)
                AND CreatedDate < :Date.newInstance(year + 1, 1, 1)
            ];
 
            System.debug('Max Result: ' + maxResult);
 
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