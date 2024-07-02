/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this batch class to update bla records, related fee records
                and creating and attaching document based on criteria called FROM flow - Generate_Late_Fee 
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]  
                          ALR -997             Komal Gupta    Generate Renewal Late Fee Transaction      
***********************************************************************************************/
public with sharing class LateFeeManagementControllerBatch implements Database.Batchable<sObject> {
    //static Constants
    public static String className = 'LateFeeManagementControllerBatch';
    private Final static String blaLateFeeCancelledStatus = 'Cancelled';
    private Final static String blaLateFeeErroredStatus = 'Errored';
    private Final static String blaRecType = 'Renewal';
    private Final static String blaLateFeeStatus = 'Ready to Send';
    public static String parentAssetRT ='Units_Record_Type';
    private Final static String blaRenewalStatus = 'Sent';
    private Final static String renewalYear = BCMOH_Constants.renewalYear;
    private Final static String blaLateFeeExcludedStatus = 'Excluded';
    private Final static String blaRenewalExcludedStatus = 'Excluded';
    private Final static String blaRenewalCancelledStatus = 'Cancelled';
    public Final static List<String> allALUnitTypes = BCMOH_Constants.allALUnitTypes;
    private Final static String blaRenewalErroredStatus = 'Errored';
    private Final static String renewalName = 'LicenseRenewalCriteria';
    private Final static String RegTxnFeeStatus = 'Due';
    public Final static String activeStatusBl = BCMOH_Constants.activeStatusBl;
    public Final static String FeeTypeStatuses = 'Renewal Unit Fee';
    
    public List<Id> cONLIST = new List<Id>();

/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is for LateFeeManagementControllerBatch
* @return:  
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/    
    public LateFeeManagementControllerBatch(List<Id> conlist) {
        this.cONLIST = conlist;
    }

    public class FlowInputs {
        @InvocableVariable public List<Id> conId;
    }

/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is for LateFeeManagementControllerBatch
* @return:  void
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
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

/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is for LateFeeManagementControllerBatch
* @return:  void
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public Database.QueryLocator start(Database.BatchableContext BC){
        
        RenewalProcessCriteria__mdt renewalCriteriaRec = RenewalProcessCriteria__mdt.getInstance(renewalName);
        String accRecType = renewalCriteriaRec.AccountRecordType__c;
        List<String> accStatuses = renewalCriteriaRec.AccountStatuses__c.split(';');
        
        String query = 'SELECT Id, Status__c, LicenseType__c,'
            +' LicenseType__r.RegulatoryAuthCategory, LicenseType__r.UnitFee__c,'
            +' LicenseType__r.OneTimeFee__c, LicenseType__r.PartialUnitFee__c, LicenseType__r.LateFee__c,'
            +' Name, RegId__c, LicenseType__r.Name, Phone, Fax, ParentId, Parent.Name, Parent.Phone, Parent.BillingAddress,'//ALR-560
            +' (SELECT Id, Name, RecordTypeId,'
            +' LicenseTypeId, LicenseType.LateFee__c,'
            +' RenewalError__c, RenewalYear__c, ExclusionReason__c,'
            +' CreatedDate, ApplicationType, ApplicantId, ApplicationCategory,'
            +' Status, Late_Fee_Status__c, AccountId, Category, BusinessLicenseApplication.Account.Id'
            +' FROM BusinessLicenseApplicationAccount WHERE RecordType.DeveloperName =: blaRecType'
            +' AND RenewalYear__c =: renewalYear AND Status =: blaRenewalStatus'
            +' AND Late_Fee_Status__c = NULL AND Id IN(SELECT ParentRecordId FROM RegulatoryTrxnFee WHERE Status =:RegTxnFeeStatus AND FeeType__c =:FeeTypeStatuses)),'
            +' (SELECT Id, Location.VisitorAddress.Address FROM AssociatedLocations LIMIT 1),'
            +' (SELECT RegistrationCertificate__c FROM AccountBusinessLicenses__r WHERE Status =: activeStatusBl LIMIT 1),'
            +' (SELECT ContactId, Contact.Name, Contact.Phone, Contact.Email, Contact.MobilePhone, Roles FROM AccountContactRelations'//ALR-560
            +'  WHERE PrimaryContact__c = TRUE AND IsActive = TRUE LIMIT 1)'
            +' FROM Account'
            +' WHERE recordType.DeveloperName =: accRecType AND LicenseType__c != NULL';
       
        return Database.getQueryLocator(query);
    }

/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is for LateFeeManagementControllerBatch
* @return:  void
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public void execute(Database.BatchableContext BC, List<Account> latefeeaccList){
        Map<Id, Account> lateFeeAccMap = new Map<Id, Account>();
        List<BusinessLicenseApplication> blaList = new List<BusinessLicenseApplication>();
        Map<Id, BusinessLicenseApplication> lateFeeBLAMap = new Map<Id, BusinessLicenseApplication>();
        
        try {
            for(Account accrec : latefeeaccList) {
                for(BusinessLicenseApplication BLArec : accrec.BusinessLicenseApplicationAccount){
                    if(blaRenewalExcludedStatus.containsIgnoreCase(BLArec.Status)){
                        BLArec.Late_Fee_Status__c = blaLateFeeExcludedStatus;
                    } else if(blaRenewalCancelledStatus.containsIgnoreCase(BLArec.Status)){
                        BLArec.Late_Fee_Status__c = blaLateFeeCancelledStatus;
                    } else if(blaRenewalErroredStatus.containsIgnoreCase(BLArec.Status)){
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
            
            if(!blaList.isEmpty()){
                Update blaList;
            }
            
            Map<Id, RegulatoryTrxnFee> transFeeMap = RenewalManagementController.createLateFeeTransFeeRecords(lateFeeAccMap, lateFeeBLAMap);
            
            List<RegulatoryTrxnFeeItem> transFeeItemList = RenewalManagementController.createLateFeeTransFeeItemRecords(lateFeeBLAMap, transFeeMap);
            
            ServerSideDocumentGenerationController.startDocGenProcessLateFee(lateFeeAccMap, lateFeeBLAMap, transFeeMap, transFeeItemList);//?documents to be attached for ready for renewal and excluded?
        }
        catch(exception ex) {
            LogService.logAndPublish(className, 'execute', '', ex);
        }
    }

/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is for LateFeeManagementControllerBatch
* @return:  void
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public void finish(Database.BatchableContext BC){
        
    }
}