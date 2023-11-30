trigger LogEventTrigger on Log_Event__e (after insert) {
    fflib_SObjectDomain.triggerHandler(LogEvents.class);
}