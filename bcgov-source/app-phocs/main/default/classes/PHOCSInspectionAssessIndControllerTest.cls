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
            Result = 'Compliant',
            PHOCSCheckboxResponse__c = false
        );
        insert insassind;
    
    }

	@isTest
    static void insassindinsert(){
        AssessmentIndicatorDefinition assinddef = [SELECT ID FROM AssessmentIndicatorDefinition LIMIT 1];
        AssessmentTask asstask = [SELECT ID FROM AssessmentTask LIMIT 1];
        delete [SELECT ID FROM InspectionAssessmentInd];
        
        Test.startTest();
        PHOCSInspectionAssessmentIndController.getcmtresult(asstask.Id,assinddef.Id,'test comment','Non-compliant',true);
        Test.stopTest();
        
        InspectionAssessmentInd newrec = [SELECT PHOCSInspectionComments__c,
                                          PHOCSCheckboxResponse__c,
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
        PHOCSInspectionAssessmentIndController.getcmtresult(asstask.Id,assinddef.Id,'update comment','N/A (Not Applicable)',false);
        Test.stopTest();
        
		InspectionAssessmentInd updaterec = [SELECT PHOCSInspectionComments__c,
                                          PHOCSCheckboxResponse__c,
                                          Result
                                          FROM InspectionAssessmentInd 
                                          WHERE AssessmentTaskId =:asstask.Id 
                                          AND AssessmentIndDefinitionId =:assinddef.Id 
                                          LIMIT 1];        
        
        System.assertEquals('update comment',updaterec.PHOCSInspectionComments__c);
        System.assertEquals('N/A (Not Applicable)',updaterec.Result);
        
    }
    
    @isTest
	static void test_getExistingCommentsByDefAndTask() {

    AssessmentIndicatorDefinition def = [SELECT Id FROM AssessmentIndicatorDefinition LIMIT 1];
    AssessmentTask task = [SELECT Id FROM AssessmentTask LIMIT 1];
    InspectionAssessmentInd ind = [
        SELECT PHOCSInspectionComments__c,PHOCSCheckboxResponse__c
        FROM InspectionAssessmentInd
        WHERE AssessmentIndDefinitionId = :def.Id
        AND AssessmentTaskId = :task.Id
        LIMIT 1
    ];

    Test.startTest();
    Map<String, Object> result =
        PHOCSInspectionAssessmentIndController.getExistingCommentsByDefAndTask(
            new List<Id>{ def.Id },
            new List<Id>{ task.Id }
        );
    Test.stopTest();
    String key = def.Id + '|' + task.Id;

    // Assertions
    System.assert(result.containsKey(key), 'Returned map must contain the correct key');
     @SuppressWarnings('unchecked')
    Map<String, Object> saved = (Map<String, Object>) result.get(key);
    System.assertEquals('test comment',String.valueOf(saved.get('comment')),  'Comment value should match the inserted record');
	System.assertEquals(false, Boolean.valueOf(String.valueOf(saved.get('checkbox'))), 'Checkbox value should match the inserted record');
    Map<String, Object> emptyResult =
        PHOCSInspectionAssessmentIndController.getExistingCommentsByDefAndTask(
            new List<Id>(),
            new List<Id>()
        );

    System.assertEquals(0, emptyResult.size(), 'Empty input should return an empty map');
}

}