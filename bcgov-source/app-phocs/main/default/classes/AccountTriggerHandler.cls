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
		if (skipGeocode) {
            return;
        }
        executeGeocoder(newList,oldMap);
    }
    public static void handleAfterInsert(List<Account> newList) {
    if (skipGeocode) {
        return;
    }
     executeGeocoder(newList, null);
  }
  
    
   private static void executeGeocoder(List<Account> accounts, Map<Id, Account> oldMap) {
    List<Id> accountsToGeocode = new List<Id>();

    for (Account acct : accounts) {
        if (acct.RecordTypeName__c != 'DrinkingWaterSourceIntake' &&
            acct.RecordTypeName__c != 'DrinkingWaterSystem' &&
            acct.RecordTypeName__c != 'Facility' && 
           	acct.RecordTypeName__c != 'PHOCSDairyFacility') {
            continue;
        }

        Boolean invokeGeocode = false;

        if (oldMap == null) {
            invokeGeocode =
                String.isNotBlank(acct.Physical_Address__Street__s) ||
                String.isNotBlank(acct.Physical_Address__City__s) ||
                String.isNotBlank(acct.Physical_Address__StateCode__s);
        } else {
            Account oldAcct = oldMap.get(acct.Id);
            invokeGeocode =
                acct.Physical_Address__Street__s != oldAcct.Physical_Address__Street__s ||
                acct.Physical_Address__City__s != oldAcct.Physical_Address__City__s ||
                acct.Physical_Address__StateCode__s != oldAcct.Physical_Address__StateCode__s;
        }

        if (invokeGeocode) {
            accountsToGeocode.add(acct.Id);
        }
    }

          if (!accountsToGeocode.isEmpty()) {
            System.enqueueJob(new GeocodeAddressQueueable(new List<Id>(accountsToGeocode)));
        }


   }

}