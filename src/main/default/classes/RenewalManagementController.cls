/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Controller class to create renewal records and related fee records
                referenced in GenerateRenewalsForAccounts flow and RenewalManagementControllerBatch class
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
                           ALR-36             Sweta           License renewal initiation
***********************************************************************************************/
public with sharing class RenewalManagementController {
    //static Constants
    public static String className = 'RenewalManagementController';
    private Final static String feeType = 'Renewal Unit Fee';
    private Final static String lateFeeType = 'Late Fee';
    private Final static String feeStatus = 'Due';
    private Final static Decimal defaultFee = 0;
   
    //method to return number of active accounts ready for renewal for current year
    @InvocableMethod
     public static List<Account> getAccountIds() {
        try {
            // Fetch account status and record type from custom metadata
            Map<String, List<String>> accDetails = BCMOH_UtilityClass.getAccRenewals(BCMOH_Constants.renewalName);
            
            // Query to get accounts with the required criteria
            List<Account> accounts = [SELECT Id, Name, ParentId, Status__c, LicenseType__c, HealthAuthority__c,
                                      (SELECT Id FROM BusinessLicenseApplicationAccount 
                                       WHERE RecordType.DeveloperName =: BCMOH_Constants.blaRecType
                                       AND Status !=: BCMOH_Constants.blaCancelledStatus 
                                       AND RenewalYear__c =: BCMOH_Constants.renewalYear)
                                      FROM Account 
                                      WHERE RecordType.DeveloperName =: accDetails.keySet() 
                                      AND LicenseType__c != NULL
                                      AND Status__c IN: accDetails.values()[0] 
                                      WITH SECURITY_ENFORCED];
            
            // Filter out accounts that have BusinessLicenseApplicationAccount records
            List<Account> filteredAccounts = new List<Account>();
            for (Account acc : accounts) {
                if (acc.BusinessLicenseApplicationAccount.isEmpty()) {
                    filteredAccounts.add(acc);
                }
            }
            
            return filteredAccounts;
        } catch (Exception ex) {
            LogService.logAndPublish('RenewalManagementController', 'getAccountIds', '', ex);
            throw new AuraHandledException(ex.getMessage());
        }
    }
    @AuraEnabled(cacheable=true)
    public static List<Account> fetchAccounts() {
    return [SELECT Id, RegId__c,Name, Parent.Name, Status__c, LicenseType__r.Name, HealthAuthority__c,
                   (SELECT Id FROM BusinessLicenseApplicationAccount WHERE RecordType.DeveloperName = 'Renewal'
                   AND Status ='Cancelled')
            FROM Account 
            WHERE Status__c IN ('Registered Active','Registered Active with Conditions', 
            'Registered Active Progressive Enforcement1')  
                  AND RecordType.DeveloperName = 'Residence'
               ];
    }

    //method to create bla records for account (bulkified)
    public static Map<Id, BusinessLicenseApplication> createBlaRecords(Map<Id, Account> accMap, Map<Id, String> blaStatusMap) {//, Map<String, RegulatoryAuthorizationType> regAuthNameMap) {
        List<BusinessLicenseApplication> blaRecCreateList = new List<BusinessLicenseApplication>();
        Map<Id, BusinessLicenseApplication> blaAccMap = new Map<Id, BusinessLicenseApplication>();
        try {
        //call BLA creation method for each account
        for(Account accRec : accMap.values()) {
            String regAuthCat = NULL;
            String licenseType = NULL;
            String relPrimaryContactId = NULL;//ALR-854
            if(accRec.LicenseType__c != NULL) {
                licenseType = accRec.LicenseType__c;
                if(accRec.LicenseType__r.RegulatoryAuthCategory != NULL) {
                	regAuthCat = accRec.LicenseType__r.RegulatoryAuthCategory;
            	}
            }
            //ALR-854 - account's related contact which is active and primary
            if(accRec.AccountContactRelations != NULL && accRec.AccountContactRelations.size() > 0) {
                relPrimaryContactId = accRec.AccountContactRelations[0].ContactId;
            }//ALR-854 ends
            BusinessLicenseApplication blaRec = createBlaRecord(BCMOH_Constants.renewalBlaRecTypeId, accRec.Id, regAuthCat, licenseType, blaStatusMap.get(accRec.Id), DateTime.now(), BCMOH_Constants.renewalYear, relPrimaryContactId);//ALR-854 - added relPrimaryContactId 
            blaRecCreateList.add(blaRec);
            blaAccMap.put(accRec.Id, blaRec);
        }
        //Insert BLA records
        Database.SaveResult[] srList = Database.Insert(blaAccMap.values(), false);//feth FROM map later
        }
        catch(exception ex) {
            LogService.logAndPublish(className, 'createBlaRecords', '', ex);
        }
        return blaAccMap;
    }

   //method to form a bla record with given parameters
    public static BusinessLicenseApplication createBlaRecord(Id recordTypeId, Id accId, String blaCategory, Id licenseTypeId, String blaStatus, DateTime appliedDate, String renewalYear, Id contactId) {//ALR-854 - added contactId
        BusinessLicenseApplication blaRec = new BusinessLicenseApplication(
            recordTypeId = recordTypeId,
            AccountId = accId,
            Category = blaCategory,
            LicenseTypeId = licenseTypeId,
            Status = blaStatus,
            AppliedDate = appliedDate,
            RenewalYear__c = renewalYear,
        	PrimaryOwnerId = contactId);//ALR-854 - added PrimaryOwnerId
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
        }
        catch(exception ex) {
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
                    // Decimal amtVal = defaultFee;
                    // amtVal = accRec.LicenseType__r?.UnitFee__c ?? defaultFee;
                    Decimal amtVal = (accRec.LicenseType__r.UnitFee__c == NULL) ? defaultFee :  accRec.LicenseType__r.UnitFee__c;
                    RegulatoryTrxnFeeItem transFeeItemRec = createTransFeeItemRecord(transFeeItemRT, transFeeMap.get(accRec.Id).Id, assetRec.Id, assetRec.Type__c, amtVal, assetRec.Quantity, feeType);
                    transFeeItemList.add(transFeeItemRec);
                }
            }
            //Insert RegulatoryTrxnFeeItem records
            Database.SaveResult[] srList = Database.Insert(transFeeItemList, false);
        }
        catch(exception ex) {
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


    // start of ALR-997
    //create transaction fee records for Late Fee
    public static Map<Id, RegulatoryTrxnFee> createLateFeeTransFeeRecords(Map<Id, Account> lateFeeAccMap, Map<Id, BusinessLicenseApplication> lateFeeBLAMap) {
        Map<Id, RegulatoryTrxnFee> transFeeAccMap = new Map<Id, RegulatoryTrxnFee>();
        DateTime dueDate = BCMOH_Constants.feeDueDateTime;//ALR-185
        try {
            //fetch recordtype
            String transFeeRecTypeId = Schema.getGlobalDescribe().get('RegulatoryTrxnFee').getDescribe().getRecordTypeInfosByDeveloperName().get('TransactionFee').getRecordTypeId();
            //create RegulatoryTrxnFee records
            for(BusinessLicenseApplication BLARec : lateFeeBLAMap.values()) {
                RegulatoryTrxnFee transFeeRec = createLateFeeTransFeeRecord(transFeeRecTypeId, BLARec.AccountId, BLARec.Id, lateFeeType, feeStatus, dueDate);
                transFeeAccMap.put(BLARec.Id, transFeeRec);
            }
            //Insert RegulatoryTrxnFee records
            Database.SaveResult[] srList = Database.Insert(transFeeAccMap.values(), false);
        }
        catch(exception ex) {
            LogService.logAndPublish(className, 'createLateFeeTransFeeRecords', '', ex);
        }
        return transFeeAccMap;
    }

    //method to form a RegulatoryTrxnFee record with given parameters for Late Fee
    public static RegulatoryTrxnFee createLateFeeTransFeeRecord(Id recordTypeId, Id accId, Id parentId, String lateFeeType, String feeStatus, DateTime dueDate) {
        RegulatoryTrxnFee transFeeRec = new RegulatoryTrxnFee(
            recordTypeId = recordTypeId,
            AccountId = accId,
            ParentRecordId = parentId,
            FeeType__c = lateFeeType,
            Status = feeStatus,
            DueDate = dueDate);
        return transFeeRec;
    }
 
    //create transaction fee ITEM records for Late Fee
    public static List<RegulatoryTrxnFeeItem> createLateFeeTransFeeItemRecords(Map<Id, BusinessLicenseApplication> lateFeeBLAMap, Map<Id, RegulatoryTrxnFee> transFeeMap) {//COF , Map<String, RegulatoryAuthorizationType> regAuthNameMap) {
        Id transFeeItemRT;
        Map<Id, RegulatoryTrxnFeeItem> transFeeItemAccMap = new Map<Id, RegulatoryTrxnFeeItem>();
        List<RegulatoryTrxnFeeItem> transFeeItemList = new List<RegulatoryTrxnFeeItem>();
        try {
            for(BusinessLicenseApplication BLARec : lateFeeBLAMap.values()) {
                Decimal amtVal = defaultFee;
                    if(BLARec.LicenseTypeId != NULL && BLARec.LicenseType.LateFee__c != NULL) {
                       amtVal = BLARec.LicenseType.LateFee__c;
                    }
                    RegulatoryTrxnFeeItem transFeeItemRec = createLateFeeTransFeeItemRecord(transFeeItemRT, transFeeMap.get(BLARec.Id).Id, amtVal, 1, lateFeeType);
                    transFeeItemList.add(transFeeItemRec);
            }

            //Insert RegulatoryTrxnFeeItem records
            Database.SaveResult[] srList = Database.Insert(transFeeItemList, false);
        }
        catch(exception ex) {
            LogService.logAndPublish(className, 'createLateFeeTransFeeItemRecords', '', ex);
        }
        return transFeeItemList;
    }

    //method to form a RegulatoryTrxnFeeItem record with given parameters for Late Fee
     public static RegulatoryTrxnFeeItem createLateFeeTransFeeItemRecord(Id recordTypeId, Id regTrxnFeeId, Decimal amtValue, Decimal quantValue, String lateFeeType) {
         RegulatoryTrxnFeeItem transFeeItemRec = new RegulatoryTrxnFeeItem(
         RegulatoryTrxnFeeId = regTrxnFeeId,
         Name = 'Late Fee',
         Amount__c = amtValue,
         Quantity__c = quantValue,
         FeeAmount = amtValue * quantValue,
         FeeType__c = lateFeeType);
         return transFeeItemRec;  
     }
    //end of ALR-997
}