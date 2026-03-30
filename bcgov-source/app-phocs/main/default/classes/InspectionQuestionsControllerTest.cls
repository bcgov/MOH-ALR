@isTest
public class InspectionQuestionsControllerTest {

    @testSetup
    static void setupData(){
        
        RegulatoryAuthorizationType ratype = new RegulatoryAuthorizationType(
        	Name = 'test regulatory',
            RegulatoryAuthCategory = 'License'
        
        );
        insert ratype;
        
        Account acc = new Account(
        	Name = 'test account',
            LicenseType__c = ratype.Id
            );
        	insert acc;
        
        ContactPointAddress cpa = new ContactPointAddress(
        Name = 'Test Address',
        Street = '123 Test Lane',
        City = 'Alberta',
        State = 'AL',
        Country = 'Canada',
        PostalCode = '500001'
    );
    insert cpa;
        

        DateTime visitDateTime = DateTime.newInstance(2025, 2, 10, 14, 30, 0);
        Visit vi = new Visit(
        AccountId = acc.Id,
        PlaceId = cpa.Id,
        PlannedVisitStartTime = visitDateTime
        
        );
        insert vi;
        
        AssessmentTaskDefinition astaskdef = new AssessmentTaskDefinition(
        	Name = 'task def',
            Category__c = 'Registration',
            TaskType = 'InspectionChecklist'
        );
        insert astaskdef;
        
        AssessmentTask asstask = new AssessmentTask(
        	Name = 'task',
            TaskType = 'InspectionChecklist',
            ParentId = vi.Id,
            AssessmentTaskDefinitionId = astaskdef.Id
        );
        insert asstask;
        
        
        
       AssessmentIndicatorDefinition assinddef = new AssessmentIndicatorDefinition(
        	Name = 'test',
            Category__c = 'test Category'
        );
        insert assinddef;
        
        AssessmentTaskIndDefinition taskIndDef = new AssessmentTaskIndDefinition(
            AssessmentTaskDefinitionId = astaskdef.Id,
            AssessmentIndDefinitionId = assinddef.Id,
            DisplayOrder = 1
        );
        insert taskIndDef;
        
        RegulatoryAuthority regaut = new RegulatoryAuthority(
        	Name = 'test reg authority'
        );
        insert regaut;
        
        RegulatoryCode regcode = new RegulatoryCode(
        	Name = 'new code',
            Subject ='test subject',
            EffectiveFrom = visitDateTime,
            RegulatoryAuthorityId = regaut.Id
        );
        insert regcode;
        
        RegulatoryCodeAssessmentInd recdassind = new RegulatoryCodeAssessmentInd(
        	AssessmentIndDefinitionId = assinddef.Id,
            RegulatoryCodeId = regcode.Id  
        );
    	insert recdassind;
    }
    
    @isTest
    static void getinsassind(){
         Visit visit = [SELECT Id FROM Visit LIMIT 1];
          List<InspectionQuestionsController.TaskGroupWrapper> result;
        Test.startTest();
    	result = InspectionQuestionsController.getInspectionQuestions(visit.Id);
    	Test.stopTest();
    	System.assertEquals(1, result.size(), 'The result should contain exactly one task group.');

        InspectionQuestionsController.TaskGroupWrapper taskGroup = result[0];
        System.assertNotEquals(null, taskGroup, 'Task group should not be null.');
    	System.assertEquals(1, taskGroup.parentQuestions.size(), 'There should be exactly one parent question.');

        InspectionQuestionsController.QuestionWrapper question = taskGroup.parentQuestions[0];
        System.assertNotEquals(null, question, 'Parent question should not be null.');
        System.assertEquals('test', question.questionText, 'The question text does not match.');
    
    }
    @isTest
     static void testGetRegulatoryCodesByInd() {
        AssessmentIndicatorDefinition assIndDef = [SELECT Id FROM AssessmentIndicatorDefinition WHERE Name = 'test' LIMIT 1];
        
        List<InspectionQuestionsController.RegulatoryCodeWrapper> result;
        Test.startTest();
        result = InspectionQuestionsController.getRegulatoryCodesByIndicator(assIndDef.Id);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should find one regulatory code.');
        InspectionQuestionsController.RegulatoryCodeWrapper wrapper = result[0];
        System.assertEquals('test subject', wrapper.regulatoryCodeName, 'The regulatory code name does not match.');
    }
    @isTest
	 static void testCreateAssessments_Text() {

    AssessmentTask asstask = [SELECT Id FROM AssessmentTask LIMIT 1];
    AssessmentIndicatorDefinition assinddef = [SELECT Id FROM AssessmentIndicatorDefinition LIMIT 1];
    List<InspectionQuestionsController.AssessmentResponseWrapper> responses = new List<InspectionQuestionsController.AssessmentResponseWrapper>();

    InspectionQuestionsController.AssessmentResponseWrapper wrap =new InspectionQuestionsController.AssessmentResponseWrapper();

    		wrap.assessmentTaskId = asstask.Id;
    		wrap.assessmentIndicatorDefinitionId = assinddef.Id;
    		wrap.assessmentResult = 'Compliant';
    		wrap.inspectionComments = 'Test Text';
    		wrap.questionDataType = 'TEXT';
			responses.add(wrap);

    Test.startTest();
    InspectionQuestionsController.createInspectionAssessments(responses);
    Test.stopTest();

    List<InspectionAssessmentInd> recs = [SELECT Id FROM InspectionAssessmentInd];
    System.assertEquals(0, recs.size(), 'No records inserted');
}


    @isTest
	 static void testCreateAssessments_Boolean() {

    AssessmentTask asstask = [SELECT Id FROM AssessmentTask LIMIT 1];
    AssessmentIndicatorDefinition assinddef = [SELECT Id FROM AssessmentIndicatorDefinition LIMIT 1];

    List<InspectionQuestionsController.AssessmentResponseWrapper> responses = new List<InspectionQuestionsController.AssessmentResponseWrapper>();
    InspectionQuestionsController.AssessmentResponseWrapper wrap =new InspectionQuestionsController.AssessmentResponseWrapper();

    		wrap.assessmentTaskId = asstask.Id;
    		wrap.assessmentIndicatorDefinitionId = assinddef.Id;
    		wrap.assessmentResult = 'true';
    		wrap.inspectionComments = '';
    		wrap.questionDataType = 'BOOLEAN';
    		responses.add(wrap);

    Test.startTest();
    InspectionQuestionsController.createInspectionAssessments(responses);
    Test.stopTest();

    List<InspectionAssessmentInd> recs = [
        SELECT Id FROM InspectionAssessmentInd];
    	System.assertEquals(0, recs.size(), 'No records inserted');
}

}