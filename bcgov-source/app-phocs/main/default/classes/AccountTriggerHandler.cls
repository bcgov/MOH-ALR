/**********************************************************************************************
* @Author:Accenture_PHOCS    
* @Date:      
* @Description: The purpose of this Class is to trigger Geocoder integration for PHOCS Accounts
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]  
                           EHIS-718               Vasanthi    Initial Version
***********************************************************************************************/
public class AccountTriggerHandler {
     private static Boolean skipGeocode = false;

    public static void setSkipGeocode(Boolean value) {
        skipGeocode = value;
    }

    public static void handleAfterUpdate(List<Account> newList, Map<Id, Account> oldMap) {
        List<Id> accountsToGeocode = new List<Id>();
		if (skipGeocode) {
            return;
        }
        for (Account acct : newList) {
            Account oldAcct = oldMap.get(acct.Id);

            if (acct.RecordTypeName__c != 'DrinkingWaterSourceIntake' &&
                acct.RecordTypeName__c != 'DrinkingWaterSystem' &&  acct.RecordTypeName__c != 'Facility') {
                continue;
            }

            Boolean addressChanged =
                acct.Physical_Address__Street__s != oldAcct.Physical_Address__Street__s ||
                acct.Physical_Address__City__s != oldAcct.Physical_Address__City__s ||
                acct.Physical_Address__StateCode__s != oldAcct.Physical_Address__StateCode__s;

            if (addressChanged) {
                accountsToGeocode.add(acct.Id);
            }
        }

        // Enqueue queueable job for each changed account
        for (Id acctId : accountsToGeocode) {
            System.enqueueJob(new GeocodeAddressQueueable(acctId));
        }
    }
}