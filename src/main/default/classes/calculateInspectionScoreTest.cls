@isTest
public class calculateInspectionScoreTest {
    @isTest
    public static void testMergeUnits(){
		
        Id tempId = '0Z5Aq00000019qrKAA';
        //RegulatoryAuthorizationType
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Helath', 'License', 'MH', 1, 2, 3, 4, true);
	
        Account residenceRec1 = TestDataFactory.createResidence('Residence', 'residenceAccount1', regAuth.Id, true);
        
        //insert AssessmentTask
        AssessmentTask task = new AssessmentTask();
        task.Name = 'Test Task Name';
        task.TaskType = 'Other';
        task.Status = 'Completed';
        insert task;
        
        //insert AssessmentIndicatorDefinition
        AssessmentIndicatorDefinition definition = new AssessmentIndicatorDefinition();
        definition.Name = 'Inspection & Follow-up Operational History Score';
        definition.Category__c = 'Operation History Assessment';
        definition.Description = 'maintains compliance & with terms/conditions';
        definition.DataType = 'Picklist';
        insert definition;
        
        //insert InspectionAssessmentInd
        InspectionAssessmentInd insassestind = new InspectionAssessmentInd();
        insassestind.AssessmentTaskId = task.Id;
        insassestind.AssessmentIndDefinitionId = definition.Id;
        insassestind.Result = 'Compliant';
        insert insassestind;
        
        //insert RegulatoryCodeViolation
        RegulatoryCodeViolation rcv = new RegulatoryCodeViolation();
        rcv.Scope__c = 'Widespread';
        rcv.Severity__c = 'Minimal Harm';
        rcv.DateCreated = System.today();
        rcv.InspectionAssmntIndId = insassestind.Id;
        rcv.UserScore__c = 15;
        rcv.InspectionId = tempId;
        insert rcv;
        
        RegulatoryCodeViolation rcv1 = new RegulatoryCodeViolation();
        rcv1.Scope__c = 'Widespread';
        rcv1.Severity__c = 'Minimal Harm';
        rcv1.DateCreated = System.today();
        rcv1.InspectionAssmntIndId = insassestind.Id;
        rcv1.UserScore__c = 15;
        rcv1.InspectionId = tempId;
        insert rcv1;
        
        List<RegulatoryCodeViolation> rcvList = new List<RegulatoryCodeViolation>();
        rcvList.add(rcv);
        rcvList.add(rcv1);
        
        List<InspectionAssessmentInd> insassessList = new List<InspectionAssessmentInd>();
        

        calculateInspectionScore calculation = new calculateInspectionScore();
        Map<String, Object> inputMap = new Map<String, Object>{'input' => rcvList};
        Map<String, Object> inputMap1 = new Map<String, Object>();
        Test.startTest();
        Object result = calculation.call('getInspectionScores', inputMap);
        Object result1 = calculation.call('getInspectionScores', inputMap1);
        
        System.assertEquals(false, result, 'Expected result to be true');
        Test.stopTest();
    }
    @isTest static void getAccounts_Method(){

        Test.startTest();

        List<RegulatoryCodeViolation> result1 = calculateInspectionScore.getRecords('Account');

        System.assertEquals(true,result1!=null);

        List<RegulatoryCodeViolation> result2 = calculateInspectionScore.getRecords(null);

        System.assertEquals(false,result2==null);

        Test.stopTest();

        

    }
}