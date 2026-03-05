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
                Account.Physical_Address__Street__s,
                Account.Physical_Address__City__s,
                Account.Physical_Address__StateCode__s,
                Account.Physical_Address__PostalCode__s,
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
        visitRec.TimeSpentMinutes__c != null ? String.valueOf(visitRec.TimeSpentMinutes__c) : null);
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
  Map<String, List<Object>> criticalInfractions = new Map<String, List<Object>>();
  Map<String, List<Object>> nonCriticalInfractions = new Map<String, List<Object>>();
  Map<String, List<Object>> inCompliance = new Map<String, List<Object>>();
  Map<String, List<Object>> notAssessed = new Map<String, List<Object>>();
  Map<String, List<Object>> notApplicable = new Map<String, List<Object>>();

    for (InspectionAssessmentInd rec : [
        SELECT
            AssessmentIndDefinitionId,
            AssessmentIndDefinition.Criticality__c,
            AssessmentIndDefinition.Category__c,
            AssessmentIndDefinition.Name,
            Result,
            ComplianceDueDate__c,
            PHOCSInspectionComments__c,
            CorrectiveActionDescription__c
        FROM InspectionAssessmentInd
        WHERE AssessmentTask.ParentId = :visitRec.Id
        AND AssessmentIndDefinition.PHOCSParentId__c = null
        ORDER BY
            AssessmentIndDefinition.Criticality__c
    ]) {
        Map<String, Object> item = new Map<String, Object>();
        item.put('category', rec.AssessmentIndDefinition.Category__c);
        item.put('question', rec.AssessmentIndDefinition.Name);
        item.put('complianceDueDate', rec.ComplianceDueDate__c!=null?rec.ComplianceDueDate__c.date():null);
        item.put('comments', rec.PHOCSInspectionComments__c);
        item.put('correctiveAction', rec.CorrectiveActionDescription__c);
        item.put(
            'cannedComments',
            cannedCommentsByParentDef.containsKey(rec.AssessmentIndDefinitionId)
                ? cannedCommentsByParentDef.get(rec.AssessmentIndDefinitionId)
                : new List<String>()
        );
		String categoryName = rec.AssessmentIndDefinition.Category__c;
        if (rec.Result == 'PHOCSNonCompliant') {
            if (rec.AssessmentIndDefinition.Criticality__c == 'Critical') {
                 addToGroupedCategory(criticalInfractions, categoryName, item);
            } else {
                addToGroupedCategory(nonCriticalInfractions, categoryName, item);
            }
        } else if (rec.Result == 'Compliant') {
           addToGroupedCategory(inCompliance, categoryName, item);
        } else if (rec.Result == 'N/S (Not Assessed)') {
           addToGroupedCategory(notAssessed, categoryName, item);
        } else if (rec.Result == 'N/A (Not Applicable)') {
           addToGroupedCategory(notApplicable, categoryName, item);
        }
    }

    /* ---------------- FINAL TOKEN MAP ---------------- */
	List<Object> criticalList = buildCategoryList(criticalInfractions);
	List<Object> nonCriticalList = buildCategoryList(nonCriticalInfractions);
	List<Object> inComplianceList = buildCategoryList(inCompliance);
	List<Object> notAssessedList = buildCategoryList(notAssessed);
	List<Object> notApplicableList = buildCategoryList(notApplicable);

	reportMap.put('criticalInfractions', criticalList);
	reportMap.put('nonCriticalInfractions', nonCriticalList);
	reportMap.put('inCompliance', inComplianceList);
	reportMap.put('notAssessed', notAssessedList);
	reportMap.put('notApplicable', notApplicableList);

/* ---------------- CONDITIONAL DISPLAY FLAGS ---------------- */
	reportMap.put('showCriticalInfractions', !criticalList.isEmpty());
	reportMap.put('showNonCriticalInfractions', !nonCriticalList.isEmpty());
	reportMap.put('showInCompliance', !inComplianceList.isEmpty());
	reportMap.put('showNotAssessed', !notAssessedList.isEmpty());
	reportMap.put('showNotApplicable', !notApplicableList.isEmpty());


    output.put('tokenMap', reportMap);
    System.debug('jsonoutput*'+JSON.serializePretty(reportMap));
        success = true;
        return  success;
        
    }
    
    private static String buildAddress(Account acc) {
        List<String> parts = new List<String>();
        if (String.isNotBlank(acc.Physical_Address__Street__s)) parts.add(acc.Physical_Address__Street__s);
        if (String.isNotBlank(acc.Physical_Address__City__s)) parts.add(acc.Physical_Address__City__s);
        if (String.isNotBlank(acc.Physical_Address__StateCode__s)) parts.add(acc.Physical_Address__StateCode__s);
        if (String.isNotBlank(acc.Physical_Address__PostalCode__s)) parts.add(acc.Physical_Address__PostalCode__s);
        return String.join(parts, ', ');
    }
	private void addToGroupedCategory(
    Map<String, List<Object>> grouping,
    String category,
    Map<String, Object> item
) {
    if (String.isBlank(category)) {
        category = 'Uncategorized';
    }

    if (!grouping.containsKey(category)) {
        grouping.put(category, new List<Object>());
    }

    grouping.get(category).add(item);
}

private List<Object> buildCategoryList(Map<String, List<Object>> source) {

    List<Object> outerList = new List<Object>();

    if (source == null || source.isEmpty()) {
        return outerList;
    }

    for (String key : source.keySet()) {

        Map<String, Object> categoryWrapper = new Map<String, Object>();
        categoryWrapper.put('categoryName', key);
        categoryWrapper.put('questions', source.get(key));

        outerList.add(categoryWrapper);
    }

    return outerList;
}




    global class Report {
        global Header header;
        global  List<Object> criticalInfractions = new  List<Object>();
        global  List<Object> nonCriticalInfractions = new  List<Object>();
        global  List<Object> inCompliance = new  List<Object>();
        global  List<Object> notAssessed = new  List<Object>();
        global  List<Object> notApplicable = new  List<Object>();
    }

    global class Header {
        global String inspector;
        global String dairyPlant;
        global String address;
        global Date inspectionDate;
        global String inspectionType;
        global String timeSpentMinutes;
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