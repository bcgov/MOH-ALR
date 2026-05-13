public with sharing class PHOCSInspectionOpenViolationController {
    
    @AuraEnabled(cacheable=true)
    public static List<Id> getParentQuestionsWithOpenViolations(Id visitId, List<Id> parentQuestionIds){
        Set<Id> quewithopenvio = new Set<Id>();
        Set<Id> validParentIds = new Set<Id>();
        Map<Id, Id> indicatorToDefinitionMap = new Map<Id, Id>();
        Map<Id, String> categoryMap = new Map<Id, String>();
        List<RegulatoryCodeViolation> violations;
        
        try {
            if (visitId == null || parentQuestionIds == null || parentQuestionIds.isEmpty()){
                return new List<Id>();
            }
            Visit insp = [SELECT Id, Name, AccountId, ContextId, Account.Type FROM Visit WHERE Id = :visitId LIMIT 1];
            
            if (insp.AccountId == null) {
                return new List<Id>();
            }
            
            Id accountId = insp.AccountId;
            Id assetId = insp.ContextId;
            Boolean isRecreationalWater = insp.Account.Type == 'Recreational Water';            
            
            for(AssessmentIndicatorDefinition def : [SELECT Id, PHOCSParentId__c, Category__c FROM AssessmentIndicatorDefinition WHERE Id IN :parentQuestionIds]){
                
                if (def.PHOCSParentId__c == null) {
                    validParentIds.add(def.Id);
                    categoryMap.put(def.Id, def.Category__c);
                }
            }
            
            for (InspectionAssessmentInd ind : [SELECT Id, AssessmentIndDefinitionId, AssessmentIndDefinition.Category__c FROM InspectionAssessmentInd WHERE AssessmentIndDefinitionId IN :validParentIds]){
                String expectedCategory = categoryMap.get(ind.AssessmentIndDefinitionId);
                
                if(expectedCategory == ind.AssessmentIndDefinition.Category__c){
                    indicatorToDefinitionMap.put(ind.Id, ind.AssessmentIndDefinitionId);
                }
            }           
            
            if (isRecreationalWater && assetId != null) {
                violations = [SELECT InspectionAssmntIndId FROM RegulatoryCodeViolation WHERE Asset__c = :assetId AND Status = 'Open' AND InspectionAssmntIndId IN :indicatorToDefinitionMap.keySet()];
            }else {                
                violations = [SELECT InspectionAssmntIndId FROM RegulatoryCodeViolation WHERE InspectionId IN (SELECT Id FROM Visit WHERE AccountId = :accountId) 
                              AND Status = 'Open' AND InspectionAssmntIndId IN :indicatorToDefinitionMap.keySet()];
            }
            
            for(RegulatoryCodeViolation reg : violations){                
                Id defId = indicatorToDefinitionMap.get(reg.InspectionAssmntIndId);
                
                if(defId != null){
                    quewithopenvio.add(defId);
                }
            }
            
        }catch (Exception e) {
            System.debug('Error in getParentQuestionsWithOpenViolations: ' + e.getMessage());
        }
        
        return new List<Id>(quewithopenvio);
    }
}