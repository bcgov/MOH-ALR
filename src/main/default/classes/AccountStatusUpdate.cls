/**
* @Name              : AccountStatusUpdate
* @Description       : Class for Updating Account Status on April 1st and May 1st
* @Author            : Keerthana Srinivasan (Accenture)
* @StoryNo           : ALR-1289
**/

public with sharing class AccountStatusUpdate implements Schedulable {

    public void execute(SchedulableContext sc) {
       
      List<Account> accountsToUpdate = new List<Account>();
        Map<Id, Account> accountIdMap = new Map<Id, Account>();
        try {
            for(Account acc : [SELECT Id, Status__c FROM Account WHERE Status__c =: BCMOH_Constants.accountStatus]) {
                accountIdMap.put(acc.Id, acc);
             }
                 Integer rtffeeId =0;
                Set<Id> rtffeeAccountIds = new Set<Id>();
                for (RegulatoryTrxnFee rtffee : [SELECT Id, Account.Id FROM RegulatoryTrxnFee WHERE Account.Id IN :accountIdMap.keySet() AND FeeType__c = :BCMOH_Constants.feeType AND Status = :BCMOH_Constants.dueFeeStatus]) {
                rtffeeId = rtffeeId+1;
                    
                }
            
            for(BusinessLicenseApplication bla : [SELECT Id, Account.Id, Status FROM BusinessLicenseApplication WHERE Account.Id IN :accountIdMap.keySet() AND RecordType.Name=: BCMOH_Constants.blaRecType]) {
                if((bla.Status == BCMOH_Constants.blaCreatedStatus || bla.Status == BCMOH_Constants.sentBlaStatus) && (rtffeeId>0)) {
                    accountIdMap.get(bla.Account.Id).Status__c = BCMOH_Constants.AccStatus ;
                    
                    
                }
            }
            
            accountsToUpdate.addAll(accountIdMap.values());
            
            if(!accountsToUpdate.isEmpty()) {
                Database.update(accountsToUpdate,FALSE) ;
               System.debug('Accounts updated successfully.');
            }
        } catch(Exception e) {
            System.debug('An error occurred: ' + e.getMessage());
        }
    }
}