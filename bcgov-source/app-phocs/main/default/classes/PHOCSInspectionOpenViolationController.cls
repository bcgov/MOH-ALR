public with sharing class PHOCSInspectionOpenViolationController {
    
		@AuraEnabled(cacheable=true)
		public static List<Id> getParentQuestionsWithOpenViolations(
    		Id visitId,
    		List<Id> parentQuestionIds
			){
    		Set<Id> quewithopenvio = new Set<Id>();
                try{
    			if(visitId == null || parentQuestionIds == null || parentQuestionIds.isEmpty()){
        		return new List<Id>();
    			}
                    
                    
    			Visit insp = [SELECT Id,Name,AccountId FROM Visit WHERE Id = :visitId LIMIT 1];
                		 if(insp.accountId == null){
            				return new List<Id>();
        					}
                    Id accountId = insp.AccountId; 
                    		
                                       
                    Set<Id> validParentIds = new Set<Id>();
                    
                    for (AssessmentIndicatorDefinition def : [
                        SELECT Id, PHOCSParentId__c
                        FROM AssessmentIndicatorDefinition 
                        WHERE Id IN :parentQuestionIds
                    ]) {
                        if(def.PHOCSParentId__c == null){
                            validParentIds.add(def.Id);
                        }
                    }   		
                    
                    Set<Id> validIndicatorIds = new Set<Id>();
                    
                    Map<Id, Id> indicatorToDefinitionMap = new Map<Id, Id>();
                            for (InspectionAssessmentInd ind : [
                                SELECT Id, AssessmentIndDefinitionId
                                FROM InspectionAssessmentInd
                                WHERE AssessmentIndDefinitionId IN :validParentIds
                            ]) {
                                indicatorToDefinitionMap.put(ind.Id, ind.AssessmentIndDefinitionId);
                            }
                    
                List<RegulatoryCodeViolation> violations = [
                SELECT InspectionAssmntIndId
                FROM RegulatoryCodeViolation
                WHERE InspectionId IN (
                    SELECT Id FROM Visit WHERE AccountId = :accountId
                )
                AND Status = 'Open'
                AND InspectionAssmntIndId IN :indicatorToDefinitionMap.keySet()
            ];

            for(RegulatoryCodeViolation reg : violations){
                Id defId = indicatorToDefinitionMap.get(reg.InspectionAssmntIndId);
                if(defId != null){
                    quewithopenvio.add(defId);
                }
            }

        } 
                catch (Exception e) {
                     System.debug('Error' + e.getMessage());
            
        }

                            
                            return new List<Id>(quewithopenvio);
                        }
    
}