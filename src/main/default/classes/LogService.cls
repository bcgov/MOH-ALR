/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Class is for 
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]               
***********************************************************************************************/
public without sharing class LogService {

    public static List<Log_Event__e> logEvents;

    /**
     * publishLogs : Publish the platform event logs
     *               only if Logging is enabled in the custom setting
    */
    public static void publishLogs(){
        if(logEvents != null && !logEvents.isEmpty() && isLoggingEnabled()){
            List<Database.SaveResult> results = Eventbus.publish(logEvents);
            processFailedPlatformEvents(results);
        }
    }

    /**
     * publishLog : Method to log (Exception) platform event
     * @param  className - name of the calling class Ex:DynamicQuestionnaireFormController
     *         methodName - name of the method that an exception occurred Ex:submitSectionAnswers
     *         recordId - recordId if exists
     *         exception - the exception
   */
    public static void log(String className, String methodName, String recordId, Exception ex){
        if(logEvents == null){
            logEvents = new List<Log_Event__e>();
        }
        logEvents.add(createLogPlatformEvent(className, methodName, recordId, ex));
    }

    /**
     * publishLog : Method to publish a single log platform event
     * @param  className - name of the calling class Ex:DynamicQuestionnaireFormController
     *         methodName - name of the method that an exception occurred Ex:submitSectionAnswers
     *         recordId - recordId if exists
     *         exception - the exception
   */
    public static void logAndPublish(String className, String methodName, String recordId, Exception ex){
        if(logEvents == null){
            logEvents = new List<Log_Event__e>();
        }
        logEvents.add(createLogPlatformEvent(className, methodName, recordId, ex));
        publishLogs();
    }

    /**
   * processFailedPlatformEvents : create a log records for failed platform event records
   * @param  results
   */
    private static void processFailedPlatformEvents(List<Database.SaveResult> results){
        List<Log__c> logsToCreate = new  List<Log__c>();
        for (Database.SaveResult eventPublishingResult : results) {
            if (eventPublishingResult.isSuccess()) continue;
            for (Database.Error err : eventPublishingResult.getErrors()) {
                logsToCreate.add(createLog('Publish Platform Event', 'publish',
                        err.getMessage(), String.valueOf(err.getStatusCode())));
            }
        }
        if(!logsToCreate.isEmpty()){
            insert logsToCreate;
        }
    }

    /**
     * createLogPlatformEvent : return an instance of Log_PE__e
     * @param  className , methodName, recordId, exception
     * @return   Log_PE__e
    */
    private static Log_Event__e createLogPlatformEvent(String className, String methodName, String recordId, Exception exceptionMessage){
        Log_Event__e logEventPE = new Log_Event__e();
        logEventPE.Method_Name__c = methodName;
        logEventPE.Class_Name__c = className;
        logEventPE.Record_Id__c = recordId;
        logEventPE.Error_Message__c = exceptionMessage.getMessage();
        logEventPE.Stack_Trace__c = exceptionMessage.getStackTraceString();
        logEventPE.Line_Number__c = exceptionMessage.getLineNumber();
        logEventPE.Type__c = exceptionMessage.getTypeName();
        logEventPE.Running_User__c = UserInfo.getUserId();
        return logEventPE;
    }

    /**
     * createLog : return an instance of Log__c
     * @param  className , methodName, errorMessage, stackTrace, recordId
     * @return   Log__c
    */
    private static Log__c createLog(String className, String methodName, String errorMessage, String stackTrace){
        Log__c log = new Log__c();
        log.Method_Name__c = methodName;
        log.Class_Name__c = className;
        log.Error_Message__c = errorMessage;
        log.Stack_Trace__c = stackTrace;
        log.Running_User__c = UserInfo.getUserId();
        return log;
    }

    private static Boolean isLoggingEnabled(){
        Log_Configuration__c configSettings = Log_Configuration__c.getOrgDefaults();
        return configSettings.Enable_Logging__c;
    }
    
    /**
   * processFailedLogs: create a log records for Database.SaveResult
   * @param  className, methodName, results
   */
    public static void processFailedLogs(String className, String methodName,List<Database.SaveResult> results){
    
        List<Log__c> logsToCreate = new  List<Log__c>();        
        for (Database.SaveResult eventPublishingResult : results) {        
            if (eventPublishingResult.isSuccess()) {            
                continue;
            }
            for (Database.Error err : eventPublishingResult.getErrors()) {            
                logsToCreate.add(createLog(className, methodName,err.getMessage(), String.valueOf(err.getStatusCode())));                
            }
        }
        
        if(!logsToCreate.isEmpty()){        
            insert logsToCreate;
        }
    }        
}