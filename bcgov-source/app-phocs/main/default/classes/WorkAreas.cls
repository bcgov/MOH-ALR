public without sharing class WorkAreas extends fflib_SObjectDomain{
    private static fflib_ISObjectUnitOfWork uow;

    public WorkAreas(List<Work_Area__c> sObjectList) {
        super(sObjectList);
    }

    public override void onAfterInsert(){
        createUpdatePublicGroup((List<Work_Area__c>)records, null);
    }

    public override void  onAfterUpdate(Map<Id, Sobject> oldRecordsMap){
        createUpdatePublicGroup((List<Work_Area__c>)records, (Map<Id, Work_Area__c>)oldRecordsMap);
    }

    public static void createUpdatePublicGroup(List<Work_Area__c> workAreaList, Map<Id, Work_Area__c> oldRecordsMap){
        WorkAreaPublicGroupQueueable queueable = new WorkAreaPublicGroupQueueable(WorkAreaList, oldRecordsMap);
        system.enqueueJob(queueable);
    }
    
   public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList){
            return new WorkAreas(sObjectList);
        }
    }
}