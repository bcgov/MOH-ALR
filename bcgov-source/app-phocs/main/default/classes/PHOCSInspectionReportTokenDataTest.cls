@isTest
public class PHOCSInspectionReportTokenDataTest {

    // Names deliberately do not run alphabetically in junction order - sorting by name was the
    // original defect, and these catch it coming back.
    private static final String Q_WATER = 'Zeta - water supply is potable';
    private static final String Q_SANITARY = 'Alpha - food is kept in a sanitary manner';
    private static final String Q_EQUIPMENT = 'Mike - equipment is clean and in good repair';
    private static final String Q_HYGIENE = 'Bravo - staff hygiene practices are adequate';
    private static final String Q_PESTS = 'Premises are free of pests';
    private static final String Q_OBSERVATION =
        'Food is stored in a manner that increases the risk of cross-contamination.';
    private static final String Q_CHECKLIST_PARENT = 'Education topics discussed';
    private static final String Q_CHECKLIST_ITEM = 'Second-hand smoke exposure';

    @testSetup
    static void setupData() {
        RegulatoryAuthorizationType licenseType = new RegulatoryAuthorizationType(
            Name = 'test regulatory',
            RegulatoryAuthCategory = 'License'
        );
        insert licenseType;

        Account acc = new Account(
            Name = 'Bills Wings and Things',
            Type = 'Food',
            HealthAuthority__c = 'Fraser Health - FH',
            Physical_Address__Street__s = '123 Spicy Wing Lane',
            Physical_Address__City__s = 'Vancouver',
            Physical_Address__StateCode__s = 'BC',
            Physical_Address__PostalCode__s = 'V6X 5K8',
            Physical_Address__CountryCode__s = 'CA',
            LicenseType__c = licenseType.Id
        );
        Account tobaccoAcc = new Account(
            Name = 'Corner Vape Shop',
            Type = 'Tobacco and Vapour',
            HealthAuthority__c = 'Fraser Health - FH',
            LicenseType__c = licenseType.Id
        );
        insert new List<Account>{ acc, tobaccoAcc };

        // A contact with no AccountId is a "private contact" - AccountContactRelation rejects it.
        Contact operator = new Contact(
            AccountId = acc.Id,
            LastName = 'Wingham',
            FirstName = 'Bill',
            Email = 'bill.wingham@example.com',
            Phone = '604-123-7890'
        );
        Contact owner = new Contact(
            AccountId = acc.Id,
            LastName = 'Davis',
            FirstName = 'Maise',
            Phone = '250-555-0101',
            MobilePhone = '250-555-0199'
        );
        insert new List<Contact>{ operator, owner };

        List<AccountContactRelation> existing = [
            SELECT Id, ContactId FROM AccountContactRelation WHERE AccountId = :acc.Id
        ];
        Map<Id, AccountContactRelation> byContact = new Map<Id, AccountContactRelation>();
        for (AccountContactRelation acr : existing) {
            byContact.put(acr.ContactId, acr);
        }

        List<AccountContactRelation> toUpsert = new List<AccountContactRelation>();
        toUpsert.add(relationFor(byContact, acc.Id, operator.Id, 'Operator', false));
        toUpsert.add(relationFor(byContact, acc.Id, owner.Id, 'Owner Contact', true));
        upsert toUpsert;

        ContactPointAddress cpa = new ContactPointAddress(
            Name = 'Test Address',
            Street = '123 Spicy Wing Lane',
            City = 'Vancouver',
            State = 'BC',
            Country = 'Canada',
            PostalCode = 'V6X 5K8'
        );
        insert cpa;

        DateTime visitDateTime = DateTime.newInstance(2026, 7, 1, 9, 0, 0);

        Visit vi = new Visit(
            AccountId = acc.Id,
            PlannedVisitStartTime = visitDateTime,
            ActualVisitStartTime = visitDateTime,
            ActualVisitEndTime = visitDateTime.addMinutes(30),
            TimeSpentMinutes__c = '00:30',
            PlaceId = cpa.Id,
            FollowUpInspectionRequired__c = true,
            SignatureRefusal__c = true,
            DeliveryMethod__c = 'Email',
            InstructionDescription = 'This is a routine food safety inspection.',
            StatusRemarks = 'Observed unwrapped food items in the walk-in cooler.'
        );
        Visit tobaccoVisit = new Visit(
            AccountId = tobaccoAcc.Id,
            PlannedVisitStartTime = visitDateTime,
            ActualVisitStartTime = visitDateTime,
            PlaceId = cpa.Id
        );
        insert new List<Visit>{ vi, tobaccoVisit };

        AssessmentTaskDefinition premisesTaskDef = new AssessmentTaskDefinition(
            Name = 'premises task def',
            TaskType = 'InspectionChecklist'
        );
        AssessmentTaskDefinition foodTaskDef = new AssessmentTaskDefinition(
            Name = 'food task def',
            TaskType = 'InspectionChecklist'
        );
        AssessmentTaskDefinition tobaccoTaskDef = new AssessmentTaskDefinition(
            Name = 'tobacco task def',
            TaskType = 'InspectionChecklist'
        );
        insert new List<AssessmentTaskDefinition>{ premisesTaskDef, foodTaskDef, tobaccoTaskDef };

        // SequenceNumber drives category order, deliberately reversed against insert order.
        AssessmentTask premisesTask = new AssessmentTask(
            Name = 'Premises and Equipment',
            TaskType = 'InspectionChecklist',
            ParentId = vi.Id,
            AssessmentTaskDefinitionId = premisesTaskDef.Id,
            SequenceNumber = 1
        );
        AssessmentTask foodTask = new AssessmentTask(
            Name = 'Food Sources and Protection',
            TaskType = 'InspectionChecklist',
            ParentId = vi.Id,
            AssessmentTaskDefinitionId = foodTaskDef.Id,
            SequenceNumber = 2
        );
        AssessmentTask tobaccoTask = new AssessmentTask(
            Name = 'Tobacco Education',
            TaskType = 'InspectionChecklist',
            ParentId = tobaccoVisit.Id,
            AssessmentTaskDefinitionId = tobaccoTaskDef.Id,
            SequenceNumber = 1
        );
        insert new List<AssessmentTask>{ premisesTask, foodTask, tobaccoTask };

        AssessmentIndicatorDefinition water = indicatorDef(Q_WATER, null, null);
        AssessmentIndicatorDefinition sanitary = indicatorDef(Q_SANITARY, null, null);
        AssessmentIndicatorDefinition equipment = indicatorDef(Q_EQUIPMENT, null, null);
        AssessmentIndicatorDefinition hygiene = indicatorDef(Q_HYGIENE, null, null);
        AssessmentIndicatorDefinition pests = indicatorDef(Q_PESTS, null, null);
        AssessmentIndicatorDefinition checklistParent = indicatorDef(Q_CHECKLIST_PARENT, null, 'Checklist');
        insert new List<AssessmentIndicatorDefinition>{
            water, sanitary, equipment, hygiene, pests, checklistParent
        };

        AssessmentIndicatorDefinition observation = indicatorDef(Q_OBSERVATION, sanitary.Id, null);
        AssessmentIndicatorDefinition checklistItem = indicatorDef(Q_CHECKLIST_ITEM, checklistParent.Id, null);
        insert new List<AssessmentIndicatorDefinition>{ observation, checklistItem };

        // The junction rows ARE the question order; one list insert fixes it.
        insert new List<AssessmentTaskIndDefinition>{
            junction(foodTaskDef.Id, water.Id, 1),
            junction(foodTaskDef.Id, sanitary.Id, 2),
            junction(foodTaskDef.Id, equipment.Id, 3),
            junction(foodTaskDef.Id, hygiene.Id, 4),
            junction(foodTaskDef.Id, observation.Id, 5),
            junction(foodTaskDef.Id, checklistParent.Id, 6),
            junction(foodTaskDef.Id, checklistItem.Id, 7),
            junction(premisesTaskDef.Id, pests.Id, 1),
            junction(tobaccoTaskDef.Id, checklistParent.Id, 1),
            junction(tobaccoTaskDef.Id, checklistItem.Id, 2)
        };

        insert new List<InspectionAssessmentInd>{
            response(foodTask.Id, water.Id, 'Compliant'),
            responseWithDetail(foodTask.Id, sanitary.Id, 'PHOCSNonCompliant'),
            response(foodTask.Id, equipment.Id, 'N/S (Not Assessed)'),
            response(foodTask.Id, hygiene.Id, 'N/A (Not Applicable)'),
            ticked(foodTask.Id, observation.Id),
            response(foodTask.Id, checklistParent.Id, 'Compliant'),
            ticked(foodTask.Id, checklistItem.Id),
            response(premisesTask.Id, pests.Id, 'Compliant'),
            response(tobaccoTask.Id, checklistParent.Id, 'Compliant'),
            ticked(tobaccoTask.Id, checklistItem.Id)
        };
    }


    private static AccountContactRelation relationFor(
        Map<Id, AccountContactRelation> byContact, Id accountId, Id contactId, String roles,
        Boolean primaryContact
    ) {
        AccountContactRelation acr = byContact.get(contactId);
        if (acr == null) {
            acr = new AccountContactRelation(AccountId = accountId, ContactId = contactId);
        }
        acr.Roles = roles;
        acr.IsActive = true;
        acr.PrimaryContact__c = primaryContact;
        return acr;
    }

    private static AssessmentIndicatorDefinition indicatorDef(String name, Id parentId, String questionType) {
        return new AssessmentIndicatorDefinition(
            Name = name,
            Category__c = 'Sanitation',
            PHOCSParentId__c = parentId,
            InspectionQuestiontype__c = questionType
        );
    }

    private static AssessmentTaskIndDefinition junction(Id taskDefinitionId, Id indicatorDefinitionId, Integer displayOrder) {
        return new AssessmentTaskIndDefinition(
            AssessmentTaskDefinitionId = taskDefinitionId,
            AssessmentIndDefinitionId = indicatorDefinitionId,
            DisplayOrder = displayOrder
        );
    }

    private static InspectionAssessmentInd response(Id taskId, Id definitionId, String result) {
        return new InspectionAssessmentInd(
            AssessmentTaskId = taskId,
            AssessmentIndDefinitionId = definitionId,
            Result = result
        );
    }

    private static InspectionAssessmentInd responseWithDetail(Id taskId, Id definitionId, String result) {
        return new InspectionAssessmentInd(
            AssessmentTaskId = taskId,
            AssessmentIndDefinitionId = definitionId,
            Result = result,
            PHOCSInspectionComments__c = 'Needs correction',
            CorrectiveActionDescription__c = 'Store all food in covered containers',
            ComplianceDueDate__c = System.today().addDays(24)
        );
    }

    private static InspectionAssessmentInd ticked(Id taskId, Id definitionId) {
        return new InspectionAssessmentInd(
            AssessmentTaskId = taskId,
            AssessmentIndDefinitionId = definitionId,
            PHOCSCheckboxResponse__c = true
        );
    }


    private static Id foodVisitId() {
        return [SELECT Id FROM Visit WHERE Account.Type = 'Food' LIMIT 1].Id;
    }

    private static Id tobaccoVisitId() {
        return [SELECT Id FROM Visit WHERE Account.Type = 'Tobacco and Vapour' LIMIT 1].Id;
    }

    private static Map<String, Object> runProvider(Id visitId) {
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>{
            'input' => new Map<String, Object>{ 'contextId' => visitId },
            'output' => output,
            'options' => new Map<String, Object>()
        };
        Object result = new PHOCSInspectionReportTokenData().call('getTokenData', args);
        System.assertEquals(true, result, 'Provider should return true');
        System.assertEquals(false, output.get('hasMoreTokenData'), 'hasMoreTokenData should be false');
        return (Map<String, Object>) output.get('tokenMap');
    }

    private static Map<String, Object> categoryNamed(Map<String, Object> tokens, String categoryName) {
        for (Object o : (List<Object>) tokens.get('findings')) {
            Map<String, Object> category = (Map<String, Object>) o;
            if (categoryName.equals(category.get('categoryName'))) {
                return category;
            }
        }
        return null;
    }

    private static List<String> questionNames(Map<String, Object> category) {
        List<String> names = new List<String>();
        for (Object o : (List<Object>) category.get('questions')) {
            names.add((String) ((Map<String, Object>) o).get('question'));
        }
        return names;
    }

    @isTest
    static void testTombstoneTokens() {
        Id visitId = foodVisitId();

        Test.startTest();
        Map<String, Object> tokens = runProvider(visitId);
        Test.stopTest();

        System.assertEquals('Bills Wings and Things', tokens.get('facilityName'));
        System.assertEquals('Food', tokens.get('facilityType'));
        System.assertEquals('Yes', tokens.get('followUpRequired'), 'Checkbox true should render Yes');
        System.assertEquals('00:30', tokens.get('timeSpent'), 'Time Spent is a Text field held as HH:MM');

        System.assertEquals('123 Spicy Wing Lane', tokens.get('addressLine1'));
        System.assertEquals('Vancouver, BC', tokens.get('addressLine2'));
        System.assertEquals('V6X 5K8', tokens.get('addressLine3'));

        System.assertEquals(true, tokens.get('IF_showOpeningComments'));
        System.assertEquals(true, tokens.get('IF_showClosingComments'));

        System.assertEquals('Yes', tokens.get('signatureRefusal'));
        System.assertEquals('Email', tokens.get('deliveryMethod'));
        System.assertEquals(true, tokens.get('IF_showDeliveryMethod'));
    }

    @isTest
    static void testHealthAuthorityLogoFlags() {
        Id visitId = foodVisitId();

        Test.startTest();
        Map<String, Object> tokens = runProvider(visitId);
        Test.stopTest();

        System.assertEquals(true, tokens.get('IF_HA_Fraser'), 'Facility HA drives the logo flag');
        System.assertEquals(false, tokens.get('IF_HA_Northern'));
        System.assertEquals(false, tokens.get('IF_HA_Interior'));
        System.assertEquals(false, tokens.get('IF_HA_Island'));
        System.assertEquals(false, tokens.get('IF_HA_VancouverCoastal'));
    }

    @isTest
    static void testContactRoles() {
        Id visitId = foodVisitId();

        Test.startTest();
        Map<String, Object> tokens = runProvider(visitId);
        Test.stopTest();

        System.assertEquals('Bill Wingham', tokens.get('operator'));
        System.assertEquals('bill.wingham@example.com', tokens.get('operatorEmail'));
        System.assertEquals('604-123-7890', tokens.get('operatorPhone'));
        System.assertEquals('Bill Wingham', tokens.get('legalName'));
        System.assertEquals('Maise Davis', tokens.get('primaryOwner'));

        System.assertEquals(null, tokens.get('operatorMobile'));
        System.assertEquals(true, tokens.get('IF_showOperatorPhone'));
        System.assertEquals(false, tokens.get('IF_showOperatorMobile'));

        System.assertEquals('250-555-0101', tokens.get('primaryOwnerPhone'));
        System.assertEquals('250-555-0199', tokens.get('primaryOwnerMobile'));
        System.assertEquals(true, tokens.get('IF_showPrimaryOwnerPhone'));
        System.assertEquals(true, tokens.get('IF_showPrimaryOwnerMobile'));

        System.assertEquals(false, tokens.get('IF_showManagerPhone'));
        System.assertEquals(false, tokens.get('IF_showManagerMobile'));
    }

    @isTest
    static void testContactNumbersListDropsTheMissingNumber() {
        Id visitId = foodVisitId();

        Test.startTest();
        Map<String, Object> tokens = runProvider(visitId);
        Test.stopTest();

        System.assertEquals(
            new List<String>{ 'Phone: 604-123-7890' },
            (List<String>) tokens.get('operatorContactNumbers'),
            'Operator has no mobile, so only the phone line is emitted'
        );
        System.assertEquals(
            new List<String>{ 'Phone: 250-555-0101', 'Mobile: 250-555-0199' },
            (List<String>) tokens.get('primaryOwnerContactNumbers'),
            'Both numbers present means both lines, phone first'
        );
        System.assertEquals(
            new List<String>(),
            (List<String>) tokens.get('managerContactNumbers'),
            'No contact in the role means an empty list, not a null token'
        );
    }

    @isTest
    static void testQuestionOrderMatchesInspectionScreen() {
        Id visitId = foodVisitId();

        Test.startTest();
        Map<String, Object> tokens = runProvider(visitId);
        Test.stopTest();

        List<Object> findings = (List<Object>) tokens.get('findings');
        System.assertEquals(2, findings.size(), 'Two AssessmentTasks means two categories');

        System.assertEquals('Premises and Equipment',
            ((Map<String, Object>) findings[0]).get('categoryName'));
        System.assertEquals('Food Sources and Protection',
            ((Map<String, Object>) findings[1]).get('categoryName'));

        System.assertEquals(
            new List<String>{ Q_WATER, Q_SANITARY, Q_EQUIPMENT, Q_HYGIENE },
            questionNames((Map<String, Object>) findings[1]),
            'Questions must come out in junction order, never alphabetically'
        );
    }

    @isTest
    static void testAllQuestionsAppearRegardlessOfComplianceStatus() {
        Id visitId = foodVisitId();

        Test.startTest();
        Map<String, Object> tokens = runProvider(visitId);
        Test.stopTest();

        Map<String, Object> category = categoryNamed(tokens, 'Food Sources and Protection');
        System.assertNotEquals(null, category, 'Category heading comes from AssessmentTask.Name');

        List<Object> questions = (List<Object>) category.get('questions');
        System.assertEquals(4, questions.size(),
            'AC#1 - compliant, not assessed and not applicable questions must all be present');

        Set<String> statuses = new Set<String>();
        Map<String, Object> nonCompliant;
        for (Object q : questions) {
            Map<String, Object> question = (Map<String, Object>) q;
            statuses.add((String) question.get('complianceStatus'));
            if (Boolean.valueOf(question.get('IF_isNonCompliant'))) {
                nonCompliant = question;
            }
        }
        System.assertEquals(
            new Set<String>{ 'Non Compliant', 'Compliant', 'Not Inspected', 'Not Applicable' },
            statuses,
            'Result codes should map to the labels used on the document'
        );

        System.assertNotEquals(null, nonCompliant, 'The non-compliant question should be flagged');
        System.assertEquals(true, nonCompliant.get('IF_showComments'));
        System.assertEquals(true, nonCompliant.get('IF_showAction'));
        System.assertEquals(true, nonCompliant.get('IF_showDueDate'));
        System.assertEquals(true, nonCompliant.get('IF_showObservations'), 'Canned comment should attach');

        List<String> observations = (List<String>) nonCompliant.get('cannedComments');
        System.assertEquals(1, observations.size(),
            'Only the ordinary observation attaches - the ticked checklist item must not');
        System.assertEquals(Q_OBSERVATION, observations[0]);
    }

    @isTest
    static void testChecklistQuestionsStayOutOfTheFindingsTable() {
        Id visitId = foodVisitId();

        Test.startTest();
        Map<String, Object> tokens = runProvider(visitId);
        Test.stopTest();

        for (Object o : (List<Object>) tokens.get('findings')) {
            for (String name : questionNames((Map<String, Object>) o)) {
                System.assertNotEquals(Q_CHECKLIST_PARENT, name,
                    'A Checklist question renders in its own section, never as a findings row');
                System.assertNotEquals(Q_CHECKLIST_ITEM, name,
                    'A ticked checklist item is not a findings row either');
            }
        }

        System.assertEquals(true, tokens.get('InspectionFindings'),
            'The findings section shows when there is at least one ordinary question');
        System.assertEquals(true, tokens.get('IF_showFindings'));
    }

    @isTest
    static void testEducationChecklistOnlyForTobaccoAndVapour() {
        Id visitId = foodVisitId();

        Test.startTest();
        Map<String, Object> tokens = runProvider(visitId);
        Test.stopTest();

        System.assertEquals(false, tokens.get('IF_showEducationChecklist'),
            'Food facility must not show the T&V education checklist');
        System.assertEquals(new List<String>(), (List<String>) tokens.get('educationChecklist'));
    }

    @isTest
    static void testEducationChecklistForTobaccoAndVapourFacility() {
        Id visitId = tobaccoVisitId();

        Test.startTest();
        Map<String, Object> tokens = runProvider(visitId);
        Test.stopTest();

        System.assertEquals(true, tokens.get('IF_showEducationChecklist'));
        System.assertEquals(
            new List<String>{ Q_CHECKLIST_ITEM },
            (List<String>) tokens.get('educationChecklist'),
            'The ticked items of a Checklist parent make up the section'
        );

        System.assertEquals(0, ((List<Object>) tokens.get('findings')).size());
        System.assertEquals(false, tokens.get('InspectionFindings'));
        System.assertEquals(false, tokens.get('IF_showFindings'));
    }

    @isTest
    static void testActionsRequiredFromVisitForNonComplaintInspection() {
        Id visitId = foodVisitId();

        Test.startTest();
        Map<String, Object> tokens = runProvider(visitId);
        Test.stopTest();

        System.assertNotEquals(null, tokens.get('actionsRequiredByLOMHO'));
        System.assertNotEquals(null, tokens.get('actionsRequiredByLicenseeOperator'));
        System.assertEquals(false, tokens.get('IF_showActionsRequired'),
            'Section is CCFL-only; a Food facility should not show it');
    }

    @isTest
    static void testUnsupportedMethod() {
        Boolean thrown = false;
        try {
            new PHOCSInspectionReportTokenData().invokeMethod(
                'invalidMethod',
                new Map<String, Object>(),
                new Map<String, Object>(),
                new Map<String, Object>()
            );
        } catch (Exception e) {
            thrown = true;
            System.assert(e.getMessage().contains('Unsupported method'), 'Should explain the failure');
        }
        System.assertEquals(true, thrown, 'Unsupported method should throw');
    }
}