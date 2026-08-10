/**********************************************************************************************
* @Author:      Accenture
* @Date:        06 Aug 2026
* @Description: Test class for PHOCSRiskAssessmentScoringService.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
                06 Aug -  PHOCS-269         -  Accenture   -  test class for RAT remote action
***********************************************************************************************/
@isTest
public class PHOCSRiskAssessmentScoringServiceTest {
    public static final String ACTION_CALCULATE_SCORE = 'calculateScore';

/**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Covers call() when an unsupported action is passed in.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testCall_UnsupportedAction_ThrowsException() {
        PHOCSRiskAssessmentScoringService service = new PHOCSRiskAssessmentScoringService();
        Map<String, Object> args = buildArgs(new Map<String, Object>{ 'facilityType' => 'Personal Services', 'jsonInput' => '{}' });
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            service.call('unknownAction', args);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.areEqual('Unsupported action: unknownAction', e.getMessage(), 'Exception message should identify the unsupported action');
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Expected an AuraHandledException for an unsupported action');
    }

/**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Covers calculateScore() when facilityType is missing from the input.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testCalculateScore_MissingFacilityType_ThrowsException() {
        PHOCSRiskAssessmentScoringService service = new PHOCSRiskAssessmentScoringService();
        Map<String, Object> args = buildArgs(new Map<String, Object>{ 'jsonInput' => '{"Q1":"answer"}' });
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            service.call(ACTION_CALCULATE_SCORE, args);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.areEqual('facilityType is required.', e.getMessage(), 'Exception message should flag the missing facilityType');
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Expected an AuraHandledException for a missing facilityType');
    }

/**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Covers calculateScore() when jsonInput is a blank string.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testCalculateScore_BlankJsonInputString_ThrowsException() {
        PHOCSRiskAssessmentScoringService service = new PHOCSRiskAssessmentScoringService();
        Map<String, Object> args = buildArgs(new Map<String, Object>{ 'facilityType' => 'Personal Services', 'jsonInput' => '   ' });
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            service.call(ACTION_CALCULATE_SCORE, args);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.areEqual('jsonInput is required.', e.getMessage(), 'Exception message should flag the blank jsonInput');
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Expected an AuraHandledException for a blank jsonInput string');
    }

/**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Covers calculateScore() when jsonInput is an empty map.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testCalculateScore_EmptyJsonInputMap_ThrowsException() {
        PHOCSRiskAssessmentScoringService service = new PHOCSRiskAssessmentScoringService();
        Map<String, Object> args = buildArgs(new Map<String, Object>{ 'facilityType' => 'Personal Services', 'jsonInput' => new Map<String, Object>() });
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            service.call(ACTION_CALCULATE_SCORE, args);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.areEqual('jsonInput is required.', e.getMessage(), 'Exception message should flag the empty jsonInput map');
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Expected an AuraHandledException for an empty jsonInput map');
    }

/**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Covers calculateScore() when jsonInput is neither a String nor a Map.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testCalculateScore_InvalidJsonInputType_ThrowsException() {
        PHOCSRiskAssessmentScoringService service = new PHOCSRiskAssessmentScoringService();
        Map<String, Object> args = buildArgs(new Map<String, Object>{ 'facilityType' => 'Personal Services', 'jsonInput' => 12345 });
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            service.call(ACTION_CALCULATE_SCORE, args);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.areEqual('jsonInput must be a JSON string or a map.', e.getMessage(), 'Exception message should flag the unsupported jsonInput type');
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Expected an AuraHandledException for an unsupported jsonInput type');
    }

/**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Covers calculateScore() when the facilityType has no matching Score or Rating metadata.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testCalculateScore_NoMatchingMetadata_ReturnsZeroScoreAndNullRating() {
        PHOCSRiskAssessmentScoringService service = new PHOCSRiskAssessmentScoringService();
        Map<String, Object> input = new Map<String, Object>{
            'facilityType' => 'PHOCSTest_NonExistent_ProgramArea',
            'jsonInput' => '{"PSE_RiskAssessment_Q1":"Some answer with no metadata match"}'
        };
        Map<String, Object> args = buildArgs(input);

        Test.startTest();
        Map<String, Object> result = (Map<String, Object>) service.call(ACTION_CALCULATE_SCORE, args);
        Test.stopTest();

        Assert.areEqual(0, (Decimal) result.get('totalScore'), 'Total score should be zero when no Score metadata matches the program area');
        Assert.areEqual(null, result.get('riskRating'), 'Risk rating should be null when no Rating metadata matches the program area');
    }

/**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Covers calculateScore() end to end with jsonInput passed as a JSON string,
*               validated dynamically against whatever PHOCSRiskAssessmentScoring__mdt records
*               already exist for a given program area.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testCalculateScore_WithJsonStringInput_ReturnsExpectedScoreAndRating() {
        runScoreAndRatingAssertion(true, false);
    }

/**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Covers calculateScore() end to end with jsonInput passed as a native Map,
*               validated dynamically against whatever PHOCSRiskAssessmentScoring__mdt records
*               already exist for a given program area.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testCalculateScore_WithMapInput_ReturnsExpectedScoreAndRating() {
        runScoreAndRatingAssertion(false, false);
    }

/**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Covers calculateScore() case-insensitive matching by lower-casing the answer
*               text before submission and confirming the score is unaffected.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testCalculateScore_CaseInsensitiveMatching_ReturnsSameScore() {
        runScoreAndRatingAssertion(true, true);
    }

/**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Builds the calculateScore output dynamically from whatever
* PHOCSRiskAssessmentScoring__mdt records already exist in the org, then verifies
* the service returns a matching totalScore and riskRating. Custom metadata records
* cannot be inserted via DML in a test context, so this validates against deployed
* metadata rather than fabricated test data. If no metadata is deployed yet, the
* assertions are skipped rather than failed. GROUP BY is not supported on custom
* metadata type objects, so the program area is resolved from a plain query instead.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static void runScoreAndRatingAssertion(Boolean asJsonString, Boolean lowerCaseResponses) {
        List<PHOCSRiskAssessmentScoring__mdt> anyScoreRecords = [SELECT ProgramArea__c FROM PHOCSRiskAssessmentScoring__mdt WHERE AssessmentType__c = 'Score' LIMIT 1];
        if (anyScoreRecords.isEmpty()) {
            return;
        }
        String programArea = anyScoreRecords[0].ProgramArea__c;

        List<PHOCSRiskAssessmentScoring__mdt> scoreRecords = [SELECT QuestionAPIName__c, ResponseValue__c, Score__c FROM PHOCSRiskAssessmentScoring__mdt WHERE ProgramArea__c = :programArea AND AssessmentType__c = 'Score'];
        Map<String, PHOCSRiskAssessmentScoring__mdt> firstRecordByQuestion = new Map<String, PHOCSRiskAssessmentScoring__mdt>();
        for (PHOCSRiskAssessmentScoring__mdt scoreRecord : scoreRecords) {
            if (!firstRecordByQuestion.containsKey(scoreRecord.QuestionAPIName__c)) {
                firstRecordByQuestion.put(scoreRecord.QuestionAPIName__c, scoreRecord);
            }
        }

        Map<String, Object> responses = new Map<String, Object>();
        Decimal expectedTotal = 0;
        for (PHOCSRiskAssessmentScoring__mdt scoreRecord : firstRecordByQuestion.values()) {
            String answerText = lowerCaseResponses ? scoreRecord.ResponseValue__c.toLowerCase() : scoreRecord.ResponseValue__c;
            responses.put(scoreRecord.QuestionAPIName__c, answerText);
            expectedTotal += scoreRecord.Score__c;
        }

        List<PHOCSRiskAssessmentScoring__mdt> ratingRecords = [SELECT ResponseValue__c, LowScore__c, HighScore__c FROM PHOCSRiskAssessmentScoring__mdt WHERE ProgramArea__c = :programArea AND AssessmentType__c = 'Rating'];
        String expectedRating = null;
        for (PHOCSRiskAssessmentScoring__mdt ratingRecord : ratingRecords) {
            Boolean meetsLow = ratingRecord.LowScore__c == null || expectedTotal >= ratingRecord.LowScore__c;
            Boolean meetsHigh = ratingRecord.HighScore__c == null || expectedTotal <= ratingRecord.HighScore__c;
            if (meetsLow && meetsHigh) {
                expectedRating = ratingRecord.ResponseValue__c;
                break;
            }
        }

        Object jsonInputValue = asJsonString ? JSON.serialize(responses) : (Object) responses;
        Map<String, Object> input = new Map<String, Object>{ 'facilityType' => programArea, 'jsonInput' => jsonInputValue };
        Map<String, Object> args = buildArgs(input);

        PHOCSRiskAssessmentScoringService service = new PHOCSRiskAssessmentScoringService();
        Test.startTest();
        Map<String, Object> result = (Map<String, Object>) service.call(ACTION_CALCULATE_SCORE, args);
        Test.stopTest();

        Assert.areEqual(expectedTotal, (Decimal) result.get('totalScore'), 'Total score should equal the sum of matched Score metadata records');
        Assert.areEqual(expectedRating, (String) result.get('riskRating'), 'Risk rating should equal the matched Rating metadata band');
    }

/**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Builds the input/output/options wrapper map expected by call().
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static Map<String, Object> buildArgs(Map<String, Object> input) {
        return new Map<String, Object>{
            'input' => input,
            'output' => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        };
    }
}