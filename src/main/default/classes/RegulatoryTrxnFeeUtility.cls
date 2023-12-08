/**
* @Name              : RegulatoryTrxnFeeUtility
* @Description       : Controller class for RegulatoryTrxnFeeTriggerHandler
* @Author            : Sweta (Accenture)
* @StoryNo           : ALR-40
**/
public class RegulatoryTrxnFeeUtility {
    //method to check if fee recs status is updated to paid and update respective unit recs to paid based on FeeType__c of fee item recs
    public static void updateUnitStatus(List<RegulatoryTrxnFee> newRegTransList, Map<ID, SObject> oldRegTransMap, Map<ID, SObject> newRegTransMap) {
        Map<Id, RegulatoryTrxnFee> paidRegTransMap = new Map<Id, RegulatoryTrxnFee>();
        try {
            System.debug('^^ inside util ' + newRegTransList);
            //fetch trans fee records which have been paid
            for(RegulatoryTrxnFee regTransRec : (List<RegulatoryTrxnFee>)newRegTransMap.values()) {
                RegulatoryTrxnFee oldRec = (RegulatoryTrxnFee)oldRegTransMap.get(regTransRec.Id);
                if(regTransRec.recordTypeId == BCMOH_Constants.transFeeRecTypeId &&
                   regTransRec.Status == BCMOH_Constants.feeStatus && regTransRec.Status != oldRec.Status) {
                       System.debug('^^ inside if for ' + regTransRec);
                       paidRegTransMap.put(regTransRec.Id, regTransRec);
                }
            }
            //fetch child fee records' unit records
            Map<Id, Asset> updateAssetMap = fetchUnitRecs(paidRegTransMap);
            System.debug('^^ resp from child meth ' + updateAssetMap);
            //Update Asset records
            Database.SaveResult[] srList = Database.Update(updateAssetMap.values());
            for(Database.SaveResult sr : srList) {
                System.debug('^^ updated updateAssetMap recs' + sr.getId()+' '+sr.isSuccess());
            } 
        }
        catch(Exception ex) {
            system.debug('^^ im caught in RegulatoryTrxnFeeUtility.updateUnitStatus '+ex.getMessage());
        }
    }
    //fetch unit recs whose status needs to be updated
    public static Map<Id, Asset> fetchUnitRecs(Map<Id, RegulatoryTrxnFee> regTransMap) {
        Map<Id, RegulatoryTrxnFeeItem> transFeeItemMap = new Map<Id, RegulatoryTrxnFeeItem>();
        Map<Id, String> assetUpdateMap = new Map<Id, String>();
        Set<Id> assetParentIds = new Set<Id>();
        Set<Id> assetChildIds = new Set<Id>();
        Map<Id, Asset> updateAssetMap = new Map<Id, Asset>();
        try {
            System.debug('^^ inside child meth' + regTransMap);
            for(RegulatoryTrxnFeeItem feeItemRec : [SELECT Id, Unit__c, Unit__r.Status 
                                                    FROM RegulatoryTrxnFeeItem 
                                                    WHERE RegulatoryTrxnFeeId IN: regTransMap.keyset() AND
                                                    FeeType__c =: BCMOH_Constants.unitFeeType AND
                                                    Unit__r.Status !=: BCMOH_Constants.feeType]) {
                                                        System.debug('^^ inside for child meth' + feeItemRec);
                                                        //if unit fee, then update their status to paid
                                                        assetChildIds.add(feeItemRec.Unit__c);
                                                    }
            //fetch asset records to be updated to paid status
            for(Asset assetRec : [SELECT Id, Status FROM Asset
                                  WHERE Status !=: BCMOH_Constants.feeType AND
                                  Id IN: assetChildIds]) {
                                      System.debug('^^ inside for each asset renwal child meth' + assetRec);
                                      assetRec.Status = BCMOH_Constants.feeStatus;
                                      updateAssetMap.put(assetRec.Id, assetRec);
                                  }
        }
        catch(Exception ex) {
            system.debug('^^ im caught in RegulatoryTrxnFeeUtility.fetchFeeItemRecs '+ex.getMessage());
        }
        return updateAssetMap;
    }
}
//backup dont remove:
/* for(Asset assetRec : [SELECT Id, Status, RecordTypeId, ParentId, AccountId, 
                                  (SELECT Id, Unit__c, FeeType__c RegulatoryTrxnFeeId FROM Regulatory_Transaction_Fee_Items__r 
                                  WHERE RegulatoryTrxnFeeId IN: regTransMap.keyset()),
                                  (SELECT Id, Status, RecordTypeId, ParentId, AccountId FROM ChildAssets)
                                  FROM Asset]) {
                                      if(assetRec.Regulatory_Transaction_Fee_Items__r != NULL &&
                                         assetRec.Regulatory_Transaction_Fee_Items__r.size() > 0 &&
                                         assetRec.FeeType__c == BCMOH_Constants.feeType) {
                                             
                                         }
                                         
                                      }*/


/*if(feeItemRec.FeeType__c == BCMOH_Constants.feeType) {   
                                                        	//if renewals, then fetch child records of unit
                                                        	System.debug('^^ inside if renwal child meth' + feeItemRec);
                                                            assetParentIds.add(feeItemRec.Unit__c);
                                                        }
                                                        else */


/*(ParentId IN: assetParentIds OR Id IN: assetUpdateMap.keySet())]) */