/**
* @Name              : RenewalManagementController
* @Description       : Controller class to create renewal records and related fee records
					   referenced in GenerateRenewalsForAccounts flow and RenewalManagementControllerBatch class
* @Author            : Sweta (Accenture)
* @StoryNo           : ALR-36
**/
public class RenewalManagementController {
    //Static Constants
    private Final Static Integer renewalYear = Date.Today().Year();
    private Final Static String feeType = 'Renewal Unit Fee';
    private Final Static String feeStatus = 'Paid';
    //method to return number of active accounts for renewal for current year
    @InvocableMethod
    public static List<String> getAccountIds() {
        List<String> activeAccCount = new List<String>();
        Integer countValue = 0;
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
        return activeAccCount;
    }
    //method to create bla records for account (bulkified)
    public static Map<Id, BusinessLicenseApplication> createBlaRecords(Map<Id, Account> accMap, Map<Id, String> blaStatusMap) {
        List<BusinessLicenseApplication> blaRecCreateList = new List<BusinessLicenseApplication>();
        Map<Id, BusinessLicenseApplication> blaAccMap = new Map<Id, BusinessLicenseApplication>();
        try {
        //fetch recordtype Id
        system.debug('cda'+UserInfo.getUserId());
        String blaRecTypeId = Schema.getGlobalDescribe().get('BusinessLicenseApplication').getDescribe().getRecordTypeInfosByDeveloperName().get('Renewal').getRecordTypeId();
        //fetch RegulatoryAuthorizationType Ids with Name and Category
        Map<String ,Id> regAuthNameIdMap = new Map<String ,Id>();
        Map<String, String> regAuthNameCategoryMap = new Map<String, String>();
        for(RegulatoryAuthorizationType regAuth : [SELECT Id, Name, RegulatoryAuthCategory 
                                                       FROM RegulatoryAuthorizationType LIMIT 100]) {
                                                           regAuthNameIdMap.put(regAuth.Name, regAuth.Id);
                                                           regAuthNameCategoryMap.put(regAuth.Name, regAuth.RegulatoryAuthCategory);
                                                       }
            //call BLA creation method for each account
            for(Account accRec : accMap.values()) {
            BusinessLicenseApplication blaRec = createBlaRecord(blaRecTypeId, accRec.Id, regAuthNameCategoryMap.get(accRec.ClassType__c), regAuthNameIdMap.get(accRec.ClassType__c), blaStatusMap.get(accRec.Id), DateTime.now(), renewalYear);
            blaRecCreateList.add(blaRec);
            blaAccMap.put(accRec.Id, blaRec);
        }
        //Insert BLA records
        Database.SaveResult[] srList = Database.Insert(blaAccMap.values());//feth from map later
            for(Database.SaveResult sr : srList) {
                System.debug('inserted bla data' + sr.getId()+' '+sr.isSuccess());
            }
        }
        catch(exception ex) {
            system.debug('Im caught'+ex.getMessage());
        }
        return blaAccMap;
    }
    
    //method to form a bla record with given parameters
    public static BusinessLicenseApplication createBlaRecord(Id recordTypeId, Id accId, String blaCategory, Id licenseTypeId, String blaStatus, DateTime appliedDate, Integer renewalYear) {
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
        try {
            //fetch recordtype
        	String transFeeRecTypeId = Schema.getGlobalDescribe().get('RegulatoryTrxnFee').getDescribe().getRecordTypeInfosByDeveloperName().get('TransactionFee').getRecordTypeId();
            //create RegulatoryTrxnFee records
            for(Account accRec : renewalFeeAccMap.values()) {
                RegulatoryTrxnFee transFeeRec = createTransFeeRecord(transFeeRecTypeId, accRec.Id, blaRecCreateMap.get(accRec.Id).Id, feeType, feeStatus);
                transFeeAccMap.put(accRec.Id, transFeeRec);
            }
            //Insert RegulatoryTrxnFee records
            Database.SaveResult[] srList = Database.Insert(transFeeAccMap.values());
            for(Database.SaveResult sr : srList) {
                System.debug('inserted transFee data' + sr.getId()+' '+sr.isSuccess());
            }
        }
        catch(exception ex) {
            system.debug('Im caught in transFee'+ex.getMessage());
        }
        return transFeeAccMap;
    }
    //method to form a RegulatoryTrxnFee record with given parameters
    public static RegulatoryTrxnFee createTransFeeRecord(Id recordTypeId, Id accId, Id blaId, String feeType, String feeStatus) {
        RegulatoryTrxnFee transFeeRec = new RegulatoryTrxnFee(
            recordTypeId = recordTypeId,
            AccountId = accId,
            ParentRecordId = blaId,
            FeeType__c = feeType,
            Status = feeStatus);
        return transFeeRec;
    }
    
    //create transaction fee ITEM records
    public static List<RegulatoryTrxnFeeItem> createTransFeeItemRecords(Map<Id, Account> renewalFeeAccMap, Map<Id, RegulatoryTrxnFee> transFeeMap) {
        Id transFeeItemRT;
        Map<Id, RegulatoryTrxnFeeItem> transFeeItemAccMap = new Map<Id, RegulatoryTrxnFeeItem>();
        List<RegulatoryTrxnFeeItem> transFeeItemList = new List<RegulatoryTrxnFeeItem>();
        try {
            for(Account accRec : renewalFeeAccMap.values()) {
                for(Asset assetRec : accRec.Assets) {
                    RegulatoryTrxnFeeItem transFeeItemRec = createTransFeeItemRecord(transFeeItemRT, transFeeMap.get(accRec.Id).Id, assetRec.Id, assetRec.Type__c, assetRec.Capacity__c, assetRec.Quantity);
                    transFeeItemList.add(transFeeItemRec);
                }
            }
            //Insert RegulatoryTrxnFee records
            Database.SaveResult[] srList = Database.Insert(transFeeItemList);
            for(Database.SaveResult sr : srList) {
                System.debug('inserted transFee Item data' + sr.getId()+' '+sr.isSuccess());
            }
        }
        catch(exception ex) {
            system.debug('Im caught in trans fee item '+ex.getMessage());
        }
        return transFeeItemList;
    }
    //method to form a RegulatoryTrxnFeeItem record with given parameters
     public static RegulatoryTrxnFeeItem createTransFeeItemRecord(Id recordTypeId, Id regTrxnFeeId, Id assetId, String assetType, String capValue, Decimal quantValue) {
         RegulatoryTrxnFeeItem transFeeItemRec = new RegulatoryTrxnFeeItem(
         RegulatoryTrxnFeeId = regTrxnFeeId,
         Unit__c = assetId,
         Name = assetType,
         Amount__c = Integer.valueOf(capValue),
         Quantity__c = quantValue,
         FeeAmount = Integer.valueOf(capValue) * quantValue);
         return transFeeItemRec;  
     }
}