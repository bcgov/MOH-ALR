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

        // Insert/update
        upsert rec;
    }
    		@AuraEnabled(cacheable=true)
				public static Map<String, String> getExistingComments(List<Id> defIds) {

    				Map<String, String> commentsMap = new Map<String, String>();

    				for (InspectionAssessmentInd rec : [
        					SELECT AssessmentIndDefinitionId, PHOCSInspectionComments__c
        					FROM InspectionAssessmentInd
        					WHERE AssessmentIndDefinitionId IN :defIds
    					])
                    {
        			commentsMap.put(rec.AssessmentIndDefinitionId, rec.PHOCSInspectionComments__c);
    		}

    return commentsMap;
}

}