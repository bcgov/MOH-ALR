/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Class is for 
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]               
***********************************************************************************************/
public with sharing class GenerateInvoiceController {
    public static String className = 'GenerateInvoiceController';
    private Final static Decimal defaultFee = 0;

/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is to
* @return:  
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    //ALR-40 - generateInvoices
    public static void generateInvoices(List<Asset> lstAsset) {
        Map<Id, List<Asset>> invoiceAssetMap = new Map<Id, List<Asset>>();
        Map<Id, BusinessLicenseApplication> blaAccMap = new Map<Id, BusinessLicenseApplication>();
        Map<Id, RegulatoryTrxnFee> transFeeAccMap = new Map<Id, RegulatoryTrxnFee>();        
        Id transFeeItemRT;
        List<RegulatoryTrxnFeeItem> transFeeItemList = new List<RegulatoryTrxnFeeItem>();
        Map<Id, Id> childParentAssetMap = new Map<Id, Id>();
        Map<Id, String> parentAmountMap = new Map<Id, String>();
        Map<Id, Asset> parentAssetMap = new Map<Id, Asset>();
        Asset oldRec = new Asset();
        DateTime dueDate = BCMOH_Constants.feeDueDateTime;//ALR-185
        try { 
            for(Asset assetRec : lstAsset) {
                system.debug('%% asset values '+assetRec.Type__c+' '+assetRec.AccountId+' '+assetRec.GenerateInvoice__c+' '+assetRec.recordTypeId+' '+assetRec.Status+' '+assetRec.Quantity+' '+assetRec.ParentId);
                if(assetRec.GenerateInvoice__c == true && assetRec.ParentId != NULL &&
                   assetRec.recordTypeId == BCMOH_Constants.unitRequestRecTypeId &&
                   assetRec.Status == BCMOH_Constants.pendingInvoiceStatus) {
                    system.debug('insdie for if aseet fvs'+assetRec.Id);
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
                                         Account.LicenseType__r.LateFee__c FROM Asset WHERE Id IN: childParentAssetMap.values() WITH SECURITY_ENFORCED]) {
                                             parentAmountMap.put(assetParentRecs.Id, assetParentRecs.Amount__c);
                                             parentAssetMap.put(assetParentRecs.Id, assetParentRecs);                                             
            }
            //fetch latest BLA record of the account as parent rec if fee rec
            for(BusinessLicenseApplication blaRec : [SELECT Id, AccountId, LicenseType.Name FROM BusinessLicenseApplication
                                                      WHERE AccountId IN: invoiceAssetMap.keySet() WITH SECURITY_ENFORCED
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
                RegulatoryTrxnFee transFeeRec = RenewalManagementController.createTransFeeRecord(BCMOH_Constants.transFeeRecTypeId, accId, parentId, BCMOH_Constants.unitFeeType, BCMOH_Constants.dueFeeStatus, dueDate);
                transFeeAccMap.put(accId, transFeeRec);
            }
            //Insert RegulatoryTrxnFee records
            Database.SaveResult[] srList = Database.Insert(transFeeAccMap.values());

            //set data for RegulatoryTrxnFeeItem records
            for(Id accId : invoiceAssetMap.keySet()) {
                for(Asset assetRec : invoiceAssetMap.get(accId)) {
                     String amtString = assetRec.Amount__c == NULL ? parentAssetMap.get(assetRec.ParentId).Amount__c : assetRec.Amount__c;
                     Decimal amtVal = amtString == BCMOH_Constants.fullUnitFee ? parentAssetMap.get(assetRec.ParentId).Account.LicenseType__r.UnitFee__c : parentAssetMap.get(assetRec.ParentId).Account.LicenseType__r.PartialUnitFee__c;
                        if(amtVal == NULL) {
                            amtVal = defaultFee;
                        }   
                    RegulatoryTrxnFeeItem transFeeItemRec = RenewalManagementController.createTransFeeItemRecord(transFeeItemRT, transFeeAccMap.get(assetRec.AccountId).Id, assetRec.Id, assetRec.Type__c, amtVal, assetRec.Quantity, BCMOH_Constants.unitFeeType);
                    transFeeItemList.add(transFeeItemRec);
                }
            }
            //Insert RegulatoryTrxnFeeItem records
                Database.SaveResult[] srList1 = Database.Insert(transFeeItemList);
        }
        catch(exception ex) {
            LogService.logAndPublish(className, 'generateInvoices', '', ex);
        }   
    }

/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is to
* @return:  
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static void generateRenewalInvoices(List<Asset> assetListNew) {
        Set<Id> accIdSet = new Set<Id>();
        Map<Id, RegulatoryTrxnFee> transFeeAccMap = new Map<Id, RegulatoryTrxnFee>();        
        try {
            Map<Id, List<Asset>> invoiceAssetMap = new Map<Id, List<Asset>>();
            Map<Id, BusinessLicenseApplication> blaAccMap = new Map<Id, BusinessLicenseApplication>();
            Id transFeeItemRT;
            List<RegulatoryTrxnFeeItem> transFeeItemList = new List<RegulatoryTrxnFeeItem>();
            DateTime dueDate = BCMOH_Constants.feeDueDateTime;//ALR-185
            
            //loop through updated assets and fetch parent recs with generate invoice true and quantity updated
            for(Asset assetRec : assetListNew) { 
                //if(assetRec.GenerateRenewalInvoice__c == true && assetRec.recordTypeId == BCMOH_Constants.parentAssetRecTypeId) {
                if(assetRec.GenerateRenewalInvoice__c == true) {
                       //decreasing units scenario
                       accIdSet.add(assetRec.AccountId);
                   }
            }
            
            //fetch all parent records associated to the updated asset's account
            for(Asset parentAssetRec : [SELECT Id, Quantity, Capacity__c, Amount__c, ParentId, Type__c, AccountId,
                                        Account.LicenseType__r.PartialUnitFee__c, Account.LicenseType__r.OneTimeFee__c,
                                        Account.LicenseType__r.UnitFee__c, Account.LicenseType__r.LateFee__c
                                        FROM Asset 
                                        WHERE AccountId IN: accIdSet AND Type__c IN: BCMOH_Constants.allALUnitTypes AND
                                        recordTypeId =: BCMOH_Constants.parentAssetRecTypeId AND Quantity > 0 WITH SECURITY_ENFORCED
                                        ORDER BY AccountId]) {//ALR-726 - added quantity greater than 0
                                            List<Asset> assetList = new List<Asset>();
                                            if(invoiceAssetMap.containsKey(parentAssetRec.AccountId)) {
                                                assetList = invoiceAssetMap.get(parentAssetRec.AccountId);
                                            }
                                            assetList.add(parentAssetRec);
                        					invoiceAssetMap.put(parentAssetRec.AccountId, assetList);
            }
            //fetch latest BLA record of the account as parent rec if fee rec
            for(BusinessLicenseApplication blaRec : [SELECT Id, AccountId, LicenseType.Name FROM BusinessLicenseApplication
                                                      WHERE AccountId IN: invoiceAssetMap.keySet() WITH SECURITY_ENFORCED
                                                      ORDER BY LastModifiedDate DESC]) {
                                                          if(!blaAccMap.containsKey(blaRec.AccountId)) {
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
                RegulatoryTrxnFee transFeeRec = RenewalManagementController.createTransFeeRecord(BCMOH_Constants.transFeeRecTypeId, accId, parentId, BCMOH_Constants.feeType, BCMOH_Constants.dueFeeStatus, dueDate);//ALR-829 - updated fee type (Renewal Unit Fee)
                transFeeAccMap.put(accId, transFeeRec);
            }
            
            //Insert RegulatoryTrxnFee records
            Database.SaveResult[] srList = Database.Insert(transFeeAccMap.values());
        
            //set data for RegulatoryTrxnFeeItem records
            for(Id accId : invoiceAssetMap.keySet()) {
                for(Asset assetRec : invoiceAssetMap.get(accId)) {
                    Decimal amtVal = defaultFee;
                    amtVal = assetRec?.Account?.LicenseType__r?.UnitFee__c ?? defaultFee;//ALR-726 (2) - for renewals, amount is always unit fee  
                    RegulatoryTrxnFeeItem transFeeItemRec = RenewalManagementController.createTransFeeItemRecord(transFeeItemRT, transFeeAccMap.get(assetRec.AccountId).Id, assetRec.Id, assetRec.Type__c, amtVal, assetRec.Quantity, BCMOH_Constants.feeType);//ALR-829 - updated fee type (Renewal Unit Fee)
                    transFeeItemList.add(transFeeItemRec);
                }
            }
            //Insert RegulatoryTrxnFeeItem records
            Database.SaveResult[] srList1 = Database.Insert(transFeeItemList);
        }
        catch(exception ex) {
            LogService.logAndPublish(className, 'generateRenewalInvoices', '', ex);
        }
    }     
}