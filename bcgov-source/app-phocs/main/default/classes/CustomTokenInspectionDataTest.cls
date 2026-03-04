@isTest
public class CustomTokenInspectionDataTest {

    @testSetup
    static void setupData(){
		RegulatoryAuthorizationType licenseType = new RegulatoryAuthorizationType(
        	Name = 'test regulatory',
            RegulatoryAuthCategory = 'License'
        
        );
        insert licenseType;
        Account acc = new Account(
            Name = 'test account',
            Physical_Address__Street__s = '123 Test Lane',
            Physical_Address__City__s = 'Kelowna',
            Physical_Address__StateCode__s = 'BC',
            Physical_Address__PostalCode__s = 'V6X 5K8',
            Physical_Address__CountryCode__s ='CA',
            LicenseType__c = licenseType.Id
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
            PlannedVisitStartTime = visitDateTime,
            ActualVisitStartTime = visitDateTime,
            ActualVisitEndTime = visitDateTime.addHours(2),
            TimeSpentMinutes__c = '01:20',
             PlaceId = cpa.Id,
            StatusRemarks = 'Inspection Completed'
        );
        insert vi;

        AssessmentTaskDefinition taskDef = new AssessmentTaskDefinition(
            Name = 'task def',
            TaskType = 'InspectionChecklist'
        );
        insert taskDef;

        AssessmentTask asstask = new AssessmentTask(
            Name = 'task',
            TaskType = 'InspectionChecklist',
            ParentId = vi.Id,
            AssessmentTaskDefinitionId = taskDef.Id
        );
        insert asstask;

        // Parent definition
        AssessmentIndicatorDefinition parentDef = new AssessmentIndicatorDefinition(
            Name = 'Parent Question',
            Category__c = 'Sanitation',
            Criticality__c = 'Critical'
        );
        insert parentDef;

        // Child definition (for canned comment)
        AssessmentIndicatorDefinition childDef = new AssessmentIndicatorDefinition(
            Name = 'Canned Comment 1',
            PHOCSParentId__c = parentDef.Id,
            Category__c = 'test Category'
        );
        insert childDef;

        // Non-compliant (Critical)
        insert new InspectionAssessmentInd(
            AssessmentTaskId = asstask.Id,
            AssessmentIndDefinitionId = parentDef.Id,
            Result = 'PHOCSNonCompliant',
            PHOCSInspectionComments__c = 'Needs correction',
            CorrectiveActionDescription__c = 'Fix immediately',
            ComplianceDueDate__c = System.today().addDays(5)
        );

        // Compliant
        insert new InspectionAssessmentInd(
            AssessmentTaskId = asstask.Id,
            AssessmentIndDefinitionId = parentDef.Id,
            Result = 'Compliant'
        );

        // Not Assessed
        insert new InspectionAssessmentInd(
            AssessmentTaskId = asstask.Id,
            AssessmentIndDefinitionId = parentDef.Id,
            Result = 'N/S (Not Assessed)'
        );

        // Not Applicable
        insert new InspectionAssessmentInd(
            AssessmentTaskId = asstask.Id,
            AssessmentIndDefinitionId = parentDef.Id,
            Result = 'N/A (Not Applicable)'
        );

        // Canned comment record
        insert new InspectionAssessmentInd(
            AssessmentTaskId = asstask.Id,
            AssessmentIndDefinitionId = childDef.Id,
            PHOCSCheckboxResponse__c = true
        );
    }


    @isTest
    static void testGetTokenData(){

        Visit visit = [SELECT Id FROM Visit LIMIT 1];

        Map<String, Object> input = new Map<String, Object>{
            'contextId' => visit.Id
        };

        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => output,
            'options' => options
        };

        CustomTokenInspectionData service = new CustomTokenInspectionData();

        Test.startTest();
        Object result = service.call('getTokenData', args);
        Test.stopTest();

        System.assertEquals(true, result, 'Method should return true');
        System.assert(output.containsKey('tokenMap'), 'tokenMap should be present');
        System.assertEquals(false, output.get('hasMoreTokenData'));

        Map<String, Object> tokenMap = (Map<String, Object>) output.get('tokenMap');

        System.assertEquals('test account', tokenMap.get('dairyPlant'));
        System.assertNotEquals(null, tokenMap.get('criticalInfractions'));
        System.assertNotEquals(null, tokenMap.get('inCompliance'));
        System.assertNotEquals(null, tokenMap.get('notAssessed'));
        System.assertNotEquals(null, tokenMap.get('notApplicable'));
    }


    @isTest
    static void testUnsupportedMethod(){

        CustomTokenInspectionData service = new CustomTokenInspectionData();

        Boolean exceptionThrown = false;

        try {
            service.invokeMethod(
                'invalidMethod',
                new Map<String, Object>(),
                new Map<String, Object>(),
                new Map<String, Object>()
            );
        } catch (Exception e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Unsupported method'));
        }

        System.assertEquals(true, exceptionThrown,
            'Exception should be thrown for unsupported method');
    }
}