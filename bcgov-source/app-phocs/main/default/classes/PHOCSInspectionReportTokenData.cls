/**
 * Token data provider for the PHOCS Inspection Report (EHIS-3844), modelled on
 * CustomTokenInspectionData.
 */

global without sharing class PHOCSInspectionReportTokenData implements omnistudio.VlocityOpenInterface2 {

    private static final Decimal UNORDERED = 999999;

    private static final String ERROR_UNSUPPORTED = 'Unsupported method. Only method [getTokenData] is supported.';

    private static final Set<String> CCFL_TYPES = new Set<String>{ 'Child Care', 'Residential Care' };
    private static final String TOBACCO_TYPE = 'Tobacco and Vapour';

    private static final Set<String> CASE_SOURCED_INSPECTION_TYPES = new Set<String>{
        'Complaint', 'Complaint Follow-up', 'Reported Incident', 'Reported Incident Follow-up'
    };

    private static final String QUESTION_TYPE_CHECKLIST = 'Checklist';

    private static final Map<String, String> RESULT_LABELS = new Map<String, String>{
        'PHOCSNonCompliant'    => 'Non Compliant',
        'Compliant'            => 'Compliant',
        'N/S (Not Assessed)'   => 'Not Inspected',
        'N/A (Not Applicable)' => 'Not Applicable'
    };

    private static final Map<String, String> HA_FLAGS = new Map<String, String>{
        'Northern Health - NH'           => 'IF_HA_Northern',
        'Interior Health - IH'           => 'IF_HA_Interior',
        'Island Health - Island'         => 'IF_HA_Island',
        'Vancouver Coastal Health - VCH' => 'IF_HA_VancouverCoastal',
        'Fraser Health - FH'             => 'IF_HA_Fraser'
    };

    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> input = (Map<String, Object>) args.get('input');
        Map<String, Object> output = (Map<String, Object>) args.get('output');
        Map<String, Object> options = (Map<String, Object>) args.get('options');
        return invokeMethod(action, input, output, options);
    }

    public Object invokeMethod(String methodName, Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) {
        if (methodName != 'getTokenData') {
            throw new PHOCSInspectionReportTokenException(ERROR_UNSUPPORTED);
        }
        return getTokenData(input, output, options);
    }

    private Boolean getTokenData(Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) {
        Boolean success = getInspectionTokenData(input, output);
        output.put('hasMoreTokenData', false);
        return success;
    }

    private Boolean getInspectionTokenData(Map<String, Object> input, Map<String, Object> output) {
        Id visitId = (Id) input.get('contextId');
        Map<String, Object> tokens = new Map<String, Object>();

        Visit visitRec = [
            SELECT Id, Name, ContextId, CaseContextId__c, OwnerId, Owner.Name, AccountId, Account.Name, Account.Type,
                   Account.AccountNumberRTPrefixed__c, Account.TotalMaximumCapacity__c, Account.HealthAuthority__c,
                   Account.Physical_Address__Street__s, Account.Physical_Address__City__s,
                   Account.Physical_Address__StateCode__s, Account.Physical_Address__PostalCode__s,
                   ActualVisitStartTime, VisitType.Name, TimeSpentMinutes__c, FollowUpInspectionRequired__c,
                   InspectionMethod__c, InspectionTypeOtherSpecify__c, InstructionDescription, StatusRemarks,
                   SignatureRefusal__c, DeliveryMethod__c, HealthAuthority__c,
                   ActionsRequiredByLOMHO__c, ActionsRequiredByLicenseeOperator__c
            FROM Visit
            WHERE Id = :visitId
            LIMIT 1
        ];

        String facilityType = visitRec.Account.Type;
        String inspectionType = visitRec.VisitType != null ? visitRec.VisitType.Name : null;

        addTombstoneTokens(tokens, visitRec, facilityType, inspectionType);
        addHealthAuthorityFlags(tokens, visitRec.Account.HealthAuthority__c);
        addContactTokens(tokens, visitRec.AccountId);
        addCategoryOfCare(tokens, visitRec.AccountId);
        addLicenceNumber(tokens, visitRec.AccountId);
        Map<String, Decimal> questionOrders = buildQuestionOrderMap(visitRec.Id);
        addFindings(tokens, visitRec.Id, questionOrders);
        addEducationChecklist(tokens, visitRec.Id, facilityType, questionOrders);
        addActionsRequired(tokens, visitRec, inspectionType, facilityType);
        addClosingTokens(tokens, visitRec);

        output.put('tokenMap', tokens);
        return true;
    }


    private void addTombstoneTokens(Map<String, Object> tokens, Visit visitRec, String facilityType, String inspectionType) {
        tokens.put('inspectionReportNumber', visitRec.Name);
        tokens.put('facilityName', visitRec.Account.Name);
        tokens.put('facilityType', facilityType);
        tokens.put('facilityNumber', visitRec.Account.AccountNumberRTPrefixed__c);
        tokens.put('inspectionDate', formatLongDate(dateOf(visitRec.ActualVisitStartTime)));
        tokens.put('inspectionType', inspectionType);
        tokens.put('inspectionTypeOther', visitRec.InspectionTypeOtherSpecify__c);
        tokens.put('inspectionMethod', visitRec.InspectionMethod__c);
        tokens.put('licensedCapacity', formatWholeNumber(visitRec.Account.TotalMaximumCapacity__c));

        tokens.put('followUpRequired', visitRec.FollowUpInspectionRequired__c ? 'Yes' : 'No');

        tokens.put('timeSpent', String.isBlank(visitRec.TimeSpentMinutes__c) ? null : visitRec.TimeSpentMinutes__c);

        Map<String, String> address = buildAddress(visitRec.Account);
        tokens.put('addressLine1', address.get('addressLine1'));
        tokens.put('addressLine2', address.get('addressLine2'));
        tokens.put('addressLine3', address.get('addressLine3'));

        tokens.put('openingComments', visitRec.InstructionDescription);
        tokens.put('IF_showOpeningComments', String.isNotBlank(visitRec.InstructionDescription));

        // Routing already picks the template; these are only for in-paragraph conditional text.
        tokens.put('IF_isCCFL', CCFL_TYPES.contains(facilityType));
        tokens.put('IF_isTobaccoVapour', TOBACCO_TYPE.equals(facilityType));
        tokens.put('IF_isOther', !CCFL_TYPES.contains(facilityType) && !TOBACCO_TYPE.equals(facilityType));
    }

    private void addHealthAuthorityFlags(Map<String, Object> tokens, String healthAuthority) {
        for (String flag : HA_FLAGS.values()) {
            tokens.put(flag, false);
        }
        if (String.isNotBlank(healthAuthority) && HA_FLAGS.containsKey(healthAuthority)) {
            tokens.put(HA_FLAGS.get(healthAuthority), true);
        }
    }

    private void addClosingTokens(Map<String, Object> tokens, Visit visitRec) {
        tokens.put('closingComments', visitRec.StatusRemarks);
        tokens.put('IF_showClosingComments', String.isNotBlank(visitRec.StatusRemarks));
        tokens.put('environmentalHealthOfficer', visitRec.Owner != null ? visitRec.Owner.Name : null);
        tokens.put('signatureRefusal', visitRec.SignatureRefusal__c ? 'Yes' : 'No');
        tokens.put('deliveryMethod', visitRec.DeliveryMethod__c);
        tokens.put('IF_showDeliveryMethod', String.isNotBlank(visitRec.DeliveryMethod__c));
    }


    private void addContactTokens(Map<String, Object> tokens, Id accountId) {
        List<AccountContactRelation> relations = [
            SELECT ContactId, Roles, PrimaryContact__c, Contact.Name, Contact.Email, Contact.Phone,
                   Contact.MobilePhone
            FROM AccountContactRelation
            WHERE AccountId = :accountId AND IsActive = true
        ];

        Contact operator, licensee, manager, primaryOwner;
        for (AccountContactRelation acr : relations) {
            if (String.isBlank(acr.Roles) || acr.Contact == null) {
                continue;
            }
            Set<String> roles = new Set<String>(acr.Roles.split(';'));
            if (operator == null && roles.contains('Operator')) {
                operator = acr.Contact;
            }
            if (licensee == null && roles.contains('Licensee')) {
                licensee = acr.Contact;
            }
            if (manager == null && roles.contains('Manager')) {
                manager = acr.Contact;
            }

            if (primaryOwner == null && roles.contains('Owner Contact') && acr.PrimaryContact__c == true) {
                primaryOwner = acr.Contact;
            }
        }

        putContact(tokens, 'operator', operator);
        putContact(tokens, 'licensee', licensee);
        putContact(tokens, 'manager', manager);
        putContact(tokens, 'primaryOwner', primaryOwner);
        putContact(tokens, 'legalName', operator);
    }

    private void putContact(Map<String, Object> tokens, String prefix, Contact c) {
        String phone = c == null ? null : c.Phone;
        String mobile = c == null ? null : c.MobilePhone;

        tokens.put(prefix, c == null ? null : c.Name);
        tokens.put(prefix + 'Email', c == null ? null : c.Email);
        tokens.put(prefix + 'Phone', String.isBlank(phone) ? null : phone.trim());
        tokens.put(prefix + 'Mobile', String.isBlank(mobile) ? null : mobile.trim());
        tokens.put(showFlag(prefix, 'Phone'), String.isNotBlank(phone));
        tokens.put(showFlag(prefix, 'Mobile'), String.isNotBlank(mobile));

        List<String> numbers = new List<String>();
        if (String.isNotBlank(phone)) {
            numbers.add('Phone: ' + phone.trim());
        }
        if (String.isNotBlank(mobile)) {
            numbers.add('Mobile: ' + mobile.trim());
        }
        tokens.put(prefix + 'ContactNumbers', numbers);
    }

    private static String showFlag(String prefix, String suffix) {
        return 'IF_show' + prefix.substring(0, 1).toUpperCase() + prefix.substring(1) + suffix;
    }

    private void addCategoryOfCare(Map<String, Object> tokens, Id accountId) {
        Set<String> types = new Set<String>();
        for (Asset a : [SELECT Type__c FROM Asset WHERE AccountId = :accountId AND Status = 'Active' AND Type__c != null]) {
            types.add(a.Type__c);
        }
        List<String> ordered = new List<String>(types);
        ordered.sort();

        tokens.put('categoryOfCare', ordered.isEmpty() ? null : String.join(ordered, ', '));

        List<String> lines = new List<String>();
        for (Integer i = 0; i < ordered.size(); i++) {
            lines.add(i < ordered.size() - 1 ? ordered[i] + ',' : ordered[i]);
        }
        tokens.put('categoriesOfCare', lines);
    }

    private void addLicenceNumber(Map<String, Object> tokens, Id accountId) {
        List<BusinessLicense> licences = [
            SELECT Identifier FROM BusinessLicense
            WHERE Account__c = :accountId AND Status = 'Active'
            ORDER BY CreatedDate DESC LIMIT 1
        ];
        tokens.put('licenceNumber', licences.isEmpty() ? null : licences[0].Identifier);
    }

    private Map<String, Decimal> buildQuestionOrderMap(Id visitId) {
        Map<String, Decimal> questionOrders = new Map<String, Decimal>();

        Set<Id> taskDefinitionIds = new Set<Id>();
        for (AssessmentTask task : [
            SELECT AssessmentTaskDefinitionId
            FROM AssessmentTask
            WHERE ParentId = :visitId AND AssessmentTaskDefinitionId != null
        ]) {
            taskDefinitionIds.add(task.AssessmentTaskDefinitionId);
        }
        if (taskDefinitionIds.isEmpty()) {
            return questionOrders;
        }

        Map<Id, Integer> nextPositionByTaskDefinition = new Map<Id, Integer>();
        for (AssessmentTaskIndDefinition def : [
            SELECT AssessmentTaskDefinitionId, AssessmentIndDefinitionId
            FROM AssessmentTaskIndDefinition
            WHERE AssessmentTaskDefinitionId IN :taskDefinitionIds
            ORDER BY AssessmentTaskDefinitionId, Id
        ]) {
            Integer position = nextPositionByTaskDefinition.containsKey(def.AssessmentTaskDefinitionId)
                ? nextPositionByTaskDefinition.get(def.AssessmentTaskDefinitionId)
                : 0;
            questionOrders.put(
                questionOrderKey(def.AssessmentTaskDefinitionId, def.AssessmentIndDefinitionId),
                Decimal.valueOf(position)
            );
            nextPositionByTaskDefinition.put(def.AssessmentTaskDefinitionId, position + 1);
        }
        return questionOrders;
    }

    private static String questionOrderKey(Id taskDefinitionId, Id indicatorDefinitionId) {
        return String.valueOf(taskDefinitionId) + '_' + String.valueOf(indicatorDefinitionId);
    }

    private static Decimal questionOrderOf(Map<String, Decimal> questionOrders, InspectionAssessmentInd rec) {
        Id taskDefinitionId = rec.AssessmentTask == null ? null : rec.AssessmentTask.AssessmentTaskDefinitionId;
        return questionOrders.get(questionOrderKey(taskDefinitionId, rec.AssessmentIndDefinitionId));
    }

    private void addFindings(Map<String, Object> tokens, Id visitId, Map<String, Decimal> questionOrders) {
  
        Map<String, List<OrderedIndicator>> observationsByParent = new Map<String, List<OrderedIndicator>>();
        for (InspectionAssessmentInd child : [
            SELECT AssessmentTaskId, AssessmentIndDefinitionId, AssessmentTask.AssessmentTaskDefinitionId,
                   AssessmentIndDefinition.PHOCSParentId__c, AssessmentIndDefinition.Name
            FROM InspectionAssessmentInd
            WHERE AssessmentTask.ParentId = :visitId
              AND AssessmentIndDefinition.PHOCSParentId__c != null
              AND PHOCSCheckboxResponse__c = true
              AND AssessmentIndDefinition.PHOCSParentId__r.InspectionQuestiontype__c != :QUESTION_TYPE_CHECKLIST
        ]) {
            if (String.isBlank(child.AssessmentIndDefinition.Name)) {
                continue;
            }
            String key = child.AssessmentTaskId + '_' + child.AssessmentIndDefinition.PHOCSParentId__c;
            if (!observationsByParent.containsKey(key)) {
                observationsByParent.put(key, new List<OrderedIndicator>());
            }
            observationsByParent.get(key).add(new OrderedIndicator(child, null, questionOrderOf(questionOrders, child)));
        }
        for (List<OrderedIndicator> observations : observationsByParent.values()) {
            observations.sort();
        }

        Map<Id, RegulatoryCodeViolation> violationByQuestion = new Map<Id, RegulatoryCodeViolation>();
        for (RegulatoryCodeViolation v : [
            SELECT InspectionAssmntIndId, CorrectiveActionDescription, ComplianceDueDate,
                   Corrected_During_Inspection__c
            FROM RegulatoryCodeViolation
            WHERE InspectionId = :visitId AND InspectionAssmntIndId != null
            ORDER BY CreatedDate ASC
        ]) {
            violationByQuestion.put(v.InspectionAssmntIndId, v);
        }

        // Parent questions, minus the Checklist branch, sorted as the screen orders them.
        List<OrderedIndicator> orderedQuestions = new List<OrderedIndicator>();
        for (InspectionAssessmentInd rec : [
            SELECT Id, AssessmentTaskId, AssessmentTask.Name, AssessmentTask.SequenceNumber,
                   AssessmentTask.AssessmentTaskDefinitionId,
                   AssessmentIndDefinitionId, AssessmentIndDefinition.Name,
                   Result, ComplianceDueDate__c, PHOCSInspectionComments__c,
                   CorrectiveActionDescription__c, CorrectedDuringInspection__c
            FROM InspectionAssessmentInd
            WHERE AssessmentTask.ParentId = :visitId
              AND AssessmentIndDefinition.PHOCSParentId__c = null
              AND AssessmentIndDefinition.InspectionQuestiontype__c != :QUESTION_TYPE_CHECKLIST
        ]) {
            orderedQuestions.add(new OrderedIndicator(
                rec,
                rec.AssessmentTask == null ? null : rec.AssessmentTask.SequenceNumber,
                questionOrderOf(questionOrders, rec)
            ));
        }
        orderedQuestions.sort();

        // AssessmentTask.Name is the heading; first-sight order is screen order because of the sort.
        Map<Id, Map<String, Object>> categoriesByTask = new Map<Id, Map<String, Object>>();
        List<Object> findings = new List<Object>();

        for (OrderedIndicator item : orderedQuestions) {
            InspectionAssessmentInd rec = item.indicator;

            Map<String, Object> category = categoriesByTask.get(rec.AssessmentTaskId);
            if (category == null) {
                category = new Map<String, Object>();
                category.put('categoryName', String.isBlank(rec.AssessmentTask.Name) ? 'Uncategorized' : rec.AssessmentTask.Name);
                category.put('questions', new List<Object>());
                categoriesByTask.put(rec.AssessmentTaskId, category);
                findings.add(category);
            }

            String key = rec.AssessmentTaskId + '_' + rec.AssessmentIndDefinitionId;
            List<String> observations = new List<String>();
            if (observationsByParent.containsKey(key)) {
                for (OrderedIndicator observation : observationsByParent.get(key)) {
                    observations.add(observation.name);
                }
            }

            String statusLabel = RESULT_LABELS.containsKey(rec.Result) ? RESULT_LABELS.get(rec.Result) : rec.Result;
            Boolean isNonCompliant = 'PHOCSNonCompliant'.equals(rec.Result);

            RegulatoryCodeViolation violation = violationByQuestion.get(rec.Id);

            String correctiveAction = rec.CorrectiveActionDescription__c;
            Datetime complianceDueDate = rec.ComplianceDueDate__c;
            Boolean correctedDuringInspection = rec.CorrectedDuringInspection__c;

            if (violation != null) {
                if (String.isNotBlank(violation.CorrectiveActionDescription)) {
                    correctiveAction = violation.CorrectiveActionDescription;
                }
                if (violation.ComplianceDueDate != null) {
                    complianceDueDate = violation.ComplianceDueDate;
                }
                correctedDuringInspection = correctedDuringInspection || violation.Corrected_During_Inspection__c;
            }

            Map<String, Object> question = new Map<String, Object>();
            question.put('question', rec.AssessmentIndDefinition.Name);
            question.put('complianceStatus', statusLabel);
            question.put('IF_showComplianceStatus', !correctedDuringInspection);
            question.put('IF_showCDI', correctedDuringInspection);
            question.put('IF_isNonCompliant', isNonCompliant);
            question.put('IF_statusRed', !correctedDuringInspection && isNonCompliant);
            question.put('IF_statusNormal', !correctedDuringInspection && !isNonCompliant);
            question.put('cannedComments', observations);
            question.put('IF_showObservations', !observations.isEmpty());
            question.put('comments', rec.PHOCSInspectionComments__c);
            question.put('IF_showComments', String.isNotBlank(rec.PHOCSInspectionComments__c));
            question.put('correctiveAction', correctiveAction);
            question.put('IF_showAction', String.isNotBlank(correctiveAction));
            question.put('complianceDueDate', formatShortDate(dateOf(complianceDueDate)));
            question.put('IF_showDueDate', complianceDueDate != null);

            ((List<Object>) category.get('questions')).add(question);
        }

        tokens.put('findings', findings);
        tokens.put('IF_showFindings', !findings.isEmpty());
        tokens.put('InspectionFindings', !findings.isEmpty());
    }

    // The education checklist is a standalone section, never a row in the findings table.
    private void addEducationChecklist(Map<String, Object> tokens, Id visitId, String facilityType, Map<String, Decimal> questionOrders) {
        List<String> checklist = new List<String>();
        if (TOBACCO_TYPE.equals(facilityType)) {
            // Items are ticked CHILDREN of a Checklist parent. InspectionQuestiontype__c sits on the
            // parent, so the filter has to reach it through PHOCSParentId__r.
            List<OrderedIndicator> items = new List<OrderedIndicator>();
            for (InspectionAssessmentInd rec : [
                SELECT AssessmentIndDefinitionId, AssessmentTask.SequenceNumber,
                       AssessmentTask.AssessmentTaskDefinitionId, AssessmentIndDefinition.Name
                FROM InspectionAssessmentInd
                WHERE AssessmentTask.ParentId = :visitId
                  AND AssessmentIndDefinition.PHOCSParentId__c != null
                  AND PHOCSCheckboxResponse__c = true
                  AND AssessmentIndDefinition.PHOCSParentId__r.InspectionQuestiontype__c = :QUESTION_TYPE_CHECKLIST
            ]) {
                if (String.isNotBlank(rec.AssessmentIndDefinition.Name)) {
                    items.add(new OrderedIndicator(
                        rec,
                        rec.AssessmentTask == null ? null : rec.AssessmentTask.SequenceNumber,
                        questionOrderOf(questionOrders, rec)
                    ));
                }
            }
            items.sort();
            for (OrderedIndicator item : items) {
                checklist.add(item.name);
            }
        }
        tokens.put('educationChecklist', checklist);
        tokens.put('IF_showEducationChecklist', !checklist.isEmpty());
    }


    private void addActionsRequired(Map<String, Object> tokens, Visit visitRec, String inspectionType, String facilityType) {
        List<String> lomho = new List<String>();
        List<String> licenseeOperator = new List<String>();

        Boolean sourceFromCase = inspectionType != null && CASE_SOURCED_INSPECTION_TYPES.contains(inspectionType);

        if (sourceFromCase) {

            Id caseId = visitRec.CaseContextId__c != null ? visitRec.CaseContextId__c : visitRec.ContextId;

            if (caseId != null) {
                Set<String> seenLomho = new Set<String>();
                Set<String> seenLicenseeOperator = new Set<String>();
                for (InteractionSummary summary : [
                    SELECT ActionsRequiredbyLOMHO__c, ActionsRequiredbyLicenseeOperator__c
                    FROM InteractionSummary
                    WHERE RelatedRecordId = :caseId OR CaseId__c = :caseId
                ]) {
                    for (String action : splitMultiselect(summary.ActionsRequiredbyLOMHO__c)) {
                        if (seenLomho.add(action)) {
                            lomho.add(action);
                        }
                    }
                    for (String action : splitMultiselect(summary.ActionsRequiredbyLicenseeOperator__c)) {
                        if (seenLicenseeOperator.add(action)) {
                            licenseeOperator.add(action);
                        }
                    }
                }
            }
        } else {
            lomho = splitMultiselect(visitRec.ActionsRequiredByLOMHO__c);
            licenseeOperator = splitMultiselect(visitRec.ActionsRequiredByLicenseeOperator__c);
        }

        tokens.put('actionsRequiredByLOMHO', lomho);
        tokens.put('actionsRequiredByLicenseeOperator', licenseeOperator);
        tokens.put('IF_showActionsRequired',
            CCFL_TYPES.contains(facilityType) && (!lomho.isEmpty() || !licenseeOperator.isEmpty()));
    }


    private static List<String> splitMultiselect(String value) {
        List<String> parts = new List<String>();
        if (String.isBlank(value)) {
            return parts;
        }
        for (String part : value.split(';')) {
            if (String.isNotBlank(part)) {
                parts.add(part.trim());
            }
        }
        return parts;
    }


    private static Map<String, String> buildAddress(Account acc) {
        Map<String, String> address = new Map<String, String>();
        List<String> cityProvince = new List<String>();

        if (String.isNotBlank(acc.Physical_Address__City__s)) {
            cityProvince.add(acc.Physical_Address__City__s.trim());
        }
        if (String.isNotBlank(acc.Physical_Address__StateCode__s)) {
            cityProvince.add(acc.Physical_Address__StateCode__s.trim());
        }

        address.put('addressLine1', String.isNotBlank(acc.Physical_Address__Street__s) ? acc.Physical_Address__Street__s.trim() : null);
        address.put('addressLine2', cityProvince.isEmpty() ? null : String.join(cityProvince, ', '));
        address.put('addressLine3', String.isNotBlank(acc.Physical_Address__PostalCode__s) ? acc.Physical_Address__PostalCode__s.trim() : null);
        return address;
    }

    private static Date dateOf(Datetime value) {
        return value == null ? null : value.date();
    }

    private static String formatLongDate(Date value) {
        return value == null ? null : Datetime.newInstance(value, Time.newInstance(0, 0, 0, 0)).format('MMMM d, yyyy');
    }

    private static String formatShortDate(Date value) {
        return value == null ? null : Datetime.newInstance(value, Time.newInstance(0, 0, 0, 0)).format('dd-MMM-yyyy');
    }

    private static String formatWholeNumber(Decimal value) {
        return value == null ? null : String.valueOf(value.setScale(0));
    }

    /**
     * Category (AssessmentTask.SequenceNumber), then position in the task's junction. The name
     * tiebreak only reaches questions with no junction row. Missing values sort last.
     */
    private class OrderedIndicator implements Comparable {
        private final InspectionAssessmentInd indicator;
        private final Decimal categorySequence;
        private final Decimal questionOrder;
        private final String name;

        private OrderedIndicator(InspectionAssessmentInd source, Decimal categorySequence, Decimal questionOrder) {
            this.indicator = source;
            this.categorySequence = categorySequence == null ? UNORDERED : categorySequence;
            this.questionOrder = questionOrder == null ? UNORDERED : questionOrder;
            this.name = (source.AssessmentIndDefinition != null && source.AssessmentIndDefinition.Name != null)
                ? source.AssessmentIndDefinition.Name
                : '';
        }

        public Integer compareTo(Object other) {
            OrderedIndicator that = (OrderedIndicator) other;
            if (this.categorySequence != that.categorySequence) {
                return this.categorySequence < that.categorySequence ? -1 : 1;
            }
            if (this.questionOrder != that.questionOrder) {
                return this.questionOrder < that.questionOrder ? -1 : 1;
            }
            return this.name.compareTo(that.name);
        }
    }

    class PHOCSInspectionReportTokenException extends Exception {}
}