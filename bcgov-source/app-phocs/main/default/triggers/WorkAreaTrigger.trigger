trigger WorkAreaTrigger on Work_Area__c (before insert, after insert, after update) {
    fflib_SObjectDomain.triggerHandler(WorkAreas.class);
}