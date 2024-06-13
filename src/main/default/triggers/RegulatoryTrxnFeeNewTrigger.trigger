/**
* @Name              : RegulatoryTrxnFeeNewTrigger
* @Description       : Trigger for Updating Account Status based on RegulatoryTrxnFee Status
* @Author            : Keerthana Srinivasan (Accenture)
* @StoryNo           : ALR-1289
**/

trigger RegulatoryTrxnFeeNewTrigger on RegulatoryTrxnFee (after update) {
    Set<Id> residenceAccountIds = new Set<Id>();
 
    if (Trigger.new.isEmpty()) {
        return;
    }

    for (RegulatoryTrxnFee rtf : Trigger.new) {
        if (rtf.FeeType__c == 'Renewal Unit Fee' && rtf.Status == 'Paid') {
            residenceAccountIds.add(rtf.AccountId);
        }
    }

    if (residenceAccountIds.isEmpty()) {
        return;
    }
 
    List<Account> accountsToUpdate = new List<Account>();
    
    Map<Id, List<RegulatoryTrxnFee>> accountFeeMap = new Map<Id, List<RegulatoryTrxnFee>>();
    for(RegulatoryTrxnFee fee : [SELECT Id, Status, AccountId FROM RegulatoryTrxnFee WHERE AccountId IN :residenceAccountIds AND FeeType__c = 'Renewal Unit Fee']) {
        if (!accountFeeMap.containsKey(fee.AccountId)) {
            accountFeeMap.put(fee.AccountId, new List<RegulatoryTrxnFee>());
        }
        accountFeeMap.get(fee.AccountId).add(fee);
    }
    
    for (Id accId : residenceAccountIds) {
        List<RegulatoryTrxnFee> fees = accountFeeMap.get(accId);

        Boolean allPaid = true;
        Boolean hasCanceled = false;

        for (RegulatoryTrxnFee fee : fees) {
            if (fee.Status != 'Paid') {
                allPaid = false;
            }
            if (fee.Status == 'Canceled') {
                hasCanceled = true;
            }
        }

        if (allPaid || (hasCanceled && !allPaid)) {
            try {
                Account acc = new Account(Id = accId, Status__c = 'Registered Active');
                accountsToUpdate.add(acc);
            } catch (Exception e) {
                System.debug('Exception occurred while updating account: ' + e.getMessage());
               
            }
        }
    }
 
    if (!accountsToUpdate.isEmpty()) {
        update accountsToUpdate;
    }
}