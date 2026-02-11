global without sharing class CustomTokenInspectionData
    implements omnistudio.VlocityOpenInterface2
{
    private static final String ERROR_UNSUPPORTED =
        'Unsupported method. Only method [getTokenData] is supported.';

    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> input =
            (Map<String, Object>) args.get('input');
        Map<String, Object> output =
            (Map<String, Object>) args.get('output');
        Map<String, Object> options =
            (Map<String, Object>) args.get('options');

        return invokeMethod(action, input, output, options);
    }

    public Object invokeMethod(
        String methodName,
        Map<String, Object> input,
        Map<String, Object> output,
        Map<String, Object> options
    ) {
        if (methodName != 'getTokenData') {
            throw new CustomTokenDataExtractorException(ERROR_UNSUPPORTED);
        }

        return getTokenData(input, output, options);
    }

    /**
     * Mock token response for testing
     */
    private Boolean getTokenData(
        Map<String, Object> input,
        Map<String, Object> output,
        Map<String, Object> options
    ) {
        Map<String, Object> tokenMap = new Map<String, Object>();
		 Boolean success = false;
        success  = getInspectionTokenData(input,output,options);
        //tokenMap.put('AccountName', 'Example Account');
        //output.put('tokenMap', tokenMap);
        
        output.put('hasMoreTokenData', false);
		
        return success;
    }
    
  private Boolean getInspectionTokenData(
        Map<String, Object> input, 
        Map<String, Object> output, 
        Map<String, Object> options)
    { 
        Boolean success = false;
         Id visitId = (Id) input.get('contextId');
        Report report = new Report();

        Visit visitRec = [
            SELECT
                Id,
                Owner.Name,
                Account.Name,
                Account.BillingStreet,
                Account.BillingCity,
                Account.BillingState,
                Account.BillingPostalCode,
                ActualVisitStartTime,
                ActualVisitEndTime,
                VisitType.Name,
                TimeSpentMinutes__c,
            	StatusRemarks
            FROM Visit
            WHERE Id = :visitId
            LIMIT 1
        ];
 Map<String, Object> reportMap = new Map<String, Object>();
        /* ---------------- HEADER ---------------- */
    reportMap.put('inspector', visitRec.Owner.Name);
    reportMap.put('dairyPlant', visitRec.Account.Name);
    reportMap.put('address', buildAddress(visitRec.Account));
    reportMap.put(
        'inspectionDate',
        visitRec.ActualVisitEndTime != null
            ? visitRec.ActualVisitEndTime.date()
            : null
    );
    reportMap.put('inspectionType', visitRec.VisitType.Name);
    reportMap.put(
        'timeSpent',
        visitRec.TimeSpentMinutes__c != null
            ? Integer.valueOf(visitRec.TimeSpentMinutes__c)
            : 0
    );
    reportMap.put('closingComments', visitRec.StatusRemarks);

       /* ---------------- CANNED COMMENTS ---------------- */
    Map<Id, List<String>> cannedCommentsByParentDef = new Map<Id, List<String>>();

    for (InspectionAssessmentInd cc : [
        SELECT
            AssessmentIndDefinition.PHOCSParentId__c,
            AssessmentIndDefinition.Name
        FROM InspectionAssessmentInd
        WHERE AssessmentTask.ParentId = :visitRec.Id
        AND AssessmentIndDefinition.PHOCSParentId__c != null
        AND PHOCSCheckboxResponse__c = true
    ]) {
        Id parentDefId = cc.AssessmentIndDefinition.PHOCSParentId__c;

        if (!cannedCommentsByParentDef.containsKey(parentDefId)) {
            cannedCommentsByParentDef.put(parentDefId, new List<String>());
        }

        if (String.isNotBlank(cc.AssessmentIndDefinition.Name)) {
            cannedCommentsByParentDef
                .get(parentDefId)
                .add(cc.AssessmentIndDefinition.Name);
        }
    }

    /* ---------------- RESULT LISTS ---------------- */
    List<Object> criticalInfractions = new List<Object>();
    List<Object> nonCriticalInfractions = new List<Object>();
    List<Object> inCompliance = new List<Object>();
    List<Object> notAssessed = new List<Object>();
    List<Object> notApplicable = new List<Object>();

    for (InspectionAssessmentInd rec : [
        SELECT
            AssessmentIndDefinitionId,
            AssessmentIndDefinition.Criticality__c,
            AssessmentIndDefinition.Category__c,
            AssessmentIndDefinition.Name,
            Result,
            ComplianceDueDate__c,
            Comments__c,
            CorrectiveActionDescription__c
        FROM InspectionAssessmentInd
        WHERE AssessmentTask.ParentId = :visitRec.Id
        AND AssessmentIndDefinition.PHOCSParentId__c = null
        ORDER BY
            AssessmentIndDefinition.Criticality__c,
            AssessmentIndDefinition.Group_Record_Id__c
    ]) {
        Map<String, Object> item = new Map<String, Object>();
        item.put('category', rec.AssessmentIndDefinition.Category__c);
        item.put('question', rec.AssessmentIndDefinition.Name);
        item.put('complianceDueDate', rec.ComplianceDueDate__c);
        item.put('comments', rec.Comments__c);
        item.put('correctiveAction', rec.CorrectiveActionDescription__c);
        item.put(
            'cannedComments',
            cannedCommentsByParentDef.containsKey(rec.AssessmentIndDefinitionId)
                ? cannedCommentsByParentDef.get(rec.AssessmentIndDefinitionId)
                : new List<String>()
        );

        if (rec.Result == 'PHOCSNonCompliant') {
            if (rec.AssessmentIndDefinition.Criticality__c == 'Critical') {
                criticalInfractions.add(item);
            } else {
                nonCriticalInfractions.add(item);
            }
        } else if (rec.Result == 'Compliant') {
            inCompliance.add(item);
        } else if (rec.Result == 'N/S (Not Assessed)') {
            notAssessed.add(item);
        } else if (rec.Result == 'N/A (Not Applicable)') {
            notApplicable.add(item);
        }
    }

    /* ---------------- FINAL TOKEN MAP ---------------- */
    reportMap.put('criticalInfractions', criticalInfractions);
    reportMap.put('nonCriticalInfractions', nonCriticalInfractions);
    reportMap.put('inCompliance', inCompliance);
    reportMap.put('notAssessed', notAssessed);
    reportMap.put('notApplicable', notApplicable);

    output.put('tokenMap', reportMap);
    System.debug('jsonoutput*'+JSON.serializePretty(reportMap));
        success = true;
        return  success;
        
    }
    
    private static String buildAddress(Account acc) {
        List<String> parts = new List<String>();
        if (String.isNotBlank(acc.BillingStreet)) parts.add(acc.BillingStreet);
        if (String.isNotBlank(acc.BillingCity)) parts.add(acc.BillingCity);
        if (String.isNotBlank(acc.BillingState)) parts.add(acc.BillingState);
        if (String.isNotBlank(acc.BillingPostalCode)) parts.add(acc.BillingPostalCode);
        return String.join(parts, ', ');
    }

    global class Report {
        global Header header;
        global List<LineItem> criticalInfractions = new List<LineItem>();
        global List<LineItem> nonCriticalInfractions = new List<LineItem>();
        global List<LineItem> inCompliance = new List<LineItem>();
        global List<LineItem> notAssessed = new List<LineItem>();
        global List<LineItem> notApplicable = new List<LineItem>();
    }

    global class Header {
        global String inspector;
        global String dairyPlant;
        global String address;
        global Date inspectionDate;
        global String inspectionType;
        global Integer timeSpentMinutes;
    }

    global class LineItem {
        global String category;
        global String question;
        global Date complianceDueDate;
        global List<String> cannedComments;
        global String comments;
        global String correctiveAction;
    }

    class CustomTokenDataExtractorException extends Exception {}
}