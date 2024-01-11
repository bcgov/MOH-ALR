/**
* @Name              : RenewalBlaTableController
* @Description       : Controller class for renewalBlaTable LWC
* @Author            : Sweta (Accenture)
* @StoryNo           : ALR-560
**/
public class RenewalBlaTableController {
    //fetch the BLA records to display on table
    @AuraEnabled(cacheable=true)
    public static List<BusinessLicenseApplication> getBlaRecs() {
        Map<Id, BusinessLicenseApplication> blaMap = new Map<Id, BusinessLicenseApplication>();
        List<BusinessLicenseApplication> blaList = new List<BusinessLicenseApplication>();
        system.debug('cs0 entered');
        try {
            //fetch account statuses
            Map<String, List<String>> accDetails = BCMOH_UtilityClass.getAccRenewals(BCMOH_Constants.renewalName);
            for(BusinessLicenseApplication blaRec : [SELECT Id, Name, ApplicationType, RenewalYear__c, 
                                                     Account.Id, Account.Name, Account.ParentId, Account.Parent.Name, 
                                                     Account.HealthAuthority__c, LicenseTypeId, LicenseType.Name,
                                                     Account.Status__c, Status, ExclusionReason__c
                                                     FROM BusinessLicenseApplication 
                                                     WHERE 
                                                     //RecordType.DeveloperName =: BCMOH_Constants.blaRecType AND
                                                     Status IN: BCMOH_Constants.renewalTableStatus 
                                                     AND RenewalYear__c =: BCMOH_Constants.renewalYear 
                                                     AND Account.Status__c IN: accDetails.values()[0] 
                                                     Order By CreatedDate LIMIT 50000]) {
                                                         blaMap.put(blaRec.Id, blaRec);
                                                         blaList.add(blaRec);
                                                     }
            system.debug('qblaaa size '+blaMap.values().size()+' '+blaList);
        }
        catch(exception ex) {
            system.debug('qblaaa im caught getBlaRecs'+ex.getMessage());
        }
        return blaList;
    }
    //update bla records from lwc
    @AuraEnabled
    public static void updateBlaRecs(Object data) {
        try {
            system.debug('dxbha'+data+' '+JSON.serialize(data));
            List<BusinessLicenseApplication> blaUpdateList = 
                (List<BusinessLicenseApplication>)JSON.deserialize(JSON.serialize(data), 
                                                                   List<BusinessLicenseApplication>.class);
            system.debug('dxbha 1'+blaUpdateList);
            if(!blaUpdateList.isEmpty() && BusinessLicenseApplication.SObjectType.getDescribe().isUpdateable()) {
                system.debug('dxbha 2'+blaUpdateList);
                Database.Update(blaUpdateList, false);
            }
        }
        catch(exception e) {
            system.debug('qblaaa im caught updateBlaRecs'+e.getMessage());
            if(String.isNotBlank( e.getMessage()) && e.getMessage().contains('error:')) {
            	throw new AuraHandledException(e.getMessage().split('error:')[1].split(':')[0] + '.');
            } 
            else {
                throw new AuraHandledException(e.getMessage());
            }
        }
    }
}