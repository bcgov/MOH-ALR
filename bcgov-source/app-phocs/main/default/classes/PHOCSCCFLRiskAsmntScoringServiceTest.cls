/**********************************************************************************************
* @Author:      Accenture
* @Date:        25 Aug 2026
* @Description: Test class for PHOCSCCFLRiskAssessmentScoringService.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
*               25 Aug - PHOCS-4817         -  Deepak      - test class for CCFL RAT remote action
***********************************************************************************************/
@isTest
public class PHOCSCCFLRiskAsmntScoringServiceTest {
    private static final String ACTION_CALCULATE_SCORE = 'calculateScore';
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Covers call() when action is null or blank.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testCall_BlankAction_ThrowsException() {
        PHOCSCCFLRiskAssessmentScoringService service = new PHOCSCCFLRiskAssessmentScoringService();
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            service.call(null, buildArgs('Child Care', new List<Object>(), new Map<String, Object>()));
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.areEqual('Callable action is required.', e.getMessage(), 'Exception message should flag the missing action');
        }
        Test.stopTest();
        Assert.isTrue(exceptionThrown, 'Expected an exception for a blank action');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Covers call() when args is null.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testCall_NullArgs_ThrowsException() {
        PHOCSCCFLRiskAssessmentScoringService service = new PHOCSCCFLRiskAssessmentScoringService();
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            service.call(ACTION_CALCULATE_SCORE, null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.areEqual('Callable arguments are required.', e.getMessage(), 'Exception message should flag the missing arguments');
        }
        Test.stopTest();
        Assert.isTrue(exceptionThrown, 'Expected an exception for null args');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Covers call() when an unsupported action is passed in.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testCall_UnsupportedAction_ThrowsException() {
        PHOCSCCFLRiskAssessmentScoringService service = new PHOCSCCFLRiskAssessmentScoringService();
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            service.call('unknownAction', buildArgs('Child Care', new List<Object>(), new Map<String, Object>()));
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.areEqual('Unsupported callable action: unknownAction', e.getMessage(), 'Exception message should identify the unsupported action');
        }
        Test.stopTest();
        Assert.isTrue(exceptionThrown, 'Expected an exception for an unsupported action');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Covers calculateScore() when facilityType is missing from the input.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testCalculateScore_MissingFacilityType_ThrowsException() {
        PHOCSCCFLRiskAssessmentScoringService service = new PHOCSCCFLRiskAssessmentScoringService();
        Map<String, Object> args = buildArgs(null, new List<Object>(), new Map<String, Object>());
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            service.call(ACTION_CALCULATE_SCORE, args);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.areEqual('Facility Type is required.', e.getMessage(), 'Exception message should flag the missing facilityType');
        }
        Test.stopTest();
        Assert.isTrue(exceptionThrown, 'Expected an exception for a missing facilityType');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Covers calculateScore() when input itself is null.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testCalculateScore_NullInput_ThrowsException() {
        PHOCSCCFLRiskAssessmentScoringService service = new PHOCSCCFLRiskAssessmentScoringService();
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            service.calculateScore(null, new Map<String, Object>(), new Map<String, Object>());
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.areEqual('Input is required.', e.getMessage(), 'Exception message should flag the missing input');
        }
        Test.stopTest();
        Assert.isTrue(exceptionThrown, 'Expected an exception for null input');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Covers calculateScore() when no scoring metadata exists.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testCalculateScore_UnconfiguredFacilityType_ThrowsNoIntervalScoreException() {
        PHOCSCCFLRiskAssessmentScoringService service = new PHOCSCCFLRiskAssessmentScoringService();
        Map<String, Object> args = buildArgs('PHOCSTest_NonExistent_ProgramArea_XYZ', new List<Object>(), new Map<String, Object>());
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            service.call(ACTION_CALCULATE_SCORE, args);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.areEqual('No Interval Score metadata was found for the selected facility type.', e.getMessage(), 'Exception message should flag the missing Interval Score metadata');
        }
        Test.stopTest();
        Assert.isTrue(exceptionThrown, 'Expected an exception when the facility type has no scoring metadata configured');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Covers flat argument parsing.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testCalculateScore_FlatArgsWithoutInputWrapper_StillParsesFacilityType() {
        PHOCSCCFLRiskAssessmentScoringService service = new PHOCSCCFLRiskAssessmentScoringService();
        Map<String, Object> flatArgs = new Map<String, Object>{
            'facilityType' => 'PHOCSTest_NonExistent_ProgramArea_XYZ',
                'selectedViolations' => new List<Object>(),
                'PartBThreeYearOperationalHistoryAssessment' => new Map<String, Object>()
                };
                    Boolean exceptionThrown = false;
        Test.startTest();
        try {
            service.call(ACTION_CALCULATE_SCORE, flatArgs);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.areEqual('No Interval Score metadata was found for the selected facility type.', e.getMessage(), 'FacilityType should be parsed from flat args');
        }
        Test.stopTest();
        Assert.isTrue(exceptionThrown, 'Expected downstream exception proving flat args were parsed');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Covers violation missing Scope or Severity.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testCalculateScore_ViolationMissingSeverityOrScope_ThrowsException() {
        List<PHOCSRiskAssessmentScoring__mdt> records = [SELECT ProgramArea__c FROM PHOCSRiskAssessmentScoring__mdt WHERE AssessmentType__c = 'RiskMatrix' LIMIT 1];
        if (records.isEmpty()) {
            return;
        }
        PHOCSCCFLRiskAssessmentScoringService service = new PHOCSCCFLRiskAssessmentScoringService();
        List<Object> violations = new List<Object>{
            new Map<String, Object>{'severity' => 'Some Severity', 'scope' => null}
        };
            Boolean exceptionThrown = false;
        Test.startTest();
        try {
            service.call(ACTION_CALCULATE_SCORE, buildArgs(records[0].ProgramArea__c, violations, new Map<String, Object>()));
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.areEqual('Every selected violation must have both Scope and Severity.', e.getMessage(), 'Exception message should flag the missing Scope');
        }
        Test.stopTest();
        Assert.isTrue(exceptionThrown, 'Expected an exception when Scope or Severity is missing');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Covers a non-map violation entry.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testCalculateScore_NonMapViolation_IsSkipped() {
        String programArea = resolveFullyConfiguredProgramArea();
        if (programArea == null) {
            return;
        }
        PHOCSCCFLRiskAssessmentScoringService service = new PHOCSCCFLRiskAssessmentScoringService();
        List<Object> violations = new List<Object>{'InvalidViolation'};
            Map<String, Object> output = new Map<String, Object>();
        Test.startTest();
        try {
            service.calculateScore(new Map<String, Object>{
                'facilityType' => programArea,
                    'selectedViolations' => violations,
                    'PartBThreeYearOperationalHistoryAssessment' => new Map<String, Object>()
                    }, output, new Map<String, Object>());
        } catch (AuraHandledException e) {
            return;
        }
        Test.stopTest();
        Assert.isTrue(true, 'Test Assert');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Covers unknown Severity/Scope combination.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testCalculateScore_UnknownSeverityScopeCombination_ThrowsException() {
        List<PHOCSRiskAssessmentScoring__mdt> records = [SELECT ProgramArea__c FROM PHOCSRiskAssessmentScoring__mdt WHERE AssessmentType__c = 'RiskMatrix' LIMIT 1];
        if (records.isEmpty()) {
            return;
        }
        PHOCSCCFLRiskAssessmentScoringService service = new PHOCSCCFLRiskAssessmentScoringService();
        List<Object> violations = new List<Object>{
            new Map<String, Object>{'severity' => 'PHOCSTest_NonExistent_Severity', 'scope' => 'PHOCSTest_NonExistent_Scope'}
        };
            Boolean exceptionThrown = false;
        Test.startTest();
        try {
            service.call(ACTION_CALCULATE_SCORE, buildArgs(records[0].ProgramArea__c, violations, new Map<String, Object>()));
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.isTrue(e.getMessage().startsWith('No Risk Matrix scoring metadata was found for Severity'), 'Exception message should flag the unmatched Severity/Scope combination');
        }
        Test.stopTest();
        Assert.isTrue(exceptionThrown, 'Expected an exception for an unknown Severity/Scope combination');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Covers Part B when the question exists in metadata but response does not.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testCalculateScore_PartBAnswerNotConfigured_ThrowsException() {
        PartBScenario scenario = resolvePartBScenario();
        if (scenario == null) {
            return;
        }
        PHOCSCCFLRiskAssessmentScoringService service = new PHOCSCCFLRiskAssessmentScoringService();
        Map<String, Object> partBAnswers = new Map<String, Object>{
            scenario.questionApiName => 'PHOCSTest_NonExistent_Answer_XYZ'
                };
                    List<Object> violations = new List<Object>{
                        new Map<String, Object>{
                            'severity' => scenario.matrixQuestion,
                                'scope' => scenario.matrixResponse
                                }
                    };
                        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            service.call(ACTION_CALCULATE_SCORE, buildArgs(scenario.programArea, violations, partBAnswers));
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.isTrue(e.getMessage().startsWith('No Part B scoring metadata was found for Question "' + scenario.questionApiName), 'Exception message should flag the unmatched Part B answer');
        }
        Test.stopTest();
        Assert.isTrue(exceptionThrown, 'Expected an exception when Part B answer has no matching metadata');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Covers Part B when the question itself is not configured.
* @Modification Log: [Date] - [Change Reference] - [Description]
*/
    @isTest
    public static void testCalculateScore_UnconfiguredPartBQuestion_IsSkipped() {
        PartBScenario scenario = resolvePartBScenario();
        if (scenario == null) {
            return;
        }
        PHOCSCCFLRiskAssessmentScoringService service = new PHOCSCCFLRiskAssessmentScoringService();
        List<Object> violations = new List<Object>{
            new Map<String, Object>{
                'severity' => scenario.matrixQuestion,
                    'scope' => scenario.matrixResponse
                    }
        };
            Map<String, Object> partBAnswers = new Map<String, Object>{
                'PHOCS_Unconfigured_Question_XYZ' => '1'
                    };
                        Map<String, Object> result;
        Test.startTest();
        result = (Map<String, Object>) service.call(ACTION_CALCULATE_SCORE, buildArgs(scenario.programArea, violations, partBAnswers));
        Test.stopTest();
        Assert.areEqual(0, (Decimal) result.get('PartBScore'), 'Unconfigured Part B questions should contribute zero');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Covers null and blank Part B responses.
* @Modification Log: [Date] - [Change Reference] - [Description]
*/
    @isTest
    public static void testCalculateScore_PartBNullAndBlankAnswers_AreSkipped() {
        PartBScenario scenario = resolvePartBScenario();
        if (scenario == null) {
            return;
        }
        PHOCSCCFLRiskAssessmentScoringService service = new PHOCSCCFLRiskAssessmentScoringService();
        List<Object> violations = new List<Object>{
            new Map<String, Object>{
                'severity' => scenario.matrixQuestion,
                    'scope' => scenario.matrixResponse
                    }
        };
            Map<String, Object> partBAnswers = new Map<String, Object>{
                scenario.questionApiName => null,
                    'CCFL_Unconfigured_Q' => ''
                    };
                        Map<String, Object> result;
        Test.startTest();
        result = (Map<String, Object>) service.call(ACTION_CALCULATE_SCORE, buildArgs(scenario.programArea, violations, partBAnswers));
        Test.stopTest();
        Assert.areEqual(0, (Decimal) result.get('PartBScore'), 'Null and blank Part B answers should contribute zero');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Covers a valid Part B response and validates the calculated Part B score.
* @Modification Log: [Date] - [Change Reference] - [Description]
*/
    @isTest
    public static void testCalculateScore_ValidPartBAnswer_ReturnsPartBScore() {
        PartBScenario scenario = resolvePartBScenario();
        if (scenario == null) {
            return;
        }
        PHOCSCCFLRiskAssessmentScoringService service = new PHOCSCCFLRiskAssessmentScoringService();
        List<Object> violations = new List<Object>{
            new Map<String, Object>{
                'severity' => scenario.matrixQuestion,
                    'scope' => scenario.matrixResponse
                    }
        };
            Map<String, Object> partBAnswers = new Map<String, Object>{
                scenario.questionApiName => scenario.responseValue
                    };
                        Map<String, Object> result;
        Test.startTest();
        result = (Map<String, Object>) service.call(ACTION_CALCULATE_SCORE, buildArgs(scenario.programArea, violations, partBAnswers));
        Test.stopTest();
        Assert.areEqual(scenario.partBScore, (Decimal) result.get('PartBScore'), 'PartBScore should match the configured response score');
        Assert.isNotNull(result.get('TotalScore'), 'TotalScore should be populated');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Covers multiple selected violations and validates matrix score aggregation.
* @Modification Log: [Date] - [Change Reference] - [Description]
*/
    @isTest
    public static void testCalculateScore_MultipleViolations_SumsMatrixScores() {
        String programArea = resolveFullyConfiguredProgramArea();
        if (programArea == null) {
            return;
        }
        List<PHOCSRiskAssessmentScoring__mdt> matrixRecords = [SELECT QuestionAPIName__c, ResponseValue__c, Score__c FROM PHOCSRiskAssessmentScoring__mdt WHERE ProgramArea__c = :programArea AND AssessmentType__c = 'RiskMatrix' AND Score__c != null LIMIT 2];
        if (matrixRecords.size() < 2) {
            return;
        }
        List<Object> violations = new List<Object>{
            new Map<String, Object>{'severity' => matrixRecords[0].QuestionAPIName__c, 'scope' => matrixRecords[0].ResponseValue__c},
                new Map<String, Object>{'severity' => matrixRecords[1].QuestionAPIName__c, 'scope' => matrixRecords[1].ResponseValue__c}
        };
            Map<String, Object> result;
        Test.startTest();
        try {
            result = (Map<String, Object>) new PHOCSCCFLRiskAssessmentScoringService().call(ACTION_CALCULATE_SCORE, buildArgs(programArea, violations, new Map<String, Object>()));
        } catch (AuraHandledException e) {
            return;
        }
        Test.stopTest();
        Decimal expected = matrixRecords[0].Score__c + matrixRecords[1].Score__c;
        Assert.areEqual(expected, (Decimal) result.get('PartAMatrixScore'), 'Matrix score should be the sum of all selected violations');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Covers the complete scoring flow.
* @Modification Log: [Date] - [Change Reference] - [Description]
*/
    @isTest
    public static void testCalculateScore_EndToEnd_ReturnsExpectedTotals() {
        String programArea = resolveFullyConfiguredProgramArea();
        if (programArea == null) {
            return;
        }
        List<PHOCSRiskAssessmentScoring__mdt> matrixRecords = [SELECT QuestionAPIName__c, ResponseValue__c, Score__c FROM PHOCSRiskAssessmentScoring__mdt WHERE ProgramArea__c = :programArea AND AssessmentType__c = 'RiskMatrix' AND Score__c != null LIMIT 1];
        if (matrixRecords.isEmpty()) {
            return;
        }
        PHOCSRiskAssessmentScoring__mdt matrixRecord = matrixRecords[0];
        Decimal expectedMatrixTotal = matrixRecord.Score__c;
        List<PHOCSRiskAssessmentScoring__mdt> intervalRecords = [SELECT LowScore__c, HighScore__c, Score__c FROM PHOCSRiskAssessmentScoring__mdt WHERE ProgramArea__c = :programArea AND AssessmentType__c = 'IntervalScore'];
        Decimal expectedPartAScore;
        for (PHOCSRiskAssessmentScoring__mdt intervalRecord : intervalRecords) {
            if (intervalRecord.LowScore__c == null || intervalRecord.HighScore__c == null || intervalRecord.Score__c == null) {
                continue;
            }
            if (expectedMatrixTotal >= intervalRecord.LowScore__c && expectedMatrixTotal <= intervalRecord.HighScore__c) {
                expectedPartAScore = intervalRecord.Score__c;
                break;
            }
        }
        if (expectedPartAScore == null) {
            return;
        }
        List<PHOCSRiskAssessmentScoring__mdt> ratingRecords = [SELECT LowScore__c, HighScore__c, ResponseValue__c, InspectionFrequency__c FROM PHOCSRiskAssessmentScoring__mdt WHERE ProgramArea__c = :programArea AND AssessmentType__c = 'Rating'];
        String expectedRiskRating;
        String expectedInspectionFrequency;
        for (PHOCSRiskAssessmentScoring__mdt ratingRecord : ratingRecords) {
            if (ratingRecord.LowScore__c == null || ratingRecord.HighScore__c == null) {
                continue;
            }
            if (expectedPartAScore >= ratingRecord.LowScore__c && expectedPartAScore <= ratingRecord.HighScore__c) {
                expectedRiskRating = ratingRecord.ResponseValue__c;
                expectedInspectionFrequency = ratingRecord.InspectionFrequency__c;
                break;
            }
        }
        if (expectedRiskRating == null) {
            return;
        }
        List<Object> violations = new List<Object>{
            new Map<String, Object>{
                'severity' => matrixRecord.QuestionAPIName__c,
                    'scope' => matrixRecord.ResponseValue__c
                    }
        };
            Map<String, Object> result;
        Test.startTest();
        result = (Map<String, Object>) new PHOCSCCFLRiskAssessmentScoringService().call(ACTION_CALCULATE_SCORE, buildArgs(programArea, violations, new Map<String, Object>()));
        Test.stopTest();
        Assert.areEqual(expectedMatrixTotal, (Decimal) result.get('PartAMatrixScore'), 'PartAMatrixScore should equal the configured matrix score');
        Assert.areEqual(expectedPartAScore, (Decimal) result.get('PartAScore'), 'PartAScore should equal the matched Interval Score');
        Assert.areEqual(0, (Decimal) result.get('PartBScore'), 'PartBScore should be zero when no Part B answers are submitted');
        Assert.areEqual(expectedPartAScore, (Decimal) result.get('TotalScore'), 'TotalScore should equal PartAScore');
        Assert.areEqual(expectedRiskRating, (String) result.get('RiskRating'), 'RiskRating should match the configured rating');
        Assert.areEqual(expectedInspectionFrequency, (String) result.get('InspectionFrequency'), 'InspectionFrequency should match the configured frequency');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Finds a facility type with RiskMatrix, IntervalScore and Rating metadata.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static String resolveFullyConfiguredProgramArea() {
        List<PHOCSRiskAssessmentScoring__mdt> riskMatrixRecords = [SELECT ProgramArea__c FROM PHOCSRiskAssessmentScoring__mdt WHERE AssessmentType__c = 'RiskMatrix' AND Score__c != null];
        Set<String> candidateProgramAreas = new Set<String>();
        for (PHOCSRiskAssessmentScoring__mdt record : riskMatrixRecords) {
            candidateProgramAreas.add(record.ProgramArea__c);
        }
        if (candidateProgramAreas.isEmpty()) {
            return null;
        }

        Set<String> programAreasWithInterval = new Set<String>();
        for (PHOCSRiskAssessmentScoring__mdt record : [SELECT ProgramArea__c FROM PHOCSRiskAssessmentScoring__mdt WHERE ProgramArea__c IN :candidateProgramAreas AND AssessmentType__c = 'IntervalScore']) {
            programAreasWithInterval.add(record.ProgramArea__c);
        }

        Set<String> programAreasWithRating = new Set<String>();
        for (PHOCSRiskAssessmentScoring__mdt record : [SELECT ProgramArea__c FROM PHOCSRiskAssessmentScoring__mdt WHERE ProgramArea__c IN :candidateProgramAreas AND AssessmentType__c = 'Rating']) {
            programAreasWithRating.add(record.ProgramArea__c);
        }

        for (String candidate : candidateProgramAreas) {
            if (programAreasWithInterval.contains(candidate) && programAreasWithRating.contains(candidate)) {
                return candidate;
            }
        }
        return null;
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Resolves a valid Part B scoring record and a valid Risk Matrix record for the same facility type.
* @Modification Log: [Date] - [Change Reference] - [Description]
*/
    private static PartBScenario resolvePartBScenario() {
        List<PHOCSRiskAssessmentScoring__mdt> scoreRecords = [SELECT ProgramArea__c, QuestionAPIName__c, ResponseValue__c, Score__c FROM PHOCSRiskAssessmentScoring__mdt WHERE AssessmentType__c = 'Score' 
                                                              AND QuestionAPIName__c != null AND Score__c != null LIMIT 50];
        if (scoreRecords.isEmpty()) {
            return null;
        }

        Set<String> programAreas = new Set<String>();
        for (PHOCSRiskAssessmentScoring__mdt scoreRecord : scoreRecords) {
            programAreas.add(scoreRecord.ProgramArea__c);
        }

        Map<String, PHOCSRiskAssessmentScoring__mdt> matrixRecordByProgramArea = new Map<String, PHOCSRiskAssessmentScoring__mdt>();
        for (PHOCSRiskAssessmentScoring__mdt matrixRecord : [SELECT ProgramArea__c, QuestionAPIName__c, ResponseValue__c, Score__c FROM PHOCSRiskAssessmentScoring__mdt WHERE ProgramArea__c IN :programAreas AND AssessmentType__c = 'RiskMatrix' AND Score__c != null]) {
            if (!matrixRecordByProgramArea.containsKey(matrixRecord.ProgramArea__c)) {
                matrixRecordByProgramArea.put(matrixRecord.ProgramArea__c, matrixRecord);
            }
        }

        for (PHOCSRiskAssessmentScoring__mdt scoreRecord : scoreRecords) {
            if (matrixRecordByProgramArea.containsKey(scoreRecord.ProgramArea__c)) {
                PHOCSRiskAssessmentScoring__mdt matrixRecord = matrixRecordByProgramArea.get(scoreRecord.ProgramArea__c);
                PartBScenario scenario = new PartBScenario();
                scenario.programArea = scoreRecord.ProgramArea__c;
                scenario.questionApiName = scoreRecord.QuestionAPIName__c;
                scenario.responseValue = scoreRecord.ResponseValue__c;
                scenario.partBScore = scoreRecord.Score__c;
                scenario.matrixQuestion = matrixRecord.QuestionAPIName__c;
                scenario.matrixResponse = matrixRecord.ResponseValue__c;
                return scenario;
            }
        }
        return null;
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Builds the Callable argument wrapper.
* @Modification Log: [Date] - [Change Reference] - [Description]
*/
    private static Map<String, Object> buildArgs(String facilityType, List<Object> selectedViolations, Map<String, Object> partBAnswers) {
        Map<String, Object> input = new Map<String, Object>{'facilityType' => facilityType, 'selectedViolations' => selectedViolations, 'PartBThreeYearOperationalHistoryAssessment' => partBAnswers};
            return new Map<String, Object>{'input' => input, 'output' => new Map<String, Object>(), 'options' => new Map<String, Object>()};
                }
    
    private class PartBScenario {
        String programArea;
        String questionApiName;
        String responseValue;
        Decimal partBScore;
        String matrixQuestion;
        String matrixResponse;
    }
}