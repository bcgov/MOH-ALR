/**
* @Name              : AccountStatusUpdateOnMay
* @Description       : Class for Updating Account Status on May 1st 
* @Author            : Keerthana Srinivasan (Accenture)
* @StoryNo           : ALR-1289
**/

public class AccountStatusUpdateOnMay implements Schedulable {
public void execute(SchedulableContext sc) {
List<Account> accountsToUpdate = new List<Account>();
        Map<Id, Account> accountIdMap = new Map<Id, Account>();
        
        try {
            for(Account acc : [SELECT Id, Status__c FROM Account]) {
                accountIdMap.put(acc.Id, acc);
            }
            
            for(RegulatoryTrxnFee rtffee : [SELECT Id, Account.Id FROM RegulatoryTrxnFee WHERE Account.Id IN :accountIdMap.keySet() AND FeeType__c =: BCMOH_Constants.feeType AND Status =: BCMOH_Constants.dueFeeStatus]) {
                if(accountIdMap.containsKey(rtffee.Account.Id)) {
                    accountIdMap.get(rtffee.Account.Id).Status__c = BCMOH_Constants.AccUnRegisteredStatus;
                   
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