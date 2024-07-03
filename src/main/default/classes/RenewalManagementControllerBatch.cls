/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this batch class to create renewal records and related fee records based on criteria
					   called FROM flow - GenerateRenewalsForAccounts
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
                           ALR-36             Sweta           License renewal initiation
***********************************************************************************************/
public with sharing class RenewalManagementControllerBatch implements Database.Batchable<sObject> {
    //static Constants
    public static String className = 'RenewalManagementControllerBatch';
    private Final static String renewalName = 'LicenseRenewalCriteria';
    private Final static String blaRecType = 'Renewal';
    private Final static String blaCancelledStatus = 'Cancelled';
    private Final static String renewalYear = BCMOH_Constants.renewalYear;
    private Final static String blaRenewalStatus = 'Ready for Renewal';
    private Final static String blaExcludedStatus = 'Excluded';
    public static String parentAssetRT ='Units_Record_Type';
    public Final static List<String> allALUnitTypes = BCMOH_Constants.allALUnitTypes;
    public Final static String activeStatusBl = BCMOH_Constants.activeStatusBl;
    public Final static List<String> Accountstatus = BCMOH_Constants.AccountTypeStatuses;

    public List<Id> recordListIds = new List<Id>();
    
    @AuraEnabled
    public static void enqueueJob(List<Id> recordIds) {
        Database.executeBatch(new RenewalManagementControllerBatch(recordIds));
    }
    
    public RenewalManagementControllerBatch(List<Id> recordIds) {
        this.recordListIds = recordIds;
    }
   
    public Database.QueryLocator start(Database.BatchableContext BC) {
        RenewalProcessCriteria__mdt renewalCriteriaRec = RenewalProcessCriteria__mdt.getInstance(renewalName);
        String accRecType = renewalCriteriaRec.AccountRecordType__c;
        List<String> accStatuses = renewalCriteriaRec.AccountStatuses__c.split(';');
        String query = 'SELECT Id, Status__c, LicenseType__c,'
            +' LicenseType__r.RegulatoryAuthCategory, LicenseType__r.UnitFee__c,'
            +' LicenseType__r.OneTimeFee__c, LicenseType__r.PartialUnitFee__c, LicenseType__r.LateFee__c,'
            +' Name, RegId__c, LicenseType__r.Name, Phone, Fax, ParentId, Parent.Name, Parent.Phone, Parent.BillingAddress,'//ALR-560
            +' (SELECT Id, Location.VisitorAddress.Address FROM AssociatedLocations LIMIT 1),'//ALR-560
            +' (SELECT RegistrationCertificate__c FROM AccountBusinessLicenses__r WHERE Status =: activeStatusBl LIMIT 1),'//ALR-560
            +' (SELECT ContactId, Contact.Name, Contact.Phone, Contact.Email, Contact.MobilePhone, Roles FROM AccountContactRelations'//ALR-560
            +'  WHERE IsActive = TRUE LIMIT 1),'//ALR-560 //ALR-854 - Added ContactId
            +' (SELECT Id FROM BusinessLicenseApplicationAccount WHERE RecordType.DeveloperName =: blaRecType'
            +'  AND Status !=: blaCancelledStatus AND RenewalYear__c =: renewalYear),'
            +' (SELECT Id, Type__c, Quantity, Amount__c FROM Assets WHERE RecordType.DeveloperName =: parentAssetRT'
            +' AND Type__c IN: allALUnitTypes AND Quantity > 0)'//ALR-769 - added type check, ALR-726 - quantity to be greater than 0
            +' FROM Account'
            +' WHERE recordType.DeveloperName =: accRecType AND LicenseType__c != NULL'
            +' AND Status__c IN: Accountstatus';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Account> renewalAccList) {
        Map<Id, String> blaStatusMap = new Map<Id, String>();
        Map<Id, Account> renewalAccMap = new Map<Id, Account>();
        Map<Id, Account> renewalFeeAccMap = new Map<Id, Account>();
        List<Id> includedAccIds = recordListIds;
                try {
            for(Account accRec : renewalAccList) {
                //check if non cancelled renewalbla already exists for the current year to avoid duplicates
                if(accRec.BusinessLicenseApplicationAccount.size() == 0) {
                    //**As per ALR-560 and ALR-796 - No more applicable --> create BLA with status as excluded and dont create child records if id not present in includedAccIds
                    //As per ALR-560 and ALR-796 - create BLA with status as excluded and create child records 
                    blaStatusMap.put(accRec.Id, includedAccIds.contains(accRec.Id) ? blaRenewalStatus : blaExcludedStatus);
                    renewalAccMap.put(accRec.Id, accRec);
                    //**As per ALR-560 and ALR-796 - No more applicable -->if assets are not present dont create Fee records (change logic to remove nesting if later)
                    //ALR-560 & ALR-796 - Excluded Ids will also have Fee records generated if assets are present.
                    if(accRec.Assets != NULL && accRec.Assets.size() > 0) {//removed - includedAccIds.contains(accRec.Id) && 
                        renewalFeeAccMap.put(accRec.Id, accRec);
                    }
                }
        	}
            //1) create BLA records in controlled class
            Map<Id, BusinessLicenseApplication> blaRecCreateMap = RenewalManagementController.createBlaRecords(renewalAccMap, blaStatusMap);
                        //2) create Trans Fee Record
            Map<Id, RegulatoryTrxnFee> transFeeMap = RenewalManagementController.createTransFeeRecords(renewalFeeAccMap, blaRecCreateMap);
                        //3) create Trans Fee Item rec
            List<RegulatoryTrxnFeeItem> transFeeItemList = RenewalManagementController.createTransFeeItemRecords(renewalFeeAccMap, transFeeMap);
            //4) attach documents to bla records
            ServerSideDocumentGenerationController.startDocGenProcess(renewalAccList, blaRecCreateMap, transFeeMap, transFeeItemList);//?documents to be attached for ready for renewal and excluded?
        }
        catch(exception ex) {
            LogService.logAndPublish(className, 'execute', '', ex);
        }
    }


    //finish method
    public void finish(Database.BatchableContext BC) {
    }
}