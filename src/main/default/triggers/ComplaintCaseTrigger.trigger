trigger ComplaintCaseTrigger on Case (before insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        System.debug('Inside Trigger');
        ComplaintCaseTriggerHandler.handleBeforeInsert(Trigger.new);
    }
}