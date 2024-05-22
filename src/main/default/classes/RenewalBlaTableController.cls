/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this class Controller class for renewalBlaTable LWC
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
                           ALR-560             Sweta           Renewal verification and renewal mass email
***********************************************************************************************/
public with sharing class RenewalBlaTableController {
    public static String className = 'RenewalBlaTableController';

/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is for RenewalBlaTableController
* @return:  List of BusinessLicenseApplication
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    //fetch the BLA records to display on table
    @AuraEnabled(cacheable=true)
    public static List<BusinessLicenseApplication> getBlaRecs() {
        Map<Id, BusinessLicenseApplication> blaMap = new Map<Id, BusinessLicenseApplication>();
        List<BusinessLicenseApplication> blaList = new List<BusinessLicenseApplication>();
        try {
            //fetch account statuses
            Map<String, List<String>> accDetails = BCMOH_UtilityClass.getAccRenewals(BCMOH_Constants.renewalName);
            for(BusinessLicenseApplication blaRec : [SELECT Id, Name, ApplicationType, RenewalYear__c, 
                                                     Account.Id, Account.Name, Account.ParentId, Account.Parent.Name, 
                                                     Account.HealthAuthority__c, LicenseTypeId, LicenseType.Name,
                                                     Account.Status__c, Status, ExclusionReason__c
                                                     FROM BusinessLicenseApplication 
                                                     WHERE 
                                                     RecordType.DeveloperName =: BCMOH_Constants.blaRecType AND
                                                     Status IN: BCMOH_Constants.renewalTableStatus 
                                                     AND RenewalYear__c =: BCMOH_Constants.renewalYear 
                                                     AND Account.Status__c IN: accDetails.values()[0] WITH SECURITY_ENFORCED
                                                     Order By CreatedDate LIMIT 50000]) {
                                                         blaMap.put(blaRec.Id, blaRec);
                                                         blaList.add(blaRec);
                                                     }
                    }
        catch(exception ex) {
            LogService.logAndPublish(className, 'getBlaRecs', '', ex);
        }
        return blaList;
    }

/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is for RenewalBlaTableController
* @return: Boolean 
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    //update bla records FROM lwc
    @AuraEnabled
    public static Boolean updateBlaRecs(Object data) {
        List<BusinessLicenseApplication> blaUpdateList = new List<BusinessLicenseApplication>(); 
        Boolean hasUpdated = false;
        try {
            List<BusinessLicenseApplication> blaList = 
                (List<BusinessLicenseApplication>)JSON.deserialize(JSON.serialize(data), 
                                                                   List<BusinessLicenseApplication>.class);
            //ALR-820 - if status is updated to Cancelled or Excluded only then update the records
            for(BusinessLicenseApplication blaRec : blaList) {
                          blaUpdateList.add(blaRec); 
            }
          if(!blaUpdateList.isEmpty() && BusinessLicenseApplication.SObjectType.getDescribe().isUpdateable()) {
                Database.Update(blaUpdateList, false);
                hasUpdated = true;
            }
        }
        catch(exception ex) {
            LogService.logAndPublish(className, 'updateBlaRecs', '', ex);
            if(String.isNotBlank( ex.getMessage()) && ex.getMessage().contains('error:')) {
            	throw new AuraHandledException(ex.getMessage().split('error:')[1].split(':')[0] + '.');
            } 
            else {
                throw new AuraHandledException(ex.getMessage());
            }
        }
        return hasUpdated;
    }
}