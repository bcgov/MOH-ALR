/**
* @Name              : RenewalManagementControllerBatch
* @Description       : batch class to create renewal records and related fee records based on criteria
					   called from flow - GenerateRenewalsForAccounts
* @Author            : Sweta (Accenture)
* @StoryNo           : ALR-36
**/
public with sharing class RenewalManagementControllerBatch implements Database.Batchable<sObject> {
    //Static Constants
    Public Static String className = 'RenewalManagementControllerBatch';
    private Final Static String renewalName = 'LicenseRenewalCriteria';
    private Final Static String blaRecType = 'Renewal';
    private Final Static String blaCancelledStatus = 'Cancelled';
    private Final Static String renewalYear = BCMOH_Constants.renewalYear;
    private Final Static String blaRenewalStatus = 'Ready for Renewal';
    private Final Static String blaExcludedStatus = 'Excluded';
    Public static String parentAssetRT ='Units_Record_Type';
    public Final Static List<String> allALUnitTypes = BCMOH_Constants.allALUnitTypes;
    public Final Static String activeStatusBl = BCMOH_Constants.activeStatusBl;
    //flow attribute
    public List<Id> CONLIST = new List<Id>();
    
    //constructor
    public RenewalManagementControllerBatch(List<Id> conlist) {
        this.CONLIST = conlist;//assigns flow list to static const
    }
    //declaring invocable variables
    public class FlowInputs {
        @InvocableVariable public List<Id> ConId;
    }
    //fetching flow inputs into attribute and run batch 
    @invocablemethod
    public static void sendEmailTest(List<FlowInputs> requests) {
        List<Id> conlist = new List<Id>();
        for(FlowInputs req : requests) {
            if(req.conId != NULL) {
            	conlist.addAll(req.conId);
            }
        }
        //RenewalManagementControllerBatch clsName = new RenewalManagementControllerBatch(conlist);
        Id jobId = Database.executeBatch(new RenewalManagementControllerBatch(conlist), 400);
        //Id jobId = Database.executeBatch(clsName, 100);
    }
    //start method
    public Database.QueryLocator start(Database.BatchableContext BC) {
        //fetch acc status and record type from custom metadata
        RenewalProcessCriteria__mdt renewalCriteriaRec = RenewalProcessCriteria__mdt.getInstance(renewalName);
        String accRecType = renewalCriteriaRec.AccountRecordType__c;
        List<String> accStatuses = renewalCriteriaRec.AccountStatuses__c.split(';');
        //Map<String, List<String>> accDetails = BCMOH_UtilityClass.getAccRenewals(BCMOH_Constants.renewalName);
        Id tempAccId = '001As00000IGYmbIAH';
        //start query
        String query = 'SELECT Id, Status__c, LicenseType__c,'
            +' LicenseType__r.RegulatoryAuthCategory, LicenseType__r.UnitFee__c,'
            +' LicenseType__r.OneTimeFee__c, LicenseType__r.PartialUnitFee__c, LicenseType__r.LateFee__c,'
            +' Name, RegId__c, LicenseType__r.Name, Phone, Fax, ParentId, Parent.Name, Parent.Phone, Parent.BillingAddress,'//ALR-560
            +' (SELECT Id, Location.VisitorAddress.Address FROM AssociatedLocations LIMIT 1),'//ALR-560
            +' (SELECT RegistrationCertificate__c FROM AccountBusinessLicenses__r WHERE Status =: activeStatusBl LIMIT 1),'//ALR-560
            +' (SELECT Contact.Name, Contact.Phone, Contact.Email, Contact.MobilePhone, Roles FROM AccountContactRelations'//ALR-560
            +'  WHERE PrimaryContact__c = TRUE AND IsActive = TRUE LIMIT 1),'//ALR-560
            +' (SELECT Id FROM BusinessLicenseApplicationAccount WHERE RecordType.DeveloperName =: blaRecType'
            +'  AND Status !=: blaCancelledStatus AND RenewalYear__c =: renewalYear),'
            +' (SELECT Id, Type__c, Quantity, Amount__c FROM Assets WHERE RecordType.DeveloperName =: parentAssetRT AND Type__c IN: allALUnitTypes)'//ALR-769 - added type check
            +' FROM Account'
            +' WHERE recordType.DeveloperName =: accRecType AND LicenseType__c != NULL'
            +' AND Status__c IN: accStatuses';
            //+' AND Id =: tempAccId';
        return Database.getQueryLocator(query);
    }
    //execute method
    public void execute(Database.BatchableContext BC, List<Account> renewalAccList) {
        Map<Id, String> blaStatusMap = new Map<Id, String>();
        Map<Id, Account> renewalAccMap = new Map<Id, Account>();
        Map<Id, Account> renewalFeeAccMap = new Map<Id, Account>();
        List<Id> includedAccIds = CONLIST;
        system.debug('*** CONLIST includedAccIds '+' '+CONLIST+' '+includedAccIds);//delete later   
        system.debug('*** renewalAcc size List '+renewalAccList.size()+' '+renewalAccList);//delete later
        try {
            for(Account accRec : renewalAccList) {
                //check if non cancelled renewalbla already exists for the current year to avoid duplicates
                if(accRec.BusinessLicenseApplicationAccount.size() == 0) {
                    system.debug('*** expect null - bla on acc '+accRec.BusinessLicenseApplicationAccount);
                    //**As per ALR-560 and ALR-796 - No more applicable --> create BLA with status as excluded and dont create child records if id not present in includedAccIds
                    //As per ALR-560 and ALR-796 - create BLA with status as excluded and create child records 
                    blaStatusMap.put(accRec.Id, includedAccIds.contains(accRec.Id) ? blaRenewalStatus : blaExcludedStatus);
                    renewalAccMap.put(accRec.Id, accRec);
                    //**As per ALR-560 and ALR-796 - No more applicable -->if assets are not present dont create Fee records (change logic to remove nesting if later)
                    //ALR-560 & ALR-796 - Excluded Ids will also have Fee records generated if assets are present.
                    if(accRec.Assets != NULL && accRec.Assets.size() > 0) {//removed - includedAccIds.contains(accRec.Id) && 
                        renewalFeeAccMap.put(accRec.Id, accRec);
                    }
                    /*else if(accRec.Assets == NULL) {--TO DO:
                        blaStatusMap.put(accRec.Id, 'Errored');
                    }*/
                    system.debug('*** blaStatusMap renewalAccMap renewalFeeAccMap'+blaStatusMap+' '+renewalAccMap+' '+renewalFeeAccMap);//delete later
                }
        	}
            //1) create BLA records in controlled class
            Map<Id, BusinessLicenseApplication> blaRecCreateMap = RenewalManagementController.createBlaRecords(renewalAccMap, blaStatusMap);
            //2) create Trans Fee Record
            Map<Id, RegulatoryTrxnFee> transFeeMap = RenewalManagementController.createTransFeeRecords(renewalFeeAccMap, blaRecCreateMap);
            //3) create Trans Fee Item rec
            List<RegulatoryTrxnFeeItem> transFeeItemList = RenewalManagementController.createTransFeeItemRecords(renewalFeeAccMap, transFeeMap);
            //4) attach documents to bla records
            system.debug('%% before calling doc'+blaRecCreateMap+' ');
            system.debug('%% before calling doc'+' '+renewalAccList);
            ServerSideDocumentGenerationController.startDocGenProcess(renewalAccList, blaRecCreateMap, transFeeMap, transFeeItemList);//?documents to be attached for ready for renewal and excluded?
        }
        catch(exception ex) {
            system.debug('Im caught in batch class'+ex.getMessage());//handle exceptions later
            LogService.logAndPublish(className, 'execute', '', ex);
        }
    }
    //finish method
    public void finish(Database.BatchableContext BC) {
    }
}