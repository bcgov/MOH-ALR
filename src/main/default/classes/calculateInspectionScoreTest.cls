@isTest
public class calculateInspectionScoreTest {
    @isTest
    public static void testMergeUnits(){
        
        String LicenseName = 'Mental Health';
        
        List<RegulatoryAuthorizationType> regAT = [SELECT Id, Name FROM RegulatoryAuthorizationType WHERE Name = 'Mental Health' LIMIT 1];
        System.debug('regAT'+regAT);

        //insert Registrant Account
        Account registrant = new Account();
        registrant.Name = 'Test Registrant';
        registrant.RecordTypeId = '012JQ000001nTczYAE';
        insert registrant;
        
        //insert Residence Account
        Account residence = new Account();
        residence.Name = 'Test Account';
        residence.ParentId = registrant.Id;
        residence.LicenseType__c = '0ehAq0000001AyEIAU';
        insert residence;
        
        //insert Inspection
        Visit inspection = new Visit();
        inspection.AccountId = residence.Id;
        inspection.PlaceId = 'Test Place Location';
        inspection.ProjectedStartTime__c = System.today();
        insert inspection;

        //insert AssessmentTask
        AssessmentTask task = new AssessmentTask();
        task.Name = 'Test Task Name';
        task.TaskType = 'Inspection Checklist';
        task.Status = 'Not Started';
        insert task;
        
        //insert AssessmentIndicatorDefinition
        AssessmentIndicatorDefinition definition = new AssessmentIndicatorDefinition();
        definition.Name = 'Test Difinition Name';
        definition.Category__c = 'Hospitality Service';
        definition.DataType = 'Text';
        insert definition;
        
        //insert InspectionAssessmentInd
        InspectionAssessmentInd insassestind = new InspectionAssessmentInd();
        insassestind.AssessmentTaskId = task.Id;
        insert insassestind;
        
        //insert RegulatoryCodeViolation
        RegulatoryCodeViolation rcv = new RegulatoryCodeViolation();
        rcv.Scope__c = 'Widespread';
        rcv.Severity__c = 'Minimal Harm';
        rcv.InspectionId = inspection.Id;
        rcv.InspectionAssmntIndId = insassestind.Id;
        rcv.UserScore__c = 15;
        insert rcv;

        calculateInspectionScore calculation = new calculateInspectionScore();
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> inputMap1 = new Map<String, Object>();
        Test.startTest();
        Object result = calculation.call('getInspectionScores', inputMap);
        Object result1 = calculation.call('getInspectionScores', inputMap1);
        //Test.stopTest();
        
        //System.assertEquals(true, result, 'Expected result to be true');
        Test.stopTest();
    }
}