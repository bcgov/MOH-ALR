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
            
            List<Account> accList = [SELECT Id, OwnerId FROM Account WHERE Id = :accountId];
            List<BusinessLicenseApplication> blaRec;  
            List<PublicComplaint> pubCompList;
            List<Case> caseList;
            List<Visit> visitList;
            
            for(Account acc : accList){
                Id oldOwnerId = acc.OwnerId;
                
                {
                    acc.OwnerId = newOwnerId;
                }
                
                if(isBlaChecked == True){
                    blaRec = getRelatedBlaRecords(acc.Id,oldOwnerId);
                    for(BusinessLicenseApplication bla : blaRec){
                        bla.OwnerId = newOwnerId;
                    }
                    Database.update(blaRec,FALSE) ;
                }
                
                if(isPublicChecked == True){
                    pubCompList = getRelatedPublicCompRecords(acc.Id,oldOwnerId);
                    for(PublicComplaint pubComp : pubCompList){
                        pubComp.OwnerId = newOwnerId;
                    }
                    Database.update(pubCompList,FALSE) ;
                }
                
                if(isCaseChecked == True){
                    caseList = getRelatedCaseRecords(acc.Id,oldOwnerId);
                    for(Case caseRec : caseList){
                        caseRec.OwnerId = newOwnerId;
                    }
                    Database.update(caseList,FALSE) ;
                }
                
                if(isInspectionChecked == True){
                    visitList = getRelatedVisitRecords(acc.Id,oldOwnerId);
                    for(Visit visit : visitList){
                        visit.OwnerId = newOwnerId;
                    }
                    Database.update(visitList,FALSE) ; 
                }
            }
            Database.update(accList,FALSE) ; 
        }
        catch (Exception err) {
            System.debug('Exception occurred: ' + err.getMessage());
        }
    }
    public static List<BusinessLicenseApplication> getRelatedBlaRecords(Id accountId, Id oldOwnerId){
        return [Select Id, OwnerId from BusinessLicenseApplication where AccountId =:accountId AND OwnerId=: oldOwnerId AND RecordType.Name='New License' AND Status !='Closed'];
    }
    
    public static List<PublicComplaint> getRelatedPublicCompRecords(Id accountId, Id oldOwnerId){
        return [Select Id, OwnerId from PublicComplaint where AccountId =:accountId AND OwnerId=: oldOwnerId AND Status =: 'Needs Review'];
    }
    
    public static List<Case> getRelatedCaseRecords(Id accountId, Id oldOwnerId){
        return [Select Id, OwnerId from Case where AccountId =:accountId AND OwnerId =: oldOwnerId AND Status != 'Closed'];
    }
    
    public static List<Visit> getRelatedVisitRecords(Id accountId, Id oldOwnerId){
        return [Select Id, OwnerId from Visit where AccountId =:accountId AND OwnerId=: oldOwnerId AND Status != 'Completed'];
    }
    
}