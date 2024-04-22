/**********************************************************************************************
* @Author:Accenture_ALR Team   
* @Date:    
* @Description: The purpose of this Trigger is to trigger on particular events for Log_Event__e
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]  
***********************************************************************************************/
trigger LogEventTrigger on Log_Event__e (after insert) {
    fflib_SObjectDomain.triggerHandler(LogEvents.class);
}