/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this class 
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
                           ALR-40              ACN-ALR        Fee calculation for newly added unit(s)
***********************************************************************************************/
public interface TriggerHandler {
	void beforeInsert(List<SObject> newRecords);
    void beforeUpdate(List<SObject> oldRecords, List<SObject> newRecords, Map<ID, SObject> oldRecordMap, Map<ID, SObject> newRecordMap);
    void beforeDelete(List<SObject> oldRecords, Map<ID, SObject> oldRecordMap);
    void afterInsert(List<SObject> newRecords, Map<ID, SObject> newRecordMap);
    void afterUpdate(List<SObject> oldRecords, List<SObject> newRecords, Map<ID, SObject> oldRecordMap, Map<ID, SObject> newRecordMap);
    void afterDelete(List<SObject> oldRecords, Map<ID, SObject> oldRecordMap);
    void afterUndelete(List<SObject> newRecords, Map<ID, SObject> newRecordMap);
}