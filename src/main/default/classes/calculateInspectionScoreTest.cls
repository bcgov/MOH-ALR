@isTest
public class calculateInspectionScoreTest {
    @isTest
    public static void testMergeUnits(){
		
        String tempId = '0Z5Aq00000019qrKAA';
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
        /*AssessmentIndicatorDefinition definition = new AssessmentIndicatorDefinition();
        definition.Name = 'Test Difinition Name';
        definition.Category__c = 'Hospitality Service';
        definition.DataType = 'Picklist';
        insert definition;*/
        
        //insert InspectionAssessmentInd
        /*InspectionAssessmentInd insassestind = new InspectionAssessmentInd();
        insassestind.AssessmentTaskId = task.Id;
        insert insassestind;*/
        
        //insert RegulatoryCodeViolation
        RegulatoryCodeViolation rcv = new RegulatoryCodeViolation();
        rcv.Scope__c = 'Widespread';
        rcv.Severity__c = 'Minimal Harm';
        rcv.DateCreated = System.today();
        //rcv.InspectionAssmntIndId = insassestind.Id;
        rcv.UserScore__c = 15;
        rcv.InspectionId = tempId;
        insert rcv;
        
        List<RegulatoryCodeViolation> rcvList = new List<RegulatoryCodeViolation>();
        rcvList.add(rcv);

        calculateInspectionScore calculation = new calculateInspectionScore();
        Map<String, Object> inputMap = new Map<String, Object>{'Inspection' => rcv};
        Map<String, Object> inputMap1 = new Map<String, Object>();
        Test.startTest();
        Object result = calculation.call('getInspectionScores', inputMap);
        Object result1 = calculation.call('getInspectionScores', inputMap1);
        
        System.assertEquals(false, result, 'Expected result to be true');
        Test.stopTest();
    }
}