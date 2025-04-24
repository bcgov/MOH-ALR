public without sharing class WorkAreas extends fflib_SObjectDomain{
    private static fflib_ISObjectUnitOfWork uow;

    public WorkAreas(List<Log_Event__e> sObjectList) {
        super(sObjectList);
    }

    public override void onAfterInsert(){
       
    }

    public override void  onAfterUpdate(Map<Id, Sobject> oldRecordsMap){
       
    }

   

   public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList){
            return new WorkAreas(sObjectList);
        }
    }
}