/**********************************************************************************************
* @Author:      Accenture 
* @Date:        11 Dec 2025
* @Description: The purpose of this class is to create methods which can be used by different trigger events.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
                11 Dec -  PHOCS-2693        -  Accenture   -  Create Violations for PHOCS InspectionAssessmentInd records.
***********************************************************************************************/
public without sharing class InspAssessmentIndTriggerHandler {
    public static Id recordTypePHOCSInspectionAssessmentInd = Schema.SObjectType.InspectionAssessmentInd.getRecordTypeInfosByDeveloperName().get('PHOCSInspectionAssessmentInd').getRecordTypeId();
    public static Id recordTypePHOCSRegulatoryCodeViolation = Schema.SObjectType.RegulatoryCodeViolation.getRecordTypeInfosByDeveloperName().get('PHOCSRegulatoryCodeViolation').getRecordTypeId();
    public static String CLASS_NAME = 'InspAssessmentIndTriggerHandler';
    public static final String RESULT_NON_COMPLIANT = 'PHOCSNonCompliant';
    
/**
* @author: Deepak
* @date: 11 Dec 2025
* @description: The purpose of this method is to all after insert submethods.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/      
    public static void afterInsert(List<InspectionAssessmentInd> newList) {
        //createRegulatoryCodeViolations(newList);
    }
    
/**
* @author: Deepak
* @date: 11 Dec 2025
* @description: The purpose of this method is to Create Violations for PHOCS InspectionAssessmentInd records.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
   /* public static void createRegulatoryCodeViolations(List<InspectionAssessmentInd> newList) {
        try {
            List<InspectionAssessmentInd> filteredInsAsmntIndList = new List<InspectionAssessmentInd>();
            Set<Id> assessmentIndDefIds = new Set<Id>();
            Set<Id> assessmentTaskIds = new Set<Id>();
            Map<Id, List<RegulatoryCodeAssessmentInd>> regMap = new Map<Id, List<RegulatoryCodeAssessmentInd>>();

            for (InspectionAssessmentInd ind : newList) {
                if(ind.RecordTypeId == recordTypePHOCSInspectionAssessmentInd && ind.Result == RESULT_NON_COMPLIANT && ind.AssessmentIndDefinitionId != null && ind.AssessmentTaskId != null){
                    filteredInsAsmntIndList.add(ind);
                    assessmentIndDefIds.add(ind.AssessmentIndDefinitionId);
                    assessmentTaskIds.add(ind.AssessmentTaskId);
                }
            }

            if (filteredInsAsmntIndList.isEmpty()){
                return;
            } 

            Map<Id, AssessmentTask> taskMap = new Map<Id, AssessmentTask>([SELECT Id, ParentId FROM AssessmentTask WHERE Id IN :assessmentTaskIds]);           
            
            List<RegulatoryCodeAssessmentInd> regCodeAsmntList = [SELECT Id, AssessmentIndDefinitionId, RegulatoryCodeId FROM RegulatoryCodeAssessmentInd WHERE AssessmentIndDefinitionId IN :assessmentIndDefIds];

            for (RegulatoryCodeAssessmentInd rca : regCodeAsmntList) {
                if (!regMap.containsKey(rca.AssessmentIndDefinitionId)) {
                    regMap.put(rca.AssessmentIndDefinitionId, new List<RegulatoryCodeAssessmentInd>());
                }
                regMap.get(rca.AssessmentIndDefinitionId).add(rca);
            }

            List<RegulatoryCodeViolation> violationsToInsert = new List<RegulatoryCodeViolation>();

            for (InspectionAssessmentInd ind : filteredInsAsmntIndList) {
                List<RegulatoryCodeAssessmentInd> mappings = regMap.get(ind.AssessmentIndDefinitionId);
                if (mappings == null){
                    continue;
                }
                Id inspectionId = taskMap.get(ind.AssessmentTaskId)?.ParentId;

                for (RegulatoryCodeAssessmentInd mapItem : mappings) {
                    RegulatoryCodeViolation vio = new RegulatoryCodeViolation();
                    vio.RecordTypeId = recordTypePHOCSRegulatoryCodeViolation;
                    vio.InspectionAssmntIndId = ind.Id;
                    vio.InspectionId = inspectionId;
                    vio.DateCreated = Date.today();
                    vio.RegulatoryCodeId = mapItem.RegulatoryCodeId;
                    vio.Status = 'Open';
                    violationsToInsert.add(vio);
                }
            }
            
            if (!violationsToInsert.isEmpty()) {
                Database.insert(violationsToInsert, true);
            }

        } catch (Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'afterInsert', '', ex);
        }
    } */
    
}