@IsTest
public class ViolationTriggerHandlerTest {

    @testSetup
    static void setupData(){

        // Regulatory Authorization Type
        RegulatoryAuthorizationType ratype = new RegulatoryAuthorizationType(
            Name = 'test regulatory',
            RegulatoryAuthCategory = 'License'            
        );
        insert ratype;

        // Account
        Account acc = new Account(
            Name = 'test account',
            LicenseType__c = ratype.Id
        );
        insert acc;

        // Address
        ContactPointAddress cpa = new ContactPointAddress(
            Name = 'Test Address',
            Street = '123 Test Lane',
            City = 'Alberta',
            State = 'AL',
            Country = 'Canada',
            PostalCode = '500001'
        );
        insert cpa;        

        // Visit
        DateTime visitDateTime = DateTime.newInstance(2025, 2, 10, 14, 30, 0);
        Visit vi = new Visit(
            AccountId = acc.Id,
            PlaceId = cpa.Id,
            PlannedVisitStartTime = visitDateTime
        );
        insert vi;

        // Assessment Task Definition
        AssessmentTaskDefinition astaskdef = new AssessmentTaskDefinition(
            Name = 'task def',
            Category__c = 'Registration',
            TaskType = 'InspectionChecklist'
        );
        insert astaskdef;

        // Assessment Task
        AssessmentTask asstask = new AssessmentTask(
            Name = 'task',
            TaskType = 'InspectionChecklist',
            ParentId = vi.Id,
            AssessmentTaskDefinitionId = astaskdef.Id
        );
        insert asstask;

        // Assessment Indicator Definition
        AssessmentIndicatorDefinition assinddef = new AssessmentIndicatorDefinition(
            Name = 'test',
            Category__c = 'test Category'
        );
        insert assinddef;

        // Task ↔ Indicator Mapping
        AssessmentTaskIndDefinition taskIndDef = new AssessmentTaskIndDefinition(
            AssessmentTaskDefinitionId = astaskdef.Id,
            AssessmentIndDefinitionId = assinddef.Id,
            DisplayOrder = 1
        );
        insert taskIndDef;

        // Regulatory Authority
        RegulatoryAuthority regaut = new RegulatoryAuthority(
            Name = 'test reg authority'
        );
        insert regaut;

        // Regulatory Code
        RegulatoryCode regcode = new RegulatoryCode(
            Name = 'new code',
            Subject = 'test subject',
            EffectiveFrom = visitDateTime,
            RegulatoryAuthorityId = regaut.Id
        );
        insert regcode;

        // Regulatory Code ↔ Indicator Mapping
        RegulatoryCodeAssessmentInd recdassind = new RegulatoryCodeAssessmentInd(
            AssessmentIndDefinitionId = assinddef.Id,
            RegulatoryCodeId = regcode.Id  
        );
        insert recdassind;

        // Inspection Assessment Indicator
        InspectionAssessmentInd inspAsmt = new InspectionAssessmentInd(
            AssessmentTaskId = asstask.Id,
            AssessmentIndDefinitionId = assinddef.Id
        );
        insert inspAsmt;

        // 🔁 Re-query to ensure relationship fields are accessible
        inspAsmt = [
            SELECT Id,
                   AssessmentIndDefinitionId,
                   AssessmentIndDefinition.Name
            FROM InspectionAssessmentInd
            WHERE Id = :inspAsmt.Id
        ];

        // Parent Violation
        RegulatoryCodeViolation parentViolation = new RegulatoryCodeViolation(
            Status = 'Open',
            InspectionId = vi.Id,
            InspectionAssmntIndId = inspAsmt.Id,
            DateCreated = Date.today()
        );
        insert parentViolation;

        // Child Violations
        List<RegulatoryCodeViolation> childViolations = new List<RegulatoryCodeViolation>();
        for (Integer i = 0; i < 5; i++) {
            childViolations.add(new RegulatoryCodeViolation(
                Status = 'Open',
                InspectionId = vi.Id,
                InspectionAssmntIndId = inspAsmt.Id,
                PHOCSParentId__c = parentViolation.Id,
                DateCreated = Date.today()
            ));
        }
        insert childViolations;
    }

    @isTest
    static void testParentAndChildAutoResolution(){

        // Fetch Parent
        RegulatoryCodeViolation parent = [
            SELECT Id,
                   Status,
                   DateResolved,
                   InspectionAssmntIndId,
                   InspectionAssmntInd.AssessmentIndDefinitionId,
                   InspectionAssmntInd.AssessmentIndDefinition.Name
            FROM RegulatoryCodeViolation
            WHERE PHOCSParentId__c = null
            LIMIT 1
        ];

        // 🔎 Verify relationship is not null (your handler condition)
        System.assertNotEquals(
            null,
            parent.InspectionAssmntInd.AssessmentIndDefinitionId,
            'AssessmentIndDefinition must not be null for handler logic to execute.'
        );

        // Update Status to trigger handler
        parent.Status = 'Resolved';

        Test.startTest();
        update parent;
        Test.stopTest();

        // Re-query Parent
        RegulatoryCodeViolation updatedParent = [
            SELECT Id, Status, DateResolved
            FROM RegulatoryCodeViolation
            WHERE Id = :parent.Id
        ];

        System.assertEquals(
            'Resolved',
            updatedParent.Status,
            'Parent violation should be Resolved.'
        );

        System.assertNotEquals(
            null,
            updatedParent.DateResolved,
            'Parent DateResolved should be populated.'
        );

        // Fetch Child Violations
        List<RegulatoryCodeViolation> children = [
            SELECT Id, Status, DateResolved, PHOCSParentId__c
            FROM RegulatoryCodeViolation
            WHERE PHOCSParentId__c = :parent.Id
        ];

        System.assertEquals(
            5,
            children.size(),
            'Expected 5 child violations.'
        );

        for(RegulatoryCodeViolation child : children){
            System.assertEquals(
                'Resolved',
                child.Status,
                'Child violation should be auto-resolved.'
            );

            System.assertNotEquals(
                null,
                child.DateResolved,
                'Child DateResolved should be populated.'
            );
        }
    }
}