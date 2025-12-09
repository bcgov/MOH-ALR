/*
*     Created by: Hari Pavan 
*     Created Date: 02-Dec-2025
*     User Story: EHIS-2661,2680
*     Description: This class saves and retrieves inspection assessment responses, including Free text comments and compliance status
*/



public with sharing class PHOCSInspectionAssessmentIndController {

    @AuraEnabled
    public static void getcmtresult(Id assessmentTaskId,
                                    Id definitionId,
                                    String comment,
                                    String result) {


        // Query existing response
        List<InspectionAssessmentInd> assqueresp = [
            SELECT Id, PHOCSInspectionComments__c, Result
            FROM InspectionAssessmentInd
            WHERE AssessmentIndDefinitionId = :definitionId
            AND AssessmentTaskId = :assessmentTaskId
            LIMIT 1
        ];

        InspectionAssessmentInd rec;

        // If record exists → update
        if (!assqueresp.isEmpty()) {
            rec = assqueresp[0];
        }
        else {
            rec = new InspectionAssessmentInd();
            rec.AssessmentIndDefinitionId = definitionId;
            rec.AssessmentTaskId = assessmentTaskId;
        }

        // Set values
        rec.PHOCSInspectionComments__c = comment;
        rec.Result = result;
         
                                        System.debug('🟢 Preparing to upsert InspectionAssessmentInd: ' + rec);


        // Insert/update
        upsert rec;
    }

    
   @AuraEnabled(cacheable=true)
	public static Map<String, String> getExistingCommentsByDefAndTask(List<Id> defIds, List<Id> taskIds) {
    Map<String, String> commentsMap = new Map<String, String>();
        
    if (defIds == null) defIds = new List<Id>();
    if (taskIds == null) taskIds = new List<Id>();

    defIds = new List<Id>(new Set<Id>(defIds).removeAll(new List<Id>{null}) ? new List<Id>(new Set<Id>(defIds)) : defIds);
    taskIds = new List<Id>(new Set<Id>(taskIds).removeAll(new List<Id>{null}) ? new List<Id>(new Set<Id>(taskIds)) : taskIds);

    if (defIds.isEmpty() || taskIds.isEmpty()) {
        return commentsMap;
    }

    // Query for matching comments (Definition + Task)
    for (InspectionAssessmentInd rec : [
        SELECT AssessmentIndDefinitionId, AssessmentTaskId, PHOCSInspectionComments__c
        FROM InspectionAssessmentInd
        WHERE AssessmentIndDefinitionId IN :defIds
        AND AssessmentTaskId IN :taskIds
    ]) {
        String key = String.valueOf(rec.AssessmentIndDefinitionId) + '|' + String.valueOf(rec.AssessmentTaskId);
        commentsMap.put(key, rec.PHOCSInspectionComments__c);
    }

    return commentsMap;
}


}