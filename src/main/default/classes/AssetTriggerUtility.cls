/**
* @Name              : AssetTriggerUtility
* @Description       : Controller class for AssetTriggerHandler
* @Author            : Sweta (Accenture)
* @StoryNo           : ALR-40
**/
public without sharing class AssetTriggerUtility {
    private Final Static Decimal defaultFee = 0;
    //ALR-40 - generateInvoices
    public static void generateInvoices(List<Asset> lstAsset, Map<Id, SObject> newAssetMap, Map<Id, SObject> oldAssetMap) {
        Map<Id, List<Asset>> invoiceAssetMap = new Map<Id, List<Asset>>();
        Map<Id, BusinessLicenseApplication> blaAccMap = new Map<Id, BusinessLicenseApplication>();
        String unitFeeType = 'Unit Fee';
        String feeStatus = 'Due';
        Id transFeeItemRT;
        List<RegulatoryTrxnFeeItem> transFeeItemList = new List<RegulatoryTrxnFeeItem>();
        Map<Id, Id> childParentAssetMap = new Map<Id, Id>();
        Map<Id, String> parentAmountMap = new Map<Id, String>();
        Map<Id, Asset> parentAssetMap = new Map<Id, Asset>();
        Asset oldRec = new Asset();
        DateTime dueDate = BCMOH_Constants.feeDueDateTime;//ALR-185
        try { 
//system.debug('^^ new asset list '+lstAsset);
            //system.debug('^^ new asset map '+newAssetMap);
            //system.debug('^^ old asset map '+oldAssetMap);
               
            String unitsRecordTypeId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Units_Record_Type').getRecordTypeId();
            String unitReqRecordTypeId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Unit_Request_Record_Type').getRecordTypeId();
            String transFeeRecTypeId = Schema.getGlobalDescribe().get('RegulatoryTrxnFee').getDescribe().getRecordTypeInfosByDeveloperName().get('TransactionFee').getRecordTypeId();
            Map<Id, RegulatoryTrxnFee> transFeeAccMap = new Map<Id, RegulatoryTrxnFee>();
            for(Asset assetRec : lstAsset) {
                if(Trigger.isUpdate) {
                	oldRec = (Asset)oldAssetMap.get(assetRec.Id);
                }
                system.debug('^^ in for new rec '+assetRec);
                system.debug('%% old asset values '+oldRec.GenerateInvoice__c+' '+oldRec.recordTypeId+' '+oldRec.Status+' '+oldRec.Quantity+' '+oldRec.ParentId);
                system.debug('%% new asset values '+assetRec.GenerateInvoice__c+' '+assetRec.recordTypeId+' '+assetRec.Status+' '+assetRec.Quantity+' '+oldRec.ParentId);
                if(assetRec.GenerateInvoice__c == true && assetRec.ParentId != NULL &&
                   assetRec.recordTypeId == unitReqRecordTypeId && 
                   assetRec.Status == BCMOH_Constants.pendingInvoiceStatus && 
                   (Trigger.isInsert || (Trigger.isUpdate && oldRec != NULL && oldRec.ParentId == NULL))) {
                    system.debug('^^ cds assetRec '+assetRec.Id);
                    List<Asset> assetList = new List<Asset>();
                    if(invoiceAssetMap.containsKey(assetRec.AccountId)) {
                        assetList = invoiceAssetMap.get(assetRec.AccountId);
                    }
                    assetList.add(assetRec);
                    invoiceAssetMap.put(assetRec.AccountId, assetList);
                    childParentAssetMap.put(assetRec.Id, assetRec.ParentId);
                }
            }
            //fetch amount of the child's parent records
            for(Asset assetParentRecs : [SELECT Id, Amount__c, AccountId, Account.LicenseType__r.PartialUnitFee__c,
                                         Account.LicenseType__r.OneTimeFee__c, Account.LicenseType__r.UnitFee__c,
                                         Account.LicenseType__r.LateFee__c 
                                         FROM Asset WHERE Id IN: childParentAssetMap.values()]) {
                                             parentAmountMap.put(assetParentRecs.Id, assetParentRecs.Amount__c);
                                             parentAssetMap.put(assetParentRecs.Id, assetParentRecs);
                                             
                                             
            }
            //fetch latest BLA record of the account as parent rec if fee rec
            for(BusinessLicenseApplication blaRec : [SELECT Id, AccountId, LicenseType.Name FROM BusinessLicenseApplication
                                                      WHERE AccountId IN: invoiceAssetMap.keySet()
                                                      ORDER BY LastModifiedDate DESC]) {
                                                          if(!blaAccMap.containsKey(blaRec.AccountId)) {
                                                              system.debug('^^ cds blaRec '+blaRec.Id);
                                                              blaAccMap.put(blaRec.AccountId, blaRec);
                                                          }
            }
            //set data for RegulatoryTrxnFee records
            for(Id accId : invoiceAssetMap.keySet()) {
                //ALR-726 (1) - populate blaId as parentId of TrxnFee record if present, else passing NULL.
                Id parentId = NULL;
                if(!blaAccMap.isEmpty() && blaAccMap.get(accId) != NULL) {
                    parentId = blaAccMap.get(accId).Id;
                }
                RegulatoryTrxnFee transFeeRec = RenewalManagementController.createTransFeeRecord(transFeeRecTypeId, accId, parentId, unitFeeType, feeStatus, dueDate);
                system.debug('^^ cds transFeeRec '+transFeeRec);
                transFeeAccMap.put(accId, transFeeRec);
            }
            //Insert RegulatoryTrxnFee records
            Database.SaveResult[] srList = Database.Insert(transFeeAccMap.values());
            for(Database.SaveResult sr : srList) {
                System.debug('inserted generateInvoices transFee data' + sr.getId()+' '+sr.isSuccess());
            }
            //set data for RegulatoryTrxnFeeItem records
            for(Id accId : invoiceAssetMap.keySet()) {
                for(Asset assetRec : invoiceAssetMap.get(accId)) {
                     String amtString = assetRec.Amount__c == NULL ? parentAssetMap.get(assetRec.ParentId).Amount__c : assetRec.Amount__c;
                     Decimal amtVal = amtString == 'Unit Fee' ? parentAssetMap.get(assetRec.ParentId).Account.LicenseType__r.UnitFee__c : parentAssetMap.get(assetRec.ParentId).Account.LicenseType__r.PartialUnitFee__c;
                        system.debug('^^ fee amt '+amtVal);
                        if(amtVal == NULL) {
                            amtVal = defaultFee;
                        }   
                    RegulatoryTrxnFeeItem transFeeItemRec = RenewalManagementController.createTransFeeItemRecord(transFeeItemRT, transFeeAccMap.get(assetRec.AccountId).Id, assetRec.Id, assetRec.Type__c, amtVal, assetRec.Quantity, unitFeeType);
                    transFeeItemList.add(transFeeItemRec);
                }
            }
            //Insert RegulatoryTrxnFeeItem records
            Database.SaveResult[] srList1 = Database.Insert(transFeeItemList);
            for(Database.SaveResult sr : srList1) {
                System.debug('^^ inserted generateInvoices transFeeItem data' + sr.getId()+' '+sr.isSuccess());
            }
        }
        catch(exception ex) {
            system.debug('^^ Im caught in generateInvoices '+ex.getMessage());
        }
    }
    /*********************************************************************************************/
    //triggered after update
    public static void generateRenewalInvoices(List<Asset> assetListNew, Map<Id, SObject> oldAssetMap, Map<Id, SObject> newAssetMap) {
        Set<Id> accIdSet = new Set<Id>();
        Map<Id, RegulatoryTrxnFee> transFeeAccMap = new Map<Id, RegulatoryTrxnFee>();
        String unitFeeType = 'Renewal Unit Fee';
        String feeStatus = 'Due';
        try {
            String transFeeRecTypeId = Schema.getGlobalDescribe().get('RegulatoryTrxnFee').getDescribe().getRecordTypeInfosByDeveloperName().get('TransactionFee').getRecordTypeId();
            String unitsRecordTypeId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Units_Record_Type').getRecordTypeId();
            Map<Id, List<Asset>> invoiceAssetMap = new Map<Id, List<Asset>>();
            Map<Id, BusinessLicenseApplication> blaAccMap = new Map<Id, BusinessLicenseApplication>();
            Id transFeeItemRT;
            List<RegulatoryTrxnFeeItem> transFeeItemList = new List<RegulatoryTrxnFeeItem>();
            DateTime dueDate = BCMOH_Constants.feeDueDateTime;//ALR-185
            
            //loop through updated assets and fetch parent recs with generate invoice true and quantity updated
            for(Asset assetRec : (List<Asset>)newAssetMap.values()) {
                Asset oldRec = (Asset)oldAssetMap.get(assetRec.Id);
                if(assetRec.GenerateRenewalInvoice__c == true && assetRec.recordTypeId == unitsRecordTypeId
                   && assetRec.Quantity != oldRec.Quantity) {
                       //decreasing units scenario
                       accIdSet.add(assetRec.AccountId);
                       system.debug('^^ cds cds assetRec '+assetRec.Id);
                   }
            }
            
            //fetch all parent records associated to the updated asset's account
            for(Asset parentAssetRec : [SELECT Id, Quantity, Capacity__c, Amount__c, ParentId, Type__c, AccountId,
                                        Account.LicenseType__r.PartialUnitFee__c, Account.LicenseType__r.OneTimeFee__c,
                                        Account.LicenseType__r.UnitFee__c, Account.LicenseType__r.LateFee__c
                                        FROM Asset 
                                        WHERE AccountId IN: accIdSet AND
                                        recordTypeId =: unitsRecordTypeId ORDER BY AccountId]) {
                                            List<Asset> assetList = new List<Asset>();
                                            if(invoiceAssetMap.containsKey(parentAssetRec.AccountId)) {
                                                assetList = invoiceAssetMap.get(parentAssetRec.AccountId);
                                            }
                                            assetList.add(parentAssetRec);
                        					invoiceAssetMap.put(parentAssetRec.AccountId, assetList);
            }
            //fetch latest BLA record of the account as parent rec if fee rec
            for(BusinessLicenseApplication blaRec : [SELECT Id, AccountId, LicenseType.Name FROM BusinessLicenseApplication
                                                      WHERE AccountId IN: invoiceAssetMap.keySet()
                                                      ORDER BY LastModifiedDate DESC]) {
                                                          if(!blaAccMap.containsKey(blaRec.AccountId)) {
                                                              system.debug('cds blaRec '+blaRec.Id);
                                                              blaAccMap.put(blaRec.AccountId, blaRec);
                                                          }
            }
            
            //set data for RegulatoryTrxnFee records
            for(Id accId : invoiceAssetMap.keySet()) {
                //ALR-726 (1) - populate blaId as parentId of TrxnFee record if present, else passing NULL.
                Id parentId = NULL;
                if(!blaAccMap.isEmpty() && blaAccMap.get(accId) != NULL) {
                    parentId = blaAccMap.get(accId).Id;
                }
                RegulatoryTrxnFee transFeeRec = RenewalManagementController.createTransFeeRecord(transFeeRecTypeId, accId, parentId, unitFeeType, feeStatus, dueDate);
                system.debug('^^ cds transFeeRec '+transFeeRec);
                transFeeAccMap.put(accId, transFeeRec);
            }
            
            //Insert RegulatoryTrxnFee records
            Database.SaveResult[] srList = Database.Insert(transFeeAccMap.values());
            for(Database.SaveResult sr : srList) {
                System.debug('inserted generateInvoices transFee data' + sr.getId()+' '+sr.isSuccess());
            }
            //set data for RegulatoryTrxnFeeItem records
            for(Id accId : invoiceAssetMap.keySet()) {
                for(Asset assetRec : invoiceAssetMap.get(accId)) {
                    Decimal amtVal = assetRec.Account.LicenseType__r.UnitFee__c;//ALR-726 (2) - for renewals, amount is always unit fee
                        system.debug('^^ fee amt '+amtVal);
                        if(amtVal == NULL) {
                            amtVal = defaultFee;
                        }   
                    RegulatoryTrxnFeeItem transFeeItemRec = RenewalManagementController.createTransFeeItemRecord(transFeeItemRT, transFeeAccMap.get(assetRec.AccountId).Id, assetRec.Id, assetRec.Type__c, amtVal, assetRec.Quantity, unitFeeType);
                    transFeeItemList.add(transFeeItemRec);
                }
            }
            //Insert RegulatoryTrxnFeeItem records
            Database.SaveResult[] srList1 = Database.Insert(transFeeItemList);
            for(Database.SaveResult sr : srList1) {
                System.debug('^^ inserted generateInvoices transFeeItem data' + sr.getId()+' '+sr.isSuccess());
            }
        }
        catch(exception ex) {
            system.debug('^^ Im caught in generateRenewalInvoices '+ex.getMessage());
        }
    }
}