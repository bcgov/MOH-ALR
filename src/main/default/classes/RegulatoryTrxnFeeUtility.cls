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
                   (regTransRec.Status == BCMOH_Constants.feeStatus || regTransRec.Status == BCMOH_Constants.cancelledStatus)
                   && regTransRec.Status != oldRec.Status) {
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
        Map<Id, String> assetChildIdStatusMap = new Map<Id, String>();
        Map<Id, Asset> updateAssetMap = new Map<Id, Asset>();
        try {
            System.debug('^^ inside child meth' + regTransMap);
            for(RegulatoryTrxnFeeItem feeItemRec : [SELECT Id, Unit__c, Unit__r.Status, RegulatoryTrxnFee.Status 
                                                    FROM RegulatoryTrxnFeeItem 
                                                    WHERE RegulatoryTrxnFeeId IN: regTransMap.keyset() AND
                                                    FeeType__c =: BCMOH_Constants.unitFeeType]) {
                                                        System.debug('^^ inside for child meth' + feeItemRec);
                                                        //if unit fee, then update their status to paid
                                                        if(feeItemRec.Unit__r.Status != feeItemRec.RegulatoryTrxnFee.Status) {
                                                        	System.debug('^^ inside for child meth if ' + feeItemRec);
                                                        	assetChildIdStatusMap.put(feeItemRec.Unit__c, feeItemRec.RegulatoryTrxnFee.Status);
                                                        }
                                                    }
            //asset with list of quantity update
            Map<Id, Integer> assetQuant = new Map<Id, Integer>();
            //fetch asset records to be updated to paid status
            for(Asset assetRec : [SELECT Id, Status, Quantity, ParentId, Parent.Quantity FROM Asset
                                  WHERE Status !=: BCMOH_Constants.feeType AND
                                  Id IN: assetChildIdStatusMap.keyset()]) {
                                      assetRec.Status = assetChildIdStatusMap.get(assetRec.Id);
                                      updateAssetMap.put(assetRec.Id, assetRec);
                                      //add child quantity to parent quantity if status is changed to paid
                                      if(assetChildIdStatusMap.get(assetRec.Id) == BCMOH_Constants.feeStatus) {
                                          Asset parentRec = new Asset(Id = assetRec.ParentId);
                                          if(updateAssetMap.containsKey(assetRec.ParentId)) {
                                              parentRec.Quantity = updateAssetMap.get(assetRec.ParentId).Quantity + 
                                                  assetRec.Quantity;
                                          }
                                          else {
                                              parentRec.Quantity = assetRec.Parent.Quantity + assetRec.Quantity;
                                          }
                                          updateAssetMap.put(assetRec.ParentId, parentRec);
                                      }
                                  }
        } 
        catch(Exception ex) {
            system.debug('^^ im caught in RegulatoryTrxnFeeUtility.fetchFeeItemRecs '+ex.getMessage());
        }
        return updateAssetMap;
    }
}