trigger RegulatoryCodeViolationTrigger on RegulatoryCodeViolation (before update, after update) {
    if (Trigger.isBefore && Trigger.isUpdate) {
        ViolationTriggerHandler.setResolvedDate(Trigger.new, Trigger.oldMap);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        ViolationTriggerHandler.resolveChildViolations(Trigger.new, Trigger.oldMap);
    }
}