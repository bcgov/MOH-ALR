/**
 * Created by vivin on 2022-01-11.
 */

public without sharing class LogEvents extends fflib_SObjectDomain{
    private static fflib_ISObjectUnitOfWork uow;

    public LogEvents(List<Log_Event__e> sObjectList) {
        super(sObjectList);
    }

    public override void onAfterInsert(){
        processLogs();
    }

    private void processLogs(){
        uow = Application.UnitOfWork.newInstance();

        for(Log_Event__e logPE : (List<Log_Event__e>) this.Records){
            Log__c log = new Log__c();
            log.Method_Name__c = logPE.Method_Name__c;
            log.Class_Name__c = logPE.Class_Name__c;
            log.Error_Message__c = logPE.Error_Message__c;
            log.Stack_Trace__c = logPE.Stack_Trace__c;
            log.Line_Number__c = logPE.Line_Number__c;
            log.Type__c = logPE.Type__c;
            log.Record_Id__c = logPE.Record_Id__c;
            log.Running_User__c = logPE.Running_User__c;
            uow.registerNew(log);
        }
        uow.commitWork();
    }

   public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList){
            return new LogEvents(sObjectList);
        }
    }
}