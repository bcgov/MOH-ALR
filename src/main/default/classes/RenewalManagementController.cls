/**
* @Name              : RenewalManagementController
* @Description       : Controller class to create renewal records and related fee records
                       referenced in GenerateRenewalsForAccounts flow and RenewalManagementControllerBatch class
* @Author            : Sweta (Accenture)
* @StoryNo           : ALR-36
**/
public with sharing class RenewalManagementController {
    //Static Constants
    Public Static String className = 'RenewalManagementController';
    private Final Static String feeType = 'Renewal Unit Fee';
    private Final Static String feeStatus = 'Due';
    private Final Static Decimal defaultFee = 0;
    //method to return number of active accounts for renewal for current year
    @InvocableMethod
    public static List<String> getAccountIds() {
        List<String> activeAccCount = new List<String>();
        Integer countValue = 0;
        try {
            RenewalProcessCriteria__mdt renewalCriteriaRec = RenewalProcessCriteria__mdt.getInstance(BCMOH_Constants.renewalName);
            String accRecType = renewalCriteriaRec.AccountRecordType__c;
            List<String> accStatuses = renewalCriteriaRec.AccountStatuses__c.split(';');
            for(Account accRec : [SELECT Id, (SELECT Id FROM BusinessLicenseApplicationAccount WHERE RecordType.DeveloperName =: BCMOH_Constants.blaRecType
                                              AND Status !=: BCMOH_Constants.blaCancelledStatus AND RenewalYear__c =: BCMOH_Constants.renewalYear)
                                  FROM Account WHERE recordType.DeveloperName =: accRecType
                                  AND Status__c IN: accStatuses]) {
                                      if(accRec.BusinessLicenseApplicationAccount.size() == 0) {
                                          countValue++;
                                      }
                                  }
            activeAccCount.add(String.valueOf(countValue));
        }
        catch(exception ex) {
            system.debug('Im caught in getAccountIds'+ex.getMessage());
            LogService.logAndPublish(className, 'getAccountIds', '', ex);
        }
        return activeAccCount;
    }
    //method to create bla records for account (bulkified)
    public static Map<Id, BusinessLicenseApplication> createBlaRecords(Map<Id, Account> accMap, Map<Id, String> blaStatusMap) {//, Map<String, RegulatoryAuthorizationType> regAuthNameMap) {
        List<BusinessLicenseApplication> blaRecCreateList = new List<BusinessLicenseApplication>();
        Map<Id, BusinessLicenseApplication> blaAccMap = new Map<Id, BusinessLicenseApplication>();
        try {
        //fetch recordtype Id
        system.debug('cda'+UserInfo.getUserId());
        String blaRecTypeId = Schema.getGlobalDescribe().get('BusinessLicenseApplication').getDescribe().getRecordTypeInfosByDeveloperName().get('Renewal').getRecordTypeId();
        //call BLA creation method for each account
        for(Account accRec : accMap.values()) {
            String regAuthCat = NULL;
            String licenseType = NULL;
            if(accRec.LicenseType__c != NULL) {
                licenseType = accRec.LicenseType__c;
                if(accRec.LicenseType__r.RegulatoryAuthCategory != NULL) {
                	regAuthCat = accRec.LicenseType__r.RegulatoryAuthCategory;
            	}
            }
            BusinessLicenseApplication blaRec = createBlaRecord(blaRecTypeId, accRec.Id, regAuthCat, licenseType, blaStatusMap.get(accRec.Id), DateTime.now(), BCMOH_Constants.renewalYear);
            blaRecCreateList.add(blaRec);
            blaAccMap.put(accRec.Id, blaRec);
        }
        //Insert BLA records
        Database.SaveResult[] srList = Database.Insert(blaAccMap.values(), false);//feth from map later
            for(Database.SaveResult sr : srList) {
                System.debug('inserted bla data' + sr.getId()+' '+sr.isSuccess());
            }
        }
        catch(exception ex) {
            system.debug('Im caught'+ex.getMessage());
            LogService.logAndPublish(className, 'createBlaRecords', '', ex);
        }
        return blaAccMap;
    }
    //method to form a bla record with given parameters
    public static BusinessLicenseApplication createBlaRecord(Id recordTypeId, Id accId, String blaCategory, Id licenseTypeId, String blaStatus, DateTime appliedDate, String renewalYear) {
        BusinessLicenseApplication blaRec = new BusinessLicenseApplication(
            recordTypeId = recordTypeId,
            AccountId = accId,
            Category = blaCategory,
            LicenseTypeId = licenseTypeId,
            Status = blaStatus,
            AppliedDate = appliedDate,
            RenewalYear__c = renewalYear);
        return blaRec;
    }
    //create transaction fee records
    public static Map<Id, RegulatoryTrxnFee> createTransFeeRecords(Map<Id, Account> renewalFeeAccMap, Map<Id, BusinessLicenseApplication> blaRecCreateMap) {
        Map<Id, RegulatoryTrxnFee> transFeeAccMap = new Map<Id, RegulatoryTrxnFee>();
        DateTime dueDate = BCMOH_Constants.feeDueDateTime;//ALR-185
        try {
            //fetch recordtype
            String transFeeRecTypeId = Schema.getGlobalDescribe().get('RegulatoryTrxnFee').getDescribe().getRecordTypeInfosByDeveloperName().get('TransactionFee').getRecordTypeId();
            //create RegulatoryTrxnFee records
            for(Account accRec : renewalFeeAccMap.values()) {
                RegulatoryTrxnFee transFeeRec = createTransFeeRecord(transFeeRecTypeId, accRec.Id, blaRecCreateMap.get(accRec.Id).Id, feeType, feeStatus, dueDate);
                transFeeAccMap.put(accRec.Id, transFeeRec);
            }
            //Insert RegulatoryTrxnFee records
            Database.SaveResult[] srList = Database.Insert(transFeeAccMap.values(), false);
            for(Database.SaveResult sr : srList) {
                System.debug('inserted transFee data' + sr.getId()+' '+sr.isSuccess());
            }
        }
        catch(exception ex) {
            system.debug('Im caught in transFee'+ex.getMessage());
            LogService.logAndPublish(className, 'createTransFeeRecords', '', ex);
        }
        return transFeeAccMap;
    }
    //method to form a RegulatoryTrxnFee record with given parameters
    public static RegulatoryTrxnFee createTransFeeRecord(Id recordTypeId, Id accId, Id parentId, String feeType, String feeStatus, DateTime dueDate) {
        RegulatoryTrxnFee transFeeRec = new RegulatoryTrxnFee(
            recordTypeId = recordTypeId,
            AccountId = accId,
            ParentRecordId = parentId,
            FeeType__c = feeType,
            Status = feeStatus,
            DueDate = dueDate);
        return transFeeRec;
    }
    
    //create transaction fee ITEM records
    public static List<RegulatoryTrxnFeeItem> createTransFeeItemRecords(Map<Id, Account> renewalFeeAccMap, Map<Id, RegulatoryTrxnFee> transFeeMap) {//COF , Map<String, RegulatoryAuthorizationType> regAuthNameMap) {
        Id transFeeItemRT;
        Map<Id, RegulatoryTrxnFeeItem> transFeeItemAccMap = new Map<Id, RegulatoryTrxnFeeItem>();
        List<RegulatoryTrxnFeeItem> transFeeItemList = new List<RegulatoryTrxnFeeItem>();
        try {
            for(Account accRec : renewalFeeAccMap.values()) {
                for(Asset assetRec : accRec.Assets) {
                    Decimal amtVal = defaultFee;
                    if(accRec.LicenseType__c != NULL && accRec.LicenseType__r.UnitFee__c != NULL) {
                       amtVal = accRec.LicenseType__r.UnitFee__c;
                    }
                    system.debug('fee amt '+amtVal);
                    /*if(amtVal == NULL) {
                        amtVal = defaultFee;
                    }*/                   
                    RegulatoryTrxnFeeItem transFeeItemRec = createTransFeeItemRecord(transFeeItemRT, transFeeMap.get(accRec.Id).Id, assetRec.Id, assetRec.Type__c, amtVal, assetRec.Quantity, feeType);
                    transFeeItemList.add(transFeeItemRec);
                }
            }
            //Insert RegulatoryTrxnFeeItem records
            Database.SaveResult[] srList = Database.Insert(transFeeItemList, false);
            for(Database.SaveResult sr : srList) {
                System.debug('inserted transFee Item data' + sr.getId()+' '+sr.isSuccess());
            }
        }
        catch(exception ex) {
            system.debug('Im caught in trans fee item '+ex.getMessage());
            LogService.logAndPublish(className, 'createTransFeeItemRecords', '', ex);
        }
        return transFeeItemList;
    }
    //method to form a RegulatoryTrxnFeeItem record with given parameters
     public static RegulatoryTrxnFeeItem createTransFeeItemRecord(Id recordTypeId, Id regTrxnFeeId, Id assetId, String assetType, Decimal amtValue, Decimal quantValue, String feeType) {
         RegulatoryTrxnFeeItem transFeeItemRec = new RegulatoryTrxnFeeItem(
         RegulatoryTrxnFeeId = regTrxnFeeId,
         Unit__c = assetId,
         Name = assetType,
         Amount__c = amtValue,
         Quantity__c = quantValue,
         FeeAmount = amtValue * quantValue,
         FeeType__c = feeType);
         return transFeeItemRec;  
     }
}