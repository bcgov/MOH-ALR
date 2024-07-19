/**
* @Name              : AccountContactRelationController
* @Description       : This class transfer Account and related records Owners.
* @Author            : Keerthana (Accenture)
* @StoryNo           : ALR-134
**/

public with sharing class ChangeAccountOwner {
    
    public class FlowInputs {
        @InvocableVariable
        public Id newOwnerId;
        
        @InvocableVariable
        public List<Id> accountId;
        
        @InvocableVariable
        public Boolean isBlaChecked;
        
        @InvocableVariable
        public Boolean isPublicChecked;
        
        @InvocableVariable
        public Boolean isCaseChecked;
        
        @InvocableVariable
        public Boolean isInspectionChecked;
    }
    
    @InvocableMethod(label='Transfer Account Ownership' description='Transfers ownership of Accounts and related records.')
    public static void transferAccountOwnership(List<FlowInputs> inputs) {
        try {
            FlowInputs input = inputs[0];
            
            Id newOwnerId = input.newOwnerId;
            List<Id> accountId = input.accountId;
            Boolean isBlaChecked = input.isBlaChecked;
            Boolean isPublicChecked = input.isPublicChecked;
            Boolean isCaseChecked = input.isCaseChecked;
            Boolean isInspectionChecked = input.isInspectionChecked;
            
            if (newOwnerId == null || accountId.isEmpty()) {
                return;
            }
            
            Map<Id, List<BusinessLicenseApplication>> mapBlaRecords = new Map<Id, List<BusinessLicenseApplication>>();
            Map<Id, List<PublicComplaint>> mapPublicCompRecords = new Map<Id, List<PublicComplaint>>();
            Map<Id, List<Case>> mapCaseRecords = new Map<Id, List<Case>>();
            Map<Id, List<Visit>> mapVisitRecords = new Map<Id, List<Visit>>();
            
            if (isBlaChecked) {
                mapBlaRecords = getRelatedBlaRecords(accountId);
            }
            if (isPublicChecked) {
                mapPublicCompRecords = getRelatedPublicCompRecords(accountId);
            }
            if (isCaseChecked) {
                mapCaseRecords = getRelatedCaseRecords(accountId);
            }
            if (isInspectionChecked) {
                mapVisitRecords = getRelatedVisitRecords(accountId);
            }
            
            List<Account> accountsToUpdate = new List<Account>();
            List<BusinessLicenseApplication> blaRecordsToUpdate = new List<BusinessLicenseApplication>();
            List<PublicComplaint> publicCompRecordsToUpdate = new List<PublicComplaint>();
            List<Case> caseRecordsToUpdate = new List<Case>();
            List<Visit> visitRecordsToUpdate = new List<Visit>();
            
            for (Id accId : accountId) {
                Account acc = new Account(Id = accId, OwnerId = newOwnerId);
                accountsToUpdate.add(acc);
                
                if (isBlaChecked && mapBlaRecords.containsKey(accId)) {
                    for (BusinessLicenseApplication bla : mapBlaRecords.get(accId)) {
                        bla.OwnerId = newOwnerId;
                        blaRecordsToUpdate.add(bla);
                    }
                }
                
                if (isPublicChecked && mapPublicCompRecords.containsKey(accId)) {
                    for (PublicComplaint pubComp : mapPublicCompRecords.get(accId)) {
                        pubComp.OwnerId = newOwnerId;
                        publicCompRecordsToUpdate.add(pubComp);
                    }
                }
                
                if (isCaseChecked && mapCaseRecords.containsKey(accId)) {
                    for (Case caseRec : mapCaseRecords.get(accId)) {
                        caseRec.OwnerId = newOwnerId;
                        caseRecordsToUpdate.add(caseRec);
                    }
                }
                
                if (isInspectionChecked && mapVisitRecords.containsKey(accId)) {
                    for (Visit visit : mapVisitRecords.get(accId)) {
                        visit.OwnerId = newOwnerId;
                        visitRecordsToUpdate.add(visit);
                    }
                }
            }
            
            
            if (!accountsToUpdate.isEmpty()) {
                update accountsToUpdate;
            }
            if (!blaRecordsToUpdate.isEmpty()) {
                update blaRecordsToUpdate;
            }
            if (!publicCompRecordsToUpdate.isEmpty()) {
                update publicCompRecordsToUpdate;
            }
            if (!caseRecordsToUpdate.isEmpty()) {
                update caseRecordsToUpdate;
            }
            if (!visitRecordsToUpdate.isEmpty()) {
                update visitRecordsToUpdate;
            }
        } catch (Exception err) {
            System.debug('Exception occurred: ' + err.getMessage());
        }
    }
    
    public static Map<Id, List<BusinessLicenseApplication>> getRelatedBlaRecords(List<Id> accountId) {
        Map<Id, List<BusinessLicenseApplication>> resultMap = new Map<Id, List<BusinessLicenseApplication>>();
        for (BusinessLicenseApplication bla : [SELECT Id, OwnerId, AccountId FROM BusinessLicenseApplication WHERE AccountId IN :accountId AND RecordType.Name='New License' AND Status !='Closed' AND Status !='Pending Approval']) {
            if (!resultMap.containsKey(bla.AccountId)) {
                resultMap.put(bla.AccountId, new List<BusinessLicenseApplication>());
            }
            resultMap.get(bla.AccountId).add(bla);
        }
        return resultMap;
    }
    
    public static Map<Id, List<PublicComplaint>> getRelatedPublicCompRecords(List<Id> accountId) {
        Map<Id, List<PublicComplaint>> resultMap = new Map<Id, List<PublicComplaint>>();
        for (PublicComplaint pubComp : [SELECT Id, OwnerId, AccountId FROM PublicComplaint WHERE AccountId IN :accountId AND Status = 'Needs Review']) {
            if (!resultMap.containsKey(pubComp.AccountId)) {
                resultMap.put(pubComp.AccountId, new List<PublicComplaint>());
            }
            resultMap.get(pubComp.AccountId).add(pubComp);
        }
        return resultMap;
    }
    
    public static Map<Id, List<Case>> getRelatedCaseRecords(List<Id> accountId) {
        Map<Id, List<Case>> resultMap = new Map<Id, List<Case>>();
        for (Case caseRec : [SELECT Id, OwnerId, AccountId FROM Case WHERE AccountId IN :accountId AND Status != 'Closed' AND Status !='Pending Approval']) {
            if (!resultMap.containsKey(caseRec.AccountId)) {
                resultMap.put(caseRec.AccountId, new List<Case>());
            }
            resultMap.get(caseRec.AccountId).add(caseRec);
        }
        return resultMap;
    }
    
    public static Map<Id, List<Visit>> getRelatedVisitRecords(List<Id> accountId) {
        Map<Id, List<Visit>> resultMap = new Map<Id, List<Visit>>();
        for (Visit visit : [SELECT Id, OwnerId, AccountId FROM Visit WHERE AccountId IN :accountId AND Status != 'Completed']) {
            if (!resultMap.containsKey(visit.AccountId)) {
                resultMap.put(visit.AccountId, new List<Visit>());
            }
            resultMap.get(visit.AccountId).add(visit);
        }
        return resultMap;
    }
}