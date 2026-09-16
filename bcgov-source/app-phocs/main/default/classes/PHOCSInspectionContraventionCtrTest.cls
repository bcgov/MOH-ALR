@isTest
private class PHOCSInspectionContraventionCtrTest {
    @TestSetup
    Static void setupTestData(){
        
        Id caseRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PHOCSComplaint').getRecordTypeId(); 
        
        Account acc = new Account(
            Name = 'Test Facility',
            RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('DrinkingWaterSystem').getRecordTypeId(),
            Type = 'Drinking Water',
            CategoryL1__c = 'Community Water System',
            CategoryL2__c = 'Local Gov System',
            CategoryL3__c = 'Municipality',
            NoofConnections__c = '15-300 (WS2)',
            TotalMaximumCapacity__c = 12,
            HealthAuthority__c = 'Vancouver Coastal Health - VCH',
            Phone = '1234567890'     
        );
        
        Case complaintcase = new Case(
            AccountId = acc.Id,
            RecordTypeId = caseRtId,
            Status = 'Open',
            Origin = 'Web',
            Type = 'Recreational Water',
            //TypeOfAdvisory__c = 'Beach Closure',
            ReasonForAdvisory__c = 'Chemical & physical parameters in excess'
        );
        insert complaintcase;
        
        InspectionType insptype = new InspectionType(
        Name = 'Complaint'
        );
        insert insptype;
            
        
        
        Schema.Location locationRec = new Schema.Location(ParentAccount__c=acc.Id, Name='Location Test', SiteTreatment__c='Raw');
        insert locationRec;
        
        Visit inspectionRec = new Visit(AccountId=acc.Id, PlaceId=locationRec.Id, InspectionMethod__c='Scheduled on Site Inspection', PlannedVisitStartTime=System.now());
        insert inspectionRec;
        
        Visit compinspectionRec = new Visit(AccountId=acc.Id, PlaceId=locationRec.Id, InspectionMethod__c='Scheduled on Site Inspection', PlannedVisitStartTime=System.now(), Status = 'Completed', IsRetracted__c = false, VisitTypeId = insptype.Id, contextId = complaintcase.Id);
        insert compinspectionRec;
        
        /*List<AssessmentIndicatorDefinition> indicators = new List<AssessmentIndicatorDefinition>{
            new AssessmentIndicatorDefinition(
                Name = 'Question 1',
                DataType = 'String',
                Category__c = 'test Category',
                Criticality__c = 'Critical'
            ),
            new AssessmentIndicatorDefinition(
                Name = 'Question 2',
                DataType = 'Boolean',
                Category__c = 'test Category',
                Criticality__c = 'Critical'
            )
        };
        insert indicators;*/
        
        AssessmentIndicatorDefinition indicators = new AssessmentIndicatorDefinition(
        		Name = 'Question 1',
                DataType = 'Boolean',
                Category__c = 'test Category',
                Criticality__c = 'Critical'
        );
            insert indicators;
        
        AssessmentIndicatorDefinition childquestion = new AssessmentIndicatorDefinition(
        		Name = 'Question 3',
                DataType = 'Boolean',
                Category__c = 'test Category',
                Criticality__c = 'Critical',
            	PHOCSParentId__c = indicators.Id
        );
            insert childquestion;
        
        
        AssessmentTaskDefinition testTaskDef = new AssessmentTaskDefinition(
            Name = 'Test Category',
            TaskType = 'InspectionChecklist'
        );
        insert testTaskDef;
        
         // Create Assessment Task
        AssessmentTask testTask = new AssessmentTask(
            Name = 'Test Task',
            TaskType = 'SignatureTask',
            ParentId = compinspectionRec.Id,
            AssessmentTaskDefinitionId = testTaskDef.Id
        );
        insert testTask;
        
        Id rectId = Schema.SObjectType.InspectionAssessmentInd.getRecordTypeInfosByDeveloperName()
    			.get('PHOCSInspectionAssessmentInd')
    			.getRecordTypeId();
        
        InspectionAssessmentInd inspaind = new InspectionAssessmentInd(
            	AssessmentIndDefinitionId = indicators.Id,
                AssessmentTaskId = testTask.Id,
                RecordTypeId = rectId
            );
        
        insert inspaind;
        
        InspectionAssessmentInd childinspaind = new InspectionAssessmentInd(
            	AssessmentIndDefinitionId = childquestion.Id,
                AssessmentTaskId = testTask.Id,
                RecordTypeId = rectId
            );
        
        insert childinspaind;
        
        Datetime specificDateTime = DateTime.newInstance(2025, 12, 25, 10, 30, 0);
        
        RegulatoryAuthority authority =
            new RegulatoryAuthority(
                Name = 'Test Regulatory Authority'
            );

        insert authority;
        
        RegulatoryCode regulatoryCode =
            new RegulatoryCode(
                Name = 'TEST-001',
                RegulatoryAuthorityId = authority.Id,
                Subject = 'test',
                EffectiveFrom = specificDateTime
            );

        insert regulatoryCode;
        
        
         RegulatoryCodeViolation violation = new RegulatoryCodeViolation(
        	InspectionId = compinspectionRec.Id,
            InspectionAssmntIndId = inspaind.Id,
            ComplianceDueDate = specificDateTime,
            DateCreated = specificDateTime,
            RegulatoryCodeId = regulatoryCode.Id,
            Corrected_During_Inspection__c = false
        );
        insert violation;
        
        RegulatoryCodeViolation childviolation = new RegulatoryCodeViolation(
        	InspectionId = compinspectionRec.Id,
            InspectionAssmntIndId = childinspaind.Id,
            ComplianceDueDate = specificDateTime,
            DateCreated = specificDateTime,
            RegulatoryCodeId = regulatoryCode.Id
        
        );
        insert childviolation;
            
    }
    
    @IsTest
    static void testGetRegulatoryViolations() {

        Case testCase = [
            SELECT Id
            FROM Case
            WHERE Status = 'Open'
            LIMIT 1
        ];
        

        Test.startTest();

        List<PHOCSInspectionContraventionController.ViolationWrapper>
            results =
            PHOCSInspectionContraventionController.getRegulatoryViolations(testCase.Id);

        Test.stopTest();


        // --------------------------------------------------------
        // Assertions
        // --------------------------------------------------------

                System.assertNotEquals(
            null,
            results,
            'Results should not be null'
        );
        
        System.assertEquals(
            1,
            results.size(),
            'Only the parent violation should create a wrapper'
        );
        
        
        PHOCSInspectionContraventionController.ViolationWrapper wrapper =
            results[0];
        
        
        // Parent question
        System.assertEquals(
            'Question 1',
            wrapper.PHOCSAssessmentIndicatorDefinition,
            'Parent question should be Question 1'
        );
        
        
        // Child questions list
        System.assertNotEquals(
            null,
            wrapper.childQuestions,
            'Child question list should not be null'
        );
        
        System.assertEquals(
            1,
            wrapper.childQuestions.size(),
            'Parent should have one child question'
        );
        
        
        // Child question
        System.assertEquals(
            'Question 3',
            wrapper.childQuestions[0],
            'Child question should be Question 3'
        );
        
        
        // Regulatory Code
        System.assertEquals(
            'TEST-001',
            wrapper.RegCode,
            'Regulatory Code should be TEST-001'
        );
        
        
        // Regulatory Authority
        System.assertEquals(
            'Test Regulatory Authority',
            wrapper.RegAuthority,
            'Regulatory Authority should be Test Regulatory Authority'
        );
    }


    @IsTest
    static void testGetRegulatoryViolationsWithNullCaseId() {

        Test.startTest();

        List<PHOCSInspectionContraventionController.ViolationWrapper>
            results =
            PHOCSInspectionContraventionController.getRegulatoryViolations(null);

        Test.stopTest();


        System.assertEquals(
            0,
            results.size(),
            'Null Case Id should return an empty list'
        );
    }


    @IsTest
    static void testNoQualifyingVisit() {

        Case testCase = new Case(
            Subject = 'No Visit Case'
        );

        insert testCase;


        Test.startTest();

        List<PHOCSInspectionContraventionController.ViolationWrapper>
            results =
            PHOCSInspectionContraventionController.getRegulatoryViolations(testCase.Id);

        Test.stopTest();


        System.assertEquals(
            0,
            results.size(),
            'No qualifying Visit should return an empty list'
        );
    }

    
}