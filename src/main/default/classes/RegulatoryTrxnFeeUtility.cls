/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Controller class for RegulatoryTrxnFeeTriggerHandler
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
                           ALR-40              Sweta          Fee calculation for newly added unit(s)
***********************************************************************************************/
public with sharing class RegulatoryTrxnFeeUtility {
    public static String className = 'RegulatoryTrxnFeeUtility';

/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is for RegulatoryTrxnFeeUtility
* @return:  void
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    //method to check if fee recs status is updated to paid and update respective unit recs to paid based on FeeType__c of fee item recs
    public static void updateUnitStatus(List<RegulatoryTrxnFee> newRegTransList, Map<ID, SObject> oldRegTransMap, Map<ID, SObject> newRegTransMap) {
        Map<Id, RegulatoryTrxnFee> paidRegTransMap = new Map<Id, RegulatoryTrxnFee>();
        try {
            //fetch trans fee records which have been paid
            for(RegulatoryTrxnFee regTransRec : (List<RegulatoryTrxnFee>)newRegTransMap.values()) {
                RegulatoryTrxnFee oldRec = (RegulatoryTrxnFee)oldRegTransMap.get(regTransRec.Id);
                if(regTransRec.recordTypeId == BCMOH_Constants.transFeeRecTypeId &&
                   (regTransRec.Status == BCMOH_Constants.feeStatus || regTransRec.Status == BCMOH_Constants.cancelledStatus)
                   && regTransRec.Status != oldRec.Status) {
                       paidRegTransMap.put(regTransRec.Id, regTransRec);
                }
            }
            //fetch child fee records' unit records
            Map<Id, Asset> updateAssetMap = fetchUnitRecs(paidRegTransMap);
            //Update Asset records
            Database.SaveResult[] srList = Database.Update(updateAssetMap.values());
        }
        catch(Exception ex) {
            LogService.logAndPublish(className, 'updateUnitStatus', '', ex);
        }
    }

/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is for RegulatoryTrxnFeeUtility
* @return:  Map<Id, Asset>
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    //fetch unit recs whose status needs to be updated
    public static Map<Id, Asset> fetchUnitRecs(Map<Id, RegulatoryTrxnFee> regTransMap) {
        Set<Id> assetChildIds = new Set<Id>();
        Map<Id, String> assetChildIdStatusMap = new Map<Id, String>();
        Map<Id, Asset> updateAssetMap = new Map<Id, Asset>();
        try {
            for(RegulatoryTrxnFeeItem feeItemRec : [SELECT Id, Unit__c, Unit__r.Status, RegulatoryTrxnFee.Status 
                                                    FROM RegulatoryTrxnFeeItem 
                                                    WHERE RegulatoryTrxnFeeId IN: regTransMap.keyset() AND
                                                    FeeType__c =: BCMOH_Constants.unitFeeType WITH SECURITY_ENFORCED]) {
                                                        //if unit fee, then update their status to paid
                                                        if(feeItemRec.Unit__r.Status != feeItemRec.RegulatoryTrxnFee.Status) {
                                                        	assetChildIdStatusMap.put(feeItemRec.Unit__c, feeItemRec.RegulatoryTrxnFee.Status);
                                                        }
                                                    }
            //asset with list of quantity update
            Map<Id, Integer> assetQuant = new Map<Id, Integer>();
            //fetch asset records to be updated to paid status
            for(Asset assetRec : [SELECT Id, Status, Quantity, ParentId, Parent.Quantity FROM Asset
                                  WHERE Status !=: BCMOH_Constants.feeType AND
                                  Id IN: assetChildIdStatusMap.keyset() WITH SECURITY_ENFORCED]) {
                                      assetRec.Status = assetChildIdStatusMap.get(assetRec.Id);
                                      updateAssetMap.put(assetRec.Id, assetRec);
                                      //add child quantity to parent quantity if status is changed to paid
                                      if(assetChildIdStatusMap.get(assetRec.Id) == BCMOH_Constants.feeStatus) {
                                          Asset parentRec = new Asset(Id = assetRec.ParentId);
                                          if(updateAssetMap.containsKey(assetRec.ParentId)) {
                                              parentRec.Quantity = updateAssetMap.get(assetRec.ParentId).Quantity + 
                                                  assetRec.Quantity;
                                          }else {
                                              parentRec.Quantity = assetRec.Parent.Quantity + assetRec.Quantity;
                                          }
                                          updateAssetMap.put(assetRec.ParentId, parentRec);
                                      }
                                  }
        } 
        catch(Exception ex) {
            LogService.logAndPublish(className, 'fetchUnitRecs', '', ex);
        }
        return updateAssetMap;
    }
}