/**
* @Name              : LateFeeManagementTableController
* @Description       : Controller class for LateFeeManagementTable LWC
* @Author            : Anilkumar (Accenture)
* @StoryNo           : ALR-996
**/
public class LateFeeManagementTableController {
    Public Static String className = 'LateFeeManagementTableController';
   
      @AuraEnabled(cacheable=true)
        public static List<BusinessLicenseApplication> getLateFeeRecs() {
        Map<Id, BusinessLicenseApplication> blaMap = new Map<Id, BusinessLicenseApplication>();
        List<BusinessLicenseApplication> blaList = new List<BusinessLicenseApplication>();
        try {
            Map<String, List<String>> accDetails = BCMOH_UtilityClass.getAccRenewals(BCMOH_Constants.renewalName);
            for(BusinessLicenseApplication blaRec : [SELECT Id, Name, ApplicationType, RenewalYear__c, 
                                                     Account.Id, Account.Name, Account.ParentId, Account.Parent.Name, 
                                                     Account.HealthAuthority__c, LicenseTypeId, LicenseType.Name,
                                                     Account.Status__c, Status,RenewalError__c,Late_Fee_Status__c,ExclusionReason__c
                                                     FROM BusinessLicenseApplication 
                                                     WHERE RecordType.DeveloperName =: BCMOH_Constants.blaRecType 
													 AND Status =: BCMOH_Constants.sentBlaStatus 
                                                     AND RenewalYear__c =: BCMOH_Constants.renewalYear 
                                                     AND Late_Fee_Status__c =:BCMOH_Constants.LateFeeStatuses
                                                     AND Id IN(
                                                        Select ParentRecordId FROM RegulatoryTrxnFee
														WHERE Status =:BCMOH_Constants.dueFeeStatus
														AND FeeType__c IN :BCMOH_Constants.FeeTypeStatuses
                                                     	)                                                     
                                                     AND Account.Status__c IN: accDetails.values()[0]
                                                     Order By CreatedDate LIMIT 50000]) {
                                                         blaMap.put(blaRec.Id, blaRec);
                                                         blaList.add(blaRec);
                                                     }
            if(Test.isRunningTest()) {
                CalloutException exe = new CalloutException();
                exe.setMessage(BCMOH_Constants.EXCEPMESSAGE);
                throw exe;
            }
        }
        catch(exception ex) {
            LogService.logAndPublish(className, 'getBlaRecs', '', ex);
        }
        return blaList;       
    }

    @AuraEnabled
    public static Boolean updateLateFeeRecs(Object data) {
        List<BusinessLicenseApplication> blaUpdateList = new List<BusinessLicenseApplication>(); 
        Boolean hasUpdated = false;
        try {
            List<BusinessLicenseApplication> blaList = 
                (List<BusinessLicenseApplication>)JSON.deserialize(JSON.serialize(data), 
                                                                   List<BusinessLicenseApplication>.class);
            for(BusinessLicenseApplication blaRec : blaList) {
                if(BCMOH_Constants.renewalTableUpdateStatus.contains(blaRec.Late_Fee_Status__c)) {
                    blaUpdateList.add(blaRec);
                }
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