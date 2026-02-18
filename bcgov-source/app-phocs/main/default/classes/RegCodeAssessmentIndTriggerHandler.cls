/**********************************************************************************************
* @Author:      Accenture 
* @Date:        18 Feb 2026
* @Description: The purpose of this Trigger is to trigger on particular events
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                18 Feb -  PHOCS-3397         -  Accenture   -  Update RelatedRegulatoryCodes__c on InspectionAssessmentInd records.
***********************************************************************************************/
public with sharing class RegCodeAssessmentIndTriggerHandler{    
    public static final String CLASS_NAME = 'RegCodeAssessmentIndTriggerHandler';
    public static final Integer MAX_LENGTH = 255;
    
/**
* @author: Deepak
* @date: 18 Feb 2025
* @description: The purpose of this method is to Update RelatedRegulatoryCodes__c.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/      
    public static void updateRelatedRegulatoryCodes(List<RegulatoryCodeAssessmentInd> newList, List<RegulatoryCodeAssessmentInd> oldList){
        try {
            Set<Id> assessmentDefIds = new Set<Id>();
            Map<Id, List<String>> codeNamesByDef = new Map<Id, List<String>>();
            
            if (newList != null) {
                for (RegulatoryCodeAssessmentInd rec : newList) {
                    if (rec.AssessmentIndDefinitionId != null) {
                        assessmentDefIds.add(rec.AssessmentIndDefinitionId);
                    }
                }
            }
            
            if (oldList != null) {
                for (RegulatoryCodeAssessmentInd rec : oldList) {
                    if (rec.AssessmentIndDefinitionId != null) {
                        assessmentDefIds.add(rec.AssessmentIndDefinitionId);
                    }
                }
            }
            
            if (assessmentDefIds.isEmpty()) {
                return;
            }
            
            List<RegulatoryCodeAssessmentInd> allMappings = [SELECT AssessmentIndDefinitionId, RegulatoryCode.Name FROM RegulatoryCodeAssessmentInd 
                                                             WHERE AssessmentIndDefinitionId IN :assessmentDefIds];
            
            for (RegulatoryCodeAssessmentInd mapping : allMappings) {
                if (mapping.RegulatoryCode == null) continue;
                
                if (!codeNamesByDef.containsKey(mapping.AssessmentIndDefinitionId)) {
                    codeNamesByDef.put(mapping.AssessmentIndDefinitionId, new List<String>());
                }                
                codeNamesByDef.get(mapping.AssessmentIndDefinitionId).add(mapping.RegulatoryCode.Name);
            }
            
            List<AssessmentIndicatorDefinition> defsToUpdate = new List<AssessmentIndicatorDefinition>();
            
            for(Id defId : assessmentDefIds){
                List<String> names = codeNamesByDef.get(defId);
                String finalValue = '';
                
                if(names != null && !names.isEmpty()){
                    String joined = String.join(names, ', ');
                    
                    if (joined.length() > MAX_LENGTH) {
                        joined = joined.substring(0, MAX_LENGTH);
                    }
                    finalValue = joined;
                }                
                defsToUpdate.add(new AssessmentIndicatorDefinition(Id = defId, RelatedRegulatoryCodes__c = finalValue));
            }
            
            if (!defsToUpdate.isEmpty()) {
                update defsToUpdate;
            }
            
        } catch (Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'updateRelatedRegulatoryCodes', '', ex);
        }
    }
}