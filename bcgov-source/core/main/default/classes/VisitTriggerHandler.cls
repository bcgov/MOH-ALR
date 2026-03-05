public with Sharing class VisitTriggerHandler {
    public static Id recordTypeALRInspection = Schema.SObjectType.InspectionAssessmentInd.getRecordTypeInfosByDeveloperName().get('Inspection').getRecordTypeId();
    public static Id recordTypePHOCSInspection = Schema.SObjectType.InspectionAssessmentInd.getRecordTypeInfosByDeveloperName().get('PHOCSInspection').getRecordTypeId();
    
    public static void afterUpdate(List<Visit> newList, Map<Id, Visit> oldMap) {
        Set<Id> completedInspectionIds = new Set<Id>();
        for (Visit insp : newList) {
            Visit oldInsp = oldMap.get(insp.Id);
            if (insp.Status == 'Completed' && oldInsp.Status != 'Completed') {
                if (insp.RecordTypeId == recordTypeALRInspection) {
                    RCVCreationHelper.createRegulatoryCodeViolations(insp.Id);
                }

                if (insp.RecordTypeId == recordTypePHOCSInspection) {
                    completedInspectionIds.add(insp.Id);
                }
            }
        }
        
        if (!completedInspectionIds.isEmpty()) {
            PHOCSInspectionAssessmentIndBatch.delInsInd(completedInspectionIds);
        }
    }
}