/**
* @Name              : RenewalManagementControllerBatch
* @Description       : batch class to create renewal records and related fee records based on criteria
					   called from flow - GenerateRenewalsForAccounts
* @Author            : Sweta (Accenture)
* @StoryNo           : ALR-36
**/
public class RenewalManagementControllerBatch implements Database.Batchable<sObject> {
    //Static Constants
    private Final Static String renewalName = 'LicenseRenewalCriteria';
    private Final Static String blaRecType = 'Renewal';
    private Final Static String blaCancelledStatus = 'Cancelled';
    private Final Static String renewalYear = BCMOH_Constants.renewalYear;
    private Final Static String blaRenewalStatus = 'Ready for Renewal';
    private Final Static String blaExcludedStatus = 'Excluded';
    Public static String parentAssetRT ='Units_Record_Type';
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
        Id jobId = Database.executeBatch(new RenewalManagementControllerBatch(conlist));
    }
    //start method
    public Database.QueryLocator start(Database.BatchableContext BC) {
        //fetching metadata
        RenewalProcessCriteria__mdt renewalCriteriaRec = RenewalProcessCriteria__mdt.getInstance(renewalName);
        String accRecType = renewalCriteriaRec.AccountRecordType__c;
        List<String> accStatuses = renewalCriteriaRec.AccountStatuses__c.split(';');
        //start query
        String query = 'SELECT Id, Status__c, ClassType__c,'
            +' (SELECT Id FROM BusinessLicenseApplicationAccount WHERE RecordType.DeveloperName =: blaRecType'
            +' AND Status !=: blaCancelledStatus AND RenewalYear__c =: renewalYear),'
            +' (SELECT Id, Type__c, Quantity, Amount__c FROM Assets WHERE RecordType.DeveloperName =: parentAssetRT)'
            +' FROM Account'
            +' WHERE recordType.DeveloperName =: accRecType'
            +' AND Status__c IN: accStatuses';
        return Database.getQueryLocator(query);
    }
    //execute method
    public void execute(Database.BatchableContext BC, List<Account> renewalAccList) {
        Map<Id, String> blaStatusMap = new Map<Id, String>();
        Map<Id, Account> renewalAccMap = new Map<Id, Account>();
        Map<Id, Account> renewalFeeAccMap = new Map<Id, Account>();
        List<Id> includedAccIds = CONLIST;
        system.debug('CONLIST includedAccIds '+' '+CONLIST+' '+includedAccIds);//delete later   
        system.debug('renewalAccList '+renewalAccList.size()+' '+renewalAccList);//delete later
        try {
            for(Account accRec : renewalAccList) {
                //check if bla already exists for the current year to avoid duplicates
                if(accRec.BusinessLicenseApplicationAccount.size() == 0) {
                    system.debug('bla '+accRec.BusinessLicenseApplicationAccount);
                    //create BLA with status as excluded and dont create child records if id not present in includedAccIds
                    blaStatusMap.put(accRec.Id, includedAccIds.contains(accRec.Id) ? blaRenewalStatus : blaExcludedStatus);
                    renewalAccMap.put(accRec.Id, accRec);
                    //if assets are not present dont create Fee records (change logic to remove nesting if later)
                    if(includedAccIds.contains(accRec.Id) && (accRec.Assets.size() > 0)) {
                        renewalFeeAccMap.put(accRec.Id, accRec);
                    }
                    system.debug('blaStatusMap renewalAccMap renewalFeeAccMap'+blaStatusMap+' '+renewalAccMap+' '+renewalFeeAccMap);//delete later
                }
        	}
            //fetch existing reg auth type records
            Map<String, RegulatoryAuthorizationType> regAuthNameMap = RenewalManagementController.getRegAuthRecs();
            //1) create BLA records in controlled class
            Map<Id, BusinessLicenseApplication> blaRecCreateMap = RenewalManagementController.createBlaRecords(renewalAccMap, blaStatusMap, regAuthNameMap);
            //2) create Trans Fee Record
            Map<Id, RegulatoryTrxnFee> transFeeMap = RenewalManagementController.createTransFeeRecords(renewalFeeAccMap, blaRecCreateMap);
            //3) create Trans Fee Item rec
            List<RegulatoryTrxnFeeItem> transFeeItemList = RenewalManagementController.createTransFeeItemRecords(renewalFeeAccMap, transFeeMap, regAuthNameMap);
        }
        catch(exception ex) {
            system.debug('Im caught in batch class'+ex.getMessage());//handle exceptions later
        }
    }
    //finish method
    public void finish(Database.BatchableContext BC) {
    }
}