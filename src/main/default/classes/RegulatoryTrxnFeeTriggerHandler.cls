/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this class is 
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
***********************************************************************************************/
public without sharing class RegulatoryTrxnFeeTriggerHandler implements TriggerHandler {
    public RegulatoryTrxnFeeTriggerHandler helper;
    //beforeInsert
    public void beforeInsert(List<RegulatoryTrxnFee> newRegTransList) {
    }
    //beforeUpdate
    public void beforeUpdate(List<RegulatoryTrxnFee> oldRegTransList, List<RegulatoryTrxnFee> newRegTransList, Map<ID, SObject> oldRegTransMap, Map<ID, SObject> newRegTransMap) {
    }
    //beforeDelete
    public void beforeDelete(List<RegulatoryTrxnFee> oldRegTransList, Map<ID, SObject> oldRegTransMap) {
    }
    //afterInsert
    public void afterInsert(List<RegulatoryTrxnFee> newRegTransList, Map<Id, SObject> newRegTransMap) {
    }
    //afterUpdate
    public void afterUpdate(List<RegulatoryTrxnFee> oldRegTransList, List<RegulatoryTrxnFee> newRegTransList, Map<ID, SObject> oldRegTransMap, Map<ID, SObject> newRegTransMap) {
       RegulatoryTrxnFeeUtility.updateUnitStatus(newRegTransList, oldRegTransMap, newRegTransMap);
    }
    //afterDelete
    public void afterDelete(List<RegulatoryTrxnFee> oldRegTransList, Map<ID, SObject> oldRegTransMap) {
    }
    //afterUndelete
    public void afterUndelete(List<RegulatoryTrxnFee> oldRegTransList, Map<ID, SObject> newRegTransMap) {
    }
}