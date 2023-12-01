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
    private Final Static String feeStatus = 'Due';
    private Final Static Decimal defaultFee = 0;
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
    //method to fetch existing reg auth type records
    public static Map<String, RegulatoryAuthorizationType> getRegAuthRecs() {
        Map<String, RegulatoryAuthorizationType> regAuthNameMap = new Map<String, RegulatoryAuthorizationType>();
        try {
            for(RegulatoryAuthorizationType regAuth : [SELECT Id, Name, RegulatoryAuthCategory, LateFee__c, 
                                                       OneTimeFee__c, PartialUnitFee__c, UnitFee__c 
                                                       FROM RegulatoryAuthorizationType LIMIT 100]) {
                                                           regAuthNameMap.put(regAuth.Name,regAuth);
                                                       }
        }
        catch(exception ex) {
            system.debug('inside reg auth type '+ex.getMessage());
        }
        return regAuthNameMap;
    }
    //method to create bla records for account (bulkified)
    public static Map<Id, BusinessLicenseApplication> createBlaRecords(Map<Id, Account> accMap, Map<Id, String> blaStatusMap, Map<String, RegulatoryAuthorizationType> regAuthNameMap) {
        List<BusinessLicenseApplication> blaRecCreateList = new List<BusinessLicenseApplication>();
        Map<Id, BusinessLicenseApplication> blaAccMap = new Map<Id, BusinessLicenseApplication>();
        try {
        //fetch recordtype Id
        system.debug('cda'+UserInfo.getUserId());
        String blaRecTypeId = Schema.getGlobalDescribe().get('BusinessLicenseApplication').getDescribe().getRecordTypeInfosByDeveloperName().get('Renewal').getRecordTypeId();
        //call BLA creation method for each account
        for(Account accRec : accMap.values()) {
            BusinessLicenseApplication blaRec = createBlaRecord(blaRecTypeId, accRec.Id, regAuthNameMap.get(accRec.ClassType__c).RegulatoryAuthCategory, regAuthNameMap.get(accRec.ClassType__c).Id, blaStatusMap.get(accRec.Id), DateTime.now(), renewalYear);
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
    public static List<RegulatoryTrxnFeeItem> createTransFeeItemRecords(Map<Id, Account> renewalFeeAccMap, Map<Id, RegulatoryTrxnFee> transFeeMap, Map<String, RegulatoryAuthorizationType> regAuthNameMap) {
        Id transFeeItemRT;
        Map<Id, RegulatoryTrxnFeeItem> transFeeItemAccMap = new Map<Id, RegulatoryTrxnFeeItem>();
        List<RegulatoryTrxnFeeItem> transFeeItemList = new List<RegulatoryTrxnFeeItem>();
        try {
            for(Account accRec : renewalFeeAccMap.values()) {
                //String cap = regAuthNameMap.get(accRec.ClassType__c);
                for(Asset assetRec : accRec.Assets) {
                	//String amtVal = assetRec.Amount__c == 'Unit Fee' ? cap.UnitFee__c : cap.PartialUnitFee__c;
                	Decimal amtVal = regAuthNameMap.get(accRec.ClassType__c).UnitFee__c;
                    system.debug('fee amt '+amtVal);
                    if(amtVal == NULL) {
                        amtVal = defaultFee;
			        }                   
                    RegulatoryTrxnFeeItem transFeeItemRec = createTransFeeItemRecord(transFeeItemRT, transFeeMap.get(accRec.Id).Id, assetRec.Id, assetRec.Type__c, amtVal, assetRec.Quantity, feeType);
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