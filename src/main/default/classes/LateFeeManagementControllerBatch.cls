/**
* @Name              : LateFeeManagementControllerBatch
* @Description       : batch class to update bla records, related fee records and creating and attaching document
					   based on criteria called from flow - Generate_Late_Fee
* @Author            : Komal Gupta (Accenture)
* @StoryNo           : ALR-997
**/
public with sharing class LateFeeManagementControllerBatch implements Database.Batchable<sObject> {
    //Static Constants
    Public Static String className = 'LateFeeManagementControllerBatch';
    private Final Static String blaLateFeeCancelledStatus = 'Cancelled';
    private Final Static String blaLateFeeErroredStatus = 'Errored';
    private Final Static String blaRecType = 'Renewal';
    private Final Static String blaLateFeeStatus = 'Ready to Send';
    Public static String parentAssetRT ='Units_Record_Type';
    private Final Static String blaRenewalStatus = 'Sent';
    private Final Static String renewalYear = BCMOH_Constants.renewalYear;
    private Final Static String blaLateFeeExcludedStatus = 'Excluded';
    private Final Static String blaRenewalExcludedStatus = 'Excluded';
    private Final Static String blaRenewalCancelledStatus = 'Cancelled';
    public Final Static List<String> allALUnitTypes = BCMOH_Constants.allALUnitTypes;
    private Final Static String blaRenewalErroredStatus = 'Errored';
    private Final Static String renewalName = 'LicenseRenewalCriteria';
    private Final Static String RegTxnFeeStatus = 'Due';
    public Final Static String activeStatusBl = BCMOH_Constants.activeStatusBl;
    
    public List<Id> CONLIST = new List<Id>();
    
    public LateFeeManagementControllerBatch(List<Id> conlist) {
        this.CONLIST = conlist;
    }
    public class FlowInputs {
        @InvocableVariable public List<Id> ConId;
    }
    @invocablemethod
    public static void sendEmailTest(List<FlowInputs> requests) {
        List<Id> conlist = new List<Id>();
        for(FlowInputs req : requests) {
            if(req.conId != NULL) {
            	conlist.addAll(req.conId);
            }
        }
        Id jobId = Database.executeBatch(new LateFeeManagementControllerBatch(conlist), 400);

    }
    public Database.QueryLocator start(Database.BatchableContext BC){
        
        RenewalProcessCriteria__mdt renewalCriteriaRec = RenewalProcessCriteria__mdt.getInstance(renewalName);
        String accRecType = renewalCriteriaRec.AccountRecordType__c;
        List<String> accStatuses = renewalCriteriaRec.AccountStatuses__c.split(';');
        
        String query = 'SELECT Id, Status__c, LicenseType__c,'
            +' LicenseType__r.RegulatoryAuthCategory, LicenseType__r.UnitFee__c,'
            +' LicenseType__r.OneTimeFee__c, LicenseType__r.PartialUnitFee__c, LicenseType__r.LateFee__c,'
            +' Name, RegId__c, LicenseType__r.Name, Phone, Fax, ParentId, Parent.Name, Parent.Phone, Parent.BillingAddress,'//ALR-560
            +' (SELECT Id, Name, RecordTypeId,'
            +' RenewalError__c, RenewalYear__c, ExclusionReason__c,'
            +' CreatedDate, ApplicationType, ApplicantId, ApplicationCategory,'
            +' Status, Late_Fee_Status__c, AccountId, Category, BusinessLicenseApplication.Account.Id'
            +' FROM BusinessLicenseApplicationAccount WHERE RecordType.DeveloperName =: blaRecType'
            +' AND RenewalYear__c =: renewalYear AND Status =: blaRenewalStatus'
            +' AND Late_Fee_Status__c = NULL),'
            +' (SELECT Id, Location.VisitorAddress.Address FROM AssociatedLocations LIMIT 1),'
            +' (SELECT RegistrationCertificate__c FROM AccountBusinessLicenses__r WHERE Status =: activeStatusBl LIMIT 1),'
            +' (SELECT ContactId, Contact.Name, Contact.Phone, Contact.Email, Contact.MobilePhone, Roles FROM AccountContactRelations'//ALR-560
            +'  WHERE PrimaryContact__c = TRUE AND IsActive = TRUE LIMIT 1),'
            +' (SELECT Id, Status, Name FROM RegulatoryTrxnFees where Status =: RegTxnFeeStatus LIMIT 1)'
            +' FROM Account'
            +' WHERE recordType.DeveloperName =: accRecType AND LicenseType__c != NULL'
            +' AND Status__c IN: accStatuses';
            
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC, List<Account> latefeeaccList){
        Map<Id, Account> lateFeeAccMap = new Map<Id, Account>();
        List<RegulatoryTrxnFee> regTxnList = new List<RegulatoryTrxnFee>();
        List<BusinessLicenseApplication> blaList = new List<BusinessLicenseApplication>();
        Map<Id, BusinessLicenseApplication> lateFeeBLAMap = new Map<Id, BusinessLicenseApplication>();

        try {
            for(Account accrec : latefeeaccList) {
                for(BusinessLicenseApplication BLArec : accrec.BusinessLicenseApplicationAccount){
                    if(BLArec.Status == blaRenewalExcludedStatus){
                        BLArec.Late_Fee_Status__c = blaLateFeeExcludedStatus;
                    } else if(BLArec.Status == blaRenewalCancelledStatus){
                        BLArec.Late_Fee_Status__c = blaLateFeeCancelledStatus;
                    } else if(BLArec.Status == blaRenewalErroredStatus){
                        BLArec.Late_Fee_Status__c = blaLateFeeErroredStatus;
                    } else {
                        BLArec.Late_Fee_Status__c = blaLateFeeStatus;
                    }
                    blaList.add(BLArec);
                    
                    if(accrec != NULL) {
                        lateFeeAccMap.put(accrec.Id, accrec);
                    }
                    
                    if(accrec.BusinessLicenseApplicationAccount != NULL && accrec.BusinessLicenseApplicationAccount.size() > 0) {
                        lateFeeBLAMap.put(BLArec.Id, BLArec);
                    }
                } 
        	}
            Update blaList;
            
            Map<Id, RegulatoryTrxnFee> transFeeMap = RenewalManagementController.createLateFeeTransFeeRecords(lateFeeAccMap, lateFeeBLAMap);
            
            List<RegulatoryTrxnFeeItem> transFeeItemList = RenewalManagementController.createLateFeeTransFeeItemRecords(lateFeeBLAMap, transFeeMap);

            system.debug('%% before calling doc'+lateFeeBLAMap+' ');
            system.debug('%% before calling doc'+' '+lateFeeAccMap);
            ServerSideDocumentGenerationController.startDocGenProcessLateFee(lateFeeAccMap, lateFeeBLAMap, transFeeMap, transFeeItemList);//?documents to be attached for ready for renewal and excluded?
        }
        catch(exception ex) {
            system.debug('Im caught in batch class'+ex.getMessage());//handle exceptions later
            LogService.logAndPublish(className, 'execute', '', ex);
        }
    }
    
    public void finish(Database.BatchableContext BC){
        
    }
}