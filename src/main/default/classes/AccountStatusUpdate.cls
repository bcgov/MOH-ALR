/**
* @Name              : AccountStatusUpdate
* @Description       : Class for Updating Account Status on April 1st and May 1st
* @Author            : Keerthana Srinivasan (Accenture)
* @StoryNo           : ALR-1289
**/

public with sharing class AccountStatusUpdate implements Schedulable {

    public void execute(SchedulableContext sc) {
        Date currentDate = Date.today();
        if(currentDate.month() == 4 && currentDate.day() == 1) {
            updateAccountStatusToRegisteredActivePendingRenewals();
        } else if(currentDate.month() == 5 && currentDate.day() == 1) {
            updateAccountStatusToUnregisteredActivePendingRenewals();
        }
    }
    
    // Method to update account status to 'Registered Active Pending Renewals'
    public static void updateAccountStatusToRegisteredActivePendingRenewals() {
        List<Account> accountsToUpdate = new List<Account>();
        Map<Id, Account> accountIdMap = new Map<Id, Account>();
        try {
            for(Account acc : [SELECT Id, Status__c FROM Account WHERE Status__c =: BCMOH_Constants.accountStatus]) {
                accountIdMap.put(acc.Id, acc);
             }

            for(BusinessLicenseApplication bla : [SELECT Id, Account.Id, Status FROM BusinessLicenseApplication WHERE Account.Id IN :accountIdMap.keySet() AND RecordType.Name=: BCMOH_Constants.blaRecType]) {
                if((bla.Status == BCMOH_Constants.blaCreatedStatus || bla.Status == BCMOH_Constants.sentBlaStatus) && accountIdMap.containsKey(bla.Account.Id)) {
                    accountIdMap.get(bla.Account.Id).Status__c = BCMOH_Constants.AccStatus ;
                    
                }
            }

            accountsToUpdate.addAll(accountIdMap.values());

            if(!accountsToUpdate.isEmpty()) {
                update accountsToUpdate;
               
            }
        } catch(Exception e) {
            System.debug('An error occurred: ' + e.getMessage());
        }
    }

    // Method to update account status to 'Unregistered Active Pending Renewals'
    public static void updateAccountStatusToUnregisteredActivePendingRenewals() {
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
                update accountsToUpdate;
            }
        } catch(Exception e) {
            System.debug('An error occurred: ' + e.getMessage());
        }
    }
}