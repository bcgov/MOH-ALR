/**********************************************************************************************
* @Author: Accenture
* @Date: 2026-08-24
* @Description: The purpose of this Controller supporting the CCFL Violation Assessment LWC. Retrieves
*                top-level (non-child) Regulatory Code Violation records for a given Inspection, for
*                display in a category-grouped violation list.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
                21 Aug -  PHOCS-4817        -  Accenture   -  supporting the CCFL Violation Assessment LWC
                24 Aug -  PHOCS-4817        -  Deepak      -  removed parentAssessmentDefId param, filter
                                                               on IsChildViolation__c = false, trimmed
                                                               SELECT to required fields only
***********************************************************************************************/
public with sharing class PHOCSCCFLViolationAssessmentController {

/**
* @author        Deepak
* @date          2026-08-24
* @description   Retrieves top-level (non-child) Regulatory Code Violations for the
*                 given Inspection, for display in a category-grouped violation list.
* @param inspectionId Id of the Inspection record to filter violations by. Required.
* @return        List<ViolationWrapper> wrapped violation data for LWC consumption.
*/
    @AuraEnabled(cacheable=true)
    public static List<ViolationWrapper> getViolations(Id inspectionId) {
        try {
            if (inspectionId == null) {
                throw new AuraHandledException('Inspection Id is required.');
            }
            
            List<RegulatoryCodeViolation> violations = [SELECT Id, RegulatoryCode.Name, RegulatoryCode.Description, Name,
                                                        InspectionAssmntInd.AssessmentIndDefinition.Name, InspectionAssmntInd.AssessmentTask.Name
                                                        FROM RegulatoryCodeViolation WHERE InspectionId = :inspectionId AND Status = 'Open'
                                                        AND IsChildViolation__c = false ORDER BY InspectionAssmntInd.AssessmentTask.Name];
            
            List<ViolationWrapper> results = new List<ViolationWrapper>();
            for (RegulatoryCodeViolation violation : violations) {
                results.add(new ViolationWrapper(violation));
            }
            return results;
        } catch (Exception ex) {
            throwError(ex.getMessage());
            return new List<ViolationWrapper>();
        }
    }

/**
* @author        Deepak
* @date          2026-08-24
* @description   Throws an AuraHandledException with a client-visible message.
* @param message Error message to surface to the calling LWC.
*/
    private static void throwError(String message) {
        AuraHandledException ex = new AuraHandledException(message);
        ex.setMessage(message);
        throw ex;
    }

/**
* @description Lightweight wrapper exposing violation data to the LWC layer.
*/
    public class ViolationWrapper {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String violationName;
        @AuraEnabled
        public String category;
        @AuraEnabled
        public String regulatoryCode;
        @AuraEnabled
        public String regulatoryCodeDescription;
        @AuraEnabled
        public String inspectionQuestion;

        public ViolationWrapper(RegulatoryCodeViolation violation) {
            id = violation.Id;
            violationName = violation.Name;
            category = violation.InspectionAssmntInd?.AssessmentTask?.Name;
            regulatoryCode = violation.RegulatoryCode?.Name;
            regulatoryCodeDescription = violation.RegulatoryCode?.Description;
            inspectionQuestion = violation.InspectionAssmntInd?.AssessmentIndDefinition?.Name;
        }
    }
}