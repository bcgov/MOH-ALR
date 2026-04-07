public class PHOCSInspectionAssessmentIndBatch implements Database.Batchable<SObject>{
		
    private Set<Id> visitIds;
    
    public PHOCSInspectionAssessmentIndBatch(Set<Id> visitIds){
        this.visitIds = visitIds;
    }
    public static void delInsInd(Set<Id> visitIds){
        Database.executeBatch(
        new PHOCSInspectionAssessmentIndBatch(visitIds),
            200
        );
    }	
	
    public Database.QueryLocator start(Database.BatchableContext bc){
        
        return Database.getQueryLocator([SELECT ID FROM InspectionAssessmentInd
                                     			WHERE AssessmentIndDefinition.PHOCSParentId__c != null
                                     			AND (PHOCSCheckboxResponse__c = false OR PHOCSCheckboxResponse__c = null)
                                     			AND AssessmentTask.ParentId IN :visitIds
                                     			AND AssessmentTask.Parent.Status = 'Completed'
                                      			AND RecordType.DeveloperName = 'PHOCSInspectionAssessmentInd'
                                     ]);
        
        
    }
    
    public void execute(Database.BatchableContext bc, List<InspectionAssessmentInd> recfound){
        if(!recfound.isEmpty()){
            delete recfound;
        }
        
    }
    
    public void finish(Database.BatchableContext bc){
        System.debug('Deleted InspectionAssessmentInd canned comment records where PHOCSCheckboxResponse__c is false');
    }
}