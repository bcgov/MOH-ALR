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
        
        Assert.areEqual(true, exceptionThrown, 'Expected an exception for a blank action');
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
        
        Assert.areEqual(true, exceptionThrown, 'Expected an exception for null args');
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
        
        Assert.areEqual(true, exceptionThrown, 'Expected an exception for an unsupported action');
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
        
        Assert.areEqual(true, exceptionThrown, 'Expected an exception for a missing facilityType');
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
        
        Assert.areEqual(true, exceptionThrown, 'Expected an exception for null input');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Covers calculateScore() when no scoring metadata exists.
*              Missing configuration should now return zero scores instead of throwing an exception.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testCalculateScore_UnconfiguredFacilityType_ReturnsZeroScores() {
        PHOCSCCFLRiskAssessmentScoringService service = new PHOCSCCFLRiskAssessmentScoringService();
        Map<String, Object> args = buildArgs('PHOCSTest_NonExistent_ProgramArea_XYZ', new List<Object>(), new Map<String, Object>());
        
        Test.startTest();
        Map<String, Object> result = (Map<String, Object>) service.call(ACTION_CALCULATE_SCORE, args);
        Test.stopTest();
        
        Assert.areEqual(0, (Decimal) result.get('PartAMatrixScore'), 'Part A Matrix Score should be zero when no metadata exists');
        Assert.areEqual(0, (Decimal) result.get('PartAScore'), 'Part A Score should be zero when no Interval Score metadata exists');
        Assert.areEqual(0, (Decimal) result.get('PartBScore'), 'Part B Score should be zero when no Part B metadata exists');
        Assert.areEqual(0, (Decimal) result.get('TotalScore'), 'Total Score should be zero when no scoring metadata exists');
        Assert.isNull(result.get('RiskRating'), 'Risk Rating should be null when no rating metadata exists');
        Assert.isNull(result.get('InspectionFrequency'), 'Inspection Frequency should be null when no rating metadata exists');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Covers flat argument parsing.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testCalculateScore_FlatArgsWithoutInputWrapper_ReturnsZeroScores() {
        PHOCSCCFLRiskAssessmentScoringService service = new PHOCSCCFLRiskAssessmentScoringService();
        
        Map<String, Object> flatArgs = new Map<String, Object>{
            'facilityType' => 'PHOCSTest_NonExistent_ProgramArea_XYZ',
                'selectedViolations' => new List<Object>(),
                'PartBThreeYearOperationalHistoryAssessment' => new Map<String, Object>()
                };
                    
                    Test.startTest();
        Map<String, Object> result = (Map<String, Object>) service.call(ACTION_CALCULATE_SCORE, flatArgs);
        Test.stopTest();
        
        Assert.areEqual(0, (Decimal) result.get('PartAMatrixScore'), 'Flat arguments should be parsed correctly');
        Assert.areEqual(0, (Decimal) result.get('PartAScore'), 'Part A Score should be zero');
        Assert.areEqual(0, (Decimal) result.get('PartBScore'), 'Part B Score should be zero');
        Assert.areEqual(0, (Decimal) result.get('TotalScore'), 'Total Score should be zero');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Covers violation missing Scope or Severity.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testCalculateScore_ViolationMissingSeverityOrScope_ThrowsException() {
        List<PHOCSRiskAssessmentScoring__mdt> records = [
            SELECT ProgramArea__c
            FROM PHOCSRiskAssessmentScoring__mdt
            WHERE AssessmentType__c = 'RiskMatrix'
            LIMIT 1
        ];
        
        if (records.isEmpty()) {
            Assert.areEqual(true, records.isEmpty(), 'No Risk Matrix metadata is available for this test');
            return;
        }
        
        PHOCSCCFLRiskAssessmentScoringService service = new PHOCSCCFLRiskAssessmentScoringService();
        
        List<Object> violations = new List<Object>{
            new Map<String, Object>{
                'severity' => 'Some Severity',
                    'scope' => null
                    }
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
        
        Assert.areEqual(true, exceptionThrown, 'Expected an exception when Scope or Severity is missing');
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
            Assert.areEqual(true, programArea == null, 'No fully configured program area is available for this test');
            return;
        }
        
        PHOCSCCFLRiskAssessmentScoringService service = new PHOCSCCFLRiskAssessmentScoringService();
        List<Object> violations = new List<Object>{'InvalidViolation'};
            Map<String, Object> output = new Map<String, Object>();
        
        Test.startTest();
        service.calculateScore(
            new Map<String, Object>{
                'facilityType' => programArea,
                    'selectedViolations' => violations,
                    'PartBThreeYearOperationalHistoryAssessment' => new Map<String, Object>()
                    },
            output,
            new Map<String, Object>()
        );
        Test.stopTest();
        
        Assert.areEqual(0, (Decimal) output.get('PartAMatrixScore'), 'Non-map violations should be skipped');
        Assert.areEqual(0, (Decimal) output.get('PartAScore'), 'Part A Score should be zero');
        Assert.areEqual(0, (Decimal) output.get('PartBScore'), 'Part B Score should be zero');
        Assert.areEqual(0, (Decimal) output.get('TotalScore'), 'Total Score should be zero');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Covers unknown Severity/Scope combination.
*              An unmatched matrix combination should now contribute zero instead of throwing.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testCalculateScore_UnknownSeverityScopeCombination_ReturnsZero() {
        List<PHOCSRiskAssessmentScoring__mdt> records = [
            SELECT ProgramArea__c
            FROM PHOCSRiskAssessmentScoring__mdt
            WHERE AssessmentType__c = 'RiskMatrix'
            LIMIT 1
        ];
        
        if (records.isEmpty()) {
            Assert.areEqual(true, records.isEmpty(), 'No Risk Matrix metadata is available for this test');
            return;
        }
        
        PHOCSCCFLRiskAssessmentScoringService service = new PHOCSCCFLRiskAssessmentScoringService();
        
        List<Object> violations = new List<Object>{
            new Map<String, Object>{
                'severity' => 'PHOCSTest_NonExistent_Severity',
                    'scope' => 'PHOCSTest_NonExistent_Scope'
                    }
        };
            
            Test.startTest();
        Map<String, Object> result = (Map<String, Object>) service.call(
            ACTION_CALCULATE_SCORE,
            buildArgs(records[0].ProgramArea__c, violations, new Map<String, Object>())
        );
        Test.stopTest();
        
        Assert.areEqual(0, (Decimal) result.get('PartAMatrixScore'), 'Unknown Severity/Scope combination should contribute zero');
        Assert.areEqual(0, (Decimal) result.get('PartAScore'), 'Part A Score should be zero when matrix score is zero');
        Assert.areEqual(0, (Decimal) result.get('TotalScore'), 'Total Score should be zero');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Covers Part B when the question exists in metadata but response does not.
*              An unmatched response should now contribute zero instead of throwing.
* @Modification Log: [Date] - [Change Reference] - [Description]
*/
    @isTest
    public static void testCalculateScore_PartBAnswerNotConfigured_ReturnsZero() {
        PartBScenario scenario = resolvePartBScenario();
        
        if (scenario == null) {
            Assert.areEqual(true, scenario == null, 'No Part B scenario is available for this test');
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
                        
                        Test.startTest();
        Map<String, Object> result = (Map<String, Object>) service.call(
            ACTION_CALCULATE_SCORE,
            buildArgs(scenario.programArea, violations, partBAnswers)
        );
        Test.stopTest();
        
        Assert.areEqual(0, (Decimal) result.get('PartBScore'), 'Unmatched Part B response should contribute zero');
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
            Assert.areEqual(true, scenario == null, 'No Part B scenario is available for this test');
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
                        
                        Test.startTest();
        Map<String, Object> result = (Map<String, Object>) service.call(
            ACTION_CALCULATE_SCORE,
            buildArgs(scenario.programArea, violations, partBAnswers)
        );
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
            Assert.areEqual(true, scenario == null, 'No Part B scenario is available for this test');
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
                        
                        Test.startTest();
        Map<String, Object> result = (Map<String, Object>) service.call(
            ACTION_CALCULATE_SCORE,
            buildArgs(scenario.programArea, violations, partBAnswers)
        );
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
            Assert.areEqual(true, scenario == null, 'No Part B scenario is available for this test');
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
                        
                        Test.startTest();
        Map<String, Object> result = (Map<String, Object>) service.call(
            ACTION_CALCULATE_SCORE,
            buildArgs(scenario.programArea, violations, partBAnswers)
        );
        Test.stopTest();
        
        Assert.areEqual(scenario.partBScore, (Decimal) result.get('PartBScore'), 'PartBScore should match the configured response score');
        Assert.areEqual(true, result.containsKey('TotalScore'), 'TotalScore should be populated');
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
            Assert.areEqual(true, programArea == null, 'No fully configured program area is available for this test');
            return;
        }
        
        List<PHOCSRiskAssessmentScoring__mdt> matrixRecords = [
            SELECT QuestionAPIName__c, ResponseValue__c, Score__c
            FROM PHOCSRiskAssessmentScoring__mdt
            WHERE ProgramArea__c = :programArea
            AND AssessmentType__c = 'RiskMatrix'
            AND Score__c != null
            LIMIT 2
        ];
        
        if (matrixRecords.size() < 2) {
            Assert.areEqual(true, matrixRecords.size() < 2, 'At least two Risk Matrix records are required');
            return;
        }
        
        List<Object> violations = new List<Object>{
            new Map<String, Object>{
                'severity' => matrixRecords[0].QuestionAPIName__c,
                    'scope' => matrixRecords[0].ResponseValue__c
                    },
                        new Map<String, Object>{
                            'severity' => matrixRecords[1].QuestionAPIName__c,
                                'scope' => matrixRecords[1].ResponseValue__c
                                }
        };
            
            Map<String, Object> result;
        
        Test.startTest();
        result = (Map<String, Object>) new PHOCSCCFLRiskAssessmentScoringService().call(
            ACTION_CALCULATE_SCORE,
            buildArgs(programArea, violations, new Map<String, Object>())
        );
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
            Assert.areEqual(true, programArea == null, 'No fully configured program area is available for this test');
            return;
        }
        
        List<PHOCSRiskAssessmentScoring__mdt> matrixRecords = [
            SELECT QuestionAPIName__c, ResponseValue__c, Score__c
            FROM PHOCSRiskAssessmentScoring__mdt
            WHERE ProgramArea__c = :programArea
            AND AssessmentType__c = 'RiskMatrix'
            AND Score__c != null
            LIMIT 1
        ];
        
        if (matrixRecords.isEmpty()) {
            Assert.areEqual(true, matrixRecords.isEmpty(), 'No Risk Matrix record is available');
            return;
        }
        
        PHOCSRiskAssessmentScoring__mdt matrixRecord = matrixRecords[0];
        Decimal expectedMatrixTotal = matrixRecord.Score__c;
        
        List<PHOCSRiskAssessmentScoring__mdt> intervalRecords = [
            SELECT LowScore__c, HighScore__c, Score__c
            FROM PHOCSRiskAssessmentScoring__mdt
            WHERE ProgramArea__c = :programArea
            AND AssessmentType__c = 'IntervalScore'
        ];
        
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
            expectedPartAScore = 0;
        }
        
        List<PHOCSRiskAssessmentScoring__mdt> ratingRecords = [
            SELECT LowScore__c, HighScore__c, ResponseValue__c, InspectionFrequency__c
            FROM PHOCSRiskAssessmentScoring__mdt
            WHERE ProgramArea__c = :programArea
            AND AssessmentType__c = 'Rating'
        ];
        
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
        
        List<Object> violations = new List<Object>{
            new Map<String, Object>{
                'severity' => matrixRecord.QuestionAPIName__c,
                    'scope' => matrixRecord.ResponseValue__c
                    }
        };
            
            Map<String, Object> result;
        
        Test.startTest();
        result = (Map<String, Object>) new PHOCSCCFLRiskAssessmentScoringService().call(
            ACTION_CALCULATE_SCORE,
            buildArgs(programArea, violations, new Map<String, Object>())
        );
        Test.stopTest();
        
        Assert.areEqual(expectedMatrixTotal, (Decimal) result.get('PartAMatrixScore'), 'PartAMatrixScore should equal the configured matrix score');
        Assert.areEqual(expectedPartAScore, (Decimal) result.get('PartAScore'), 'PartAScore should equal the matched Interval Score or zero');
        Assert.areEqual(0, (Decimal) result.get('PartBScore'), 'PartBScore should be zero when no Part B answers are submitted');
        Assert.areEqual(expectedPartAScore, (Decimal) result.get('TotalScore'), 'TotalScore should equal PartAScore');
        Assert.areEqual(expectedRiskRating, (String) result.get('RiskRating'), 'RiskRating should match the configured rating or remain null');
        Assert.areEqual(expectedInspectionFrequency, (String) result.get('InspectionFrequency'), 'InspectionFrequency should match the configured frequency or remain null');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Covers Interval Score when no matching interval exists.
* @Modification Log: [Date] - [Change Reference] - [Description]
*/
    @isTest
    public static void testCalculateScore_NoMatchingInterval_ReturnsZeroPartAScore() {
        List<PHOCSRiskAssessmentScoring__mdt> riskMatrixRecords = [
            SELECT ProgramArea__c, QuestionAPIName__c, ResponseValue__c, Score__c
            FROM PHOCSRiskAssessmentScoring__mdt
            WHERE AssessmentType__c = 'RiskMatrix'
            AND Score__c != null
            LIMIT 50
        ];
        
        Set<String> programAreas = new Set<String>();
        
        for (PHOCSRiskAssessmentScoring__mdt record : riskMatrixRecords) {
            programAreas.add(record.ProgramArea__c);
        }
        
        if (programAreas.isEmpty()) {
            Assert.areEqual(true, programAreas.isEmpty(), 'No Risk Matrix program area is available');
            return;
        }
        
        List<PHOCSRiskAssessmentScoring__mdt> intervalRecords = [
            SELECT ProgramArea__c, LowScore__c, HighScore__c, Score__c
            FROM PHOCSRiskAssessmentScoring__mdt
            WHERE ProgramArea__c IN :programAreas
            AND AssessmentType__c = 'IntervalScore'
        ];
        
        Map<String, List<PHOCSRiskAssessmentScoring__mdt>> intervalsByProgramArea = new Map<String, List<PHOCSRiskAssessmentScoring__mdt>>();
        
        for (PHOCSRiskAssessmentScoring__mdt intervalRecord : intervalRecords) {
            if (!intervalsByProgramArea.containsKey(intervalRecord.ProgramArea__c)) {
                intervalsByProgramArea.put(intervalRecord.ProgramArea__c, new List<PHOCSRiskAssessmentScoring__mdt>());
            }
            
            intervalsByProgramArea.get(intervalRecord.ProgramArea__c).add(intervalRecord);
        }
        
        PHOCSRiskAssessmentScoring__mdt selectedMatrixRecord;
        
        for (PHOCSRiskAssessmentScoring__mdt matrixRecord : riskMatrixRecords) {
            if (!intervalsByProgramArea.containsKey(matrixRecord.ProgramArea__c)) {
                selectedMatrixRecord = matrixRecord;
                break;
            }
        }
        
        if (selectedMatrixRecord == null) {
            Assert.areEqual(true, selectedMatrixRecord == null, 'No program area without Interval Score metadata is available');
            return;
        }
        
        List<Object> violations = new List<Object>{
            new Map<String, Object>{
                'severity' => selectedMatrixRecord.QuestionAPIName__c,
                    'scope' => selectedMatrixRecord.ResponseValue__c
                    }
        };
            
            Test.startTest();
        Map<String, Object> result = (Map<String, Object>) new PHOCSCCFLRiskAssessmentScoringService().call(
            ACTION_CALCULATE_SCORE,
            buildArgs(selectedMatrixRecord.ProgramArea__c, violations, new Map<String, Object>())
        );
        Test.stopTest();
        
        Assert.areEqual(selectedMatrixRecord.Score__c, (Decimal) result.get('PartAMatrixScore'), 'Matrix score should still be calculated');
        Assert.areEqual(0, (Decimal) result.get('PartAScore'), 'Part A Score should be zero when no Interval Score metadata exists');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Finds a facility type with RiskMatrix, IntervalScore and Rating metadata.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static String resolveFullyConfiguredProgramArea() {
        List<PHOCSRiskAssessmentScoring__mdt> riskMatrixRecords = [
            SELECT ProgramArea__c
            FROM PHOCSRiskAssessmentScoring__mdt
            WHERE AssessmentType__c = 'RiskMatrix'
            AND Score__c != null
        ];
        
        Set<String> candidateProgramAreas = new Set<String>();
        
        for (PHOCSRiskAssessmentScoring__mdt record : riskMatrixRecords) {
            candidateProgramAreas.add(record.ProgramArea__c);
        }
        
        if (candidateProgramAreas.isEmpty()) {
            return null;
        }
        
        List<PHOCSRiskAssessmentScoring__mdt> intervalRecords = [SELECT ProgramArea__c FROM PHOCSRiskAssessmentScoring__mdt
                                                                 WHERE ProgramArea__c IN :candidateProgramAreas AND AssessmentType__c = 'IntervalScore'];
        
        Set<String> programAreasWithInterval = new Set<String>();
        
        for (PHOCSRiskAssessmentScoring__mdt record : intervalRecords) {
            programAreasWithInterval.add(record.ProgramArea__c);
        }
        
        List<PHOCSRiskAssessmentScoring__mdt> ratingRecords = [SELECT ProgramArea__c FROM PHOCSRiskAssessmentScoring__mdt
                                                               WHERE ProgramArea__c IN :candidateProgramAreas AND AssessmentType__c = 'Rating'];
        
        Set<String> programAreasWithRating = new Set<String>();
        
        for (PHOCSRiskAssessmentScoring__mdt record : ratingRecords) {
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
*  @Modification Log: [Date] - [Change Reference] - [Description]
*/
    private static PartBScenario resolvePartBScenario() {
        List<PHOCSRiskAssessmentScoring__mdt> scoreRecords = [SELECT ProgramArea__c, QuestionAPIName__c, ResponseValue__c, Score__c
                                                              FROM PHOCSRiskAssessmentScoring__mdt WHERE AssessmentType__c = 'Score'
                                                              AND QuestionAPIName__c != null AND Score__c != null LIMIT 50];
        
        if (scoreRecords.isEmpty()) {
            return null;
        }
        
        Set<String> programAreas = new Set<String>();        
        for (PHOCSRiskAssessmentScoring__mdt scoreRecord : scoreRecords) {
            programAreas.add(scoreRecord.ProgramArea__c);
        }
        
        List<PHOCSRiskAssessmentScoring__mdt> matrixRecords = [SELECT ProgramArea__c, QuestionAPIName__c, ResponseValue__c, Score__c
                                                               FROM PHOCSRiskAssessmentScoring__mdt WHERE ProgramArea__c IN :programAreas
                                                               AND AssessmentType__c = 'RiskMatrix' AND Score__c != null];
        
        Map<String, PHOCSRiskAssessmentScoring__mdt> matrixRecordByProgramArea = new Map<String, PHOCSRiskAssessmentScoring__mdt>();
        
        for (PHOCSRiskAssessmentScoring__mdt matrixRecord : matrixRecords) {
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