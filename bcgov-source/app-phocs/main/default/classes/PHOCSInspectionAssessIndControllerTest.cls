@isTest
public class PHOCSInspectionAssessIndControllerTest {
		
    @testSetUp
    static void setupData(){
        AssessmentIndicatorDefinition assinddef = new AssessmentIndicatorDefinition(
        	Name = 'test',
            Category__c = 'test Category'
        );
        insert assinddef;
    
    	AssessmentTask asstask = new AssessmentTask(
        	Name = 'task',
            TaskType = 'SignatureTask'
        );
        insert asstask;
        
        InspectionAssessmentInd insassind = new InspectionAssessmentInd(
        	AssessmentIndDefinitionId = assinddef.Id,
            AssessmentTaskId = asstask.Id,
            PHOCSInspectionComments__c = 'test comment',
            Result = 'Compliant'
        );
        insert insassind;
    
    }

	@isTest
    static void insassindinsert(){
        AssessmentIndicatorDefinition assinddef = [SELECT ID FROM AssessmentIndicatorDefinition LIMIT 1];
        AssessmentTask asstask = [SELECT ID FROM AssessmentTask LIMIT 1];
        delete [SELECT ID FROM InspectionAssessmentInd];
        
        Test.startTest();
        PHOCSInspectionAssessmentIndController.getcmtresult(asstask.Id,assinddef.Id,'test comment','Non-compliant');
        Test.stopTest();
        
        InspectionAssessmentInd newrec = [SELECT PHOCSInspectionComments__c,
                                          Result
                                          FROM InspectionAssessmentInd 
                                          WHERE AssessmentTaskId =:asstask.Id 
                                          AND AssessmentIndDefinitionId =:assinddef.Id 
                                          LIMIT 1];
        System.assertEquals('test comment',newrec.PHOCSInspectionComments__c);
        System.assertEquals('Non-compliant',newrec.Result);
        
    }

	@isTest
    static void insassindupdate(){
     	AssessmentIndicatorDefinition assinddef = [SELECT ID FROM AssessmentIndicatorDefinition LIMIT 1];
        AssessmentTask asstask = [SELECT ID FROM AssessmentTask LIMIT 1];
        
        Test.startTest();
        PHOCSInspectionAssessmentIndController.getcmtresult(asstask.Id,assinddef.Id,'update comment','N/A (Not Applicable)');
        Test.stopTest();
        
		InspectionAssessmentInd updaterec = [SELECT PHOCSInspectionComments__c,
                                          Result
                                          FROM InspectionAssessmentInd 
                                          WHERE AssessmentTaskId =:asstask.Id 
                                          AND AssessmentIndDefinitionId =:assinddef.Id 
                                          LIMIT 1];        
        
        System.assertEquals('update comment',updaterec.PHOCSInspectionComments__c);
        System.assertEquals('N/A (Not Applicable)',updaterec.Result);
        
    }
    
    @isTest
    static void checkexistingcomment(){
        AssessmentIndicatorDefinition assinddef = [SELECT ID FROM AssessmentIndicatorDefinition LIMIT 1];
        
        Test.startTest();
        Map<String,String> result = PHOCSInspectionAssessmentIndController.getExistingComments(new List<Id>{assinddef.Id});
        Test.stopTest();
        
        System.assert(result.containsKey(assinddef.Id), 'Assessment Indicator Definition should exists');
        System.assertEquals('test comment',result.get(assinddef.Id));
        
        
    }

}