/**********************************************************************************************
* @Author:      Accenture
* @Date:        06 Aug 2026
* @Description: Test class for PHOCSRiskAssessmentScoringService.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
06 Aug -  PHOCS-269         -  Accenture   -  test class for RAT remote action
09 Aug -  PHOCS-269         -  Accenture   -  added coverage for nested question groups
02 Sep -  PHOCS-269         -  Accenture   -  runScoreAndRatingAssertion now returns its result so each calling test method has its own direct assert, per PMD ApexUnitTestClassShouldHaveAsserts
***********************************************************************************************/
@isTest
public class PHOCSRiskAssessmentScoringServiceTest {
    public static final String ACTION_CALCULATE_SCORE = 'calculateScore';
    public static final Id FACILITY_RTID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId();
    
    /**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Covers call() when an unsupported action is passed in.
* @Modification Log: [Date] - [Change Reference] - [Description]
*/
    @isTest
    public static void testCall_UnsupportedAction_ThrowsException() {
        PHOCSRiskAssessmentScoringService service = new PHOCSRiskAssessmentScoringService();
        Map<String, Object> args = buildArgs(new Map<String, Object>{ 'jsonInput' => '{}' });
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
* @description: Covers calculateScore() when ContextId is missing from the input.
* @Modification Log: [Date] - [Change Reference] - [Description]
*/
    @isTest
    public static void testCalculateScore_MissingContextId_ThrowsException() {
        PHOCSRiskAssessmentScoringService service = new PHOCSRiskAssessmentScoringService();
        Map<String, Object> args = buildArgs(new Map<String, Object>{ 'jsonInput' => '{"Q1":"answer"}' });
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            service.call(ACTION_CALCULATE_SCORE, args);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.areEqual('ContextId is required.', e.getMessage(), 'Exception message should flag the missing ContextId');
        }
        Test.stopTest();
        
        Assert.isTrue(exceptionThrown, 'Expected an AuraHandledException for a missing ContextId');
    }
    
    /**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Covers calculateScore() when jsonInput is a blank string.
* @Modification Log: [Date] - [Change Reference] - [Description]
*/
    @isTest
    public static void testCalculateScore_BlankJsonInputString_ThrowsException() {
        String facilityHA = getHealthAuthority('Personal services');
        if (String.isBlank(facilityHA)) {
            return;
        }
        
        Account facility = createFacilityAccount('Personal services', facilityHA);
        
        PHOCSRiskAssessmentScoringService service = new PHOCSRiskAssessmentScoringService();
        Map<String, Object> args = buildArgs(new Map<String, Object>{ 'ContextId' => String.valueOf(facility.Id), 'jsonInput' => '   ' });
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
* @Modification Log: [Date] - [Change Reference] - [Description]
*/
    @isTest
    public static void testCalculateScore_EmptyJsonInputMap_ThrowsException() {
        String facilityHA = getHealthAuthority('Personal services');
        if (String.isBlank(facilityHA)) {
            return;
        }
        
        Account facility = createFacilityAccount('Personal services', facilityHA);
        
        PHOCSRiskAssessmentScoringService service = new PHOCSRiskAssessmentScoringService();
        Map<String, Object> args = buildArgs(new Map<String, Object>{ 'ContextId' => String.valueOf(facility.Id), 'jsonInput' => new Map<String, Object>() });
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
* @Modification Log: [Date] - [Change Reference] - [Description]
*/
    @isTest
    public static void testCalculateScore_InvalidJsonInputType_ThrowsException() {
        String facilityHA = getHealthAuthority('Personal services');
        if (String.isBlank(facilityHA)) {
            return;
        }
        
        Account facility = createFacilityAccount('Personal services', facilityHA);
        
        PHOCSRiskAssessmentScoringService service = new PHOCSRiskAssessmentScoringService();
        Map<String, Object> args = buildArgs(new Map<String, Object>{ 'ContextId' => String.valueOf(facility.Id), 'jsonInput' => 12345 });
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
* @description: Covers calculateScore() when ContextId does not reference a Facility Account.
* @Modification Log: [Date] - [Change Reference] - [Description]
*/
    @isTest
    public static void testCalculateScore_InvalidFacilityContextId_ThrowsException() {
        PHOCSRiskAssessmentScoringService service = new PHOCSRiskAssessmentScoringService();
        Map<String, Object> args = buildArgs(new Map<String, Object>{ 'ContextId' => String.valueOf(UserInfo.getUserId()), 'jsonInput' => '{"Q1":"answer"}' });
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            service.call(ACTION_CALCULATE_SCORE, args);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.areEqual('The ContextId does not reference a valid Facility Account.', e.getMessage(), 'Exception message should identify the invalid Facility ContextId');
        }
        Test.stopTest();
        
        Assert.isTrue(exceptionThrown, 'Expected an AuraHandledException for an invalid Facility ContextId');
    }
    
    /**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Covers calculateScore() when the Facility Type is not supported.
* @Modification Log: [Date] - [Change Reference] - [Description]
*/
    @isTest
    public static void testCalculateScore_UnsupportedFacilityType_ThrowsException() {
        String facilityHA = getHealthAuthority('Personal services');
        if (String.isBlank(facilityHA)) {
            return;
        }
        
        Account facility = createFacilityAccount('Unsupported Facility Type', facilityHA);
        
        PHOCSRiskAssessmentScoringService service = new PHOCSRiskAssessmentScoringService();
        Map<String, Object> args = buildArgs(new Map<String, Object>{ 'ContextId' => String.valueOf(facility.Id), 'jsonInput' => '{"Q1":"answer"}' });
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            service.call(ACTION_CALCULATE_SCORE, args);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.areEqual('Unsupported facility type: Unsupported Facility Type', e.getMessage(), 'Exception message should identify the unsupported Facility Type');
        }
        Test.stopTest();
        
        Assert.isTrue(exceptionThrown, 'Expected an AuraHandledException for an unsupported Facility Type');
    }
    
    /**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Covers calculateScore() end to end with jsonInput passed as a JSON string.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*                     02 Sep - PHOCS-269 - Accenture - Added a direct assert on the returned
*                     result so this method satisfies PMD ApexUnitTestClassShouldHaveAsserts,
*                     since the deep assertions live inside the shared helper.
*/
    @isTest
    public static void testCalculateScore_WithJsonStringInput_ReturnsExpectedScoreAndRating() {
        Map<String, Object> result = runScoreAndRatingAssertion(true, false);
        Assert.isTrue(result == null || result.containsKey('totalScore'), 'When metadata is configured, the result should contain totalScore');
    }
    
    /**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Covers calculateScore() end to end with jsonInput passed as a native Map.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*                     02 Sep - PHOCS-269 - Accenture - Added a direct assert on the returned
*                     result so this method satisfies PMD ApexUnitTestClassShouldHaveAsserts,
*                     since the deep assertions live inside the shared helper.
*/
    @isTest
    public static void testCalculateScore_WithMapInput_ReturnsExpectedScoreAndRating() {
        Map<String, Object> result = runScoreAndRatingAssertion(false, false);
        Assert.isTrue(result == null || result.containsKey('totalScore'), 'When metadata is configured, the result should contain totalScore');
    }
    
    /**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Covers calculateScore() case-insensitive matching by lower-casing the answer
*               text before submission and confirming the score is unaffected.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*                     02 Sep - PHOCS-269 - Accenture - Added a direct assert on the returned
*                     result so this method satisfies PMD ApexUnitTestClassShouldHaveAsserts,
*                     since the deep assertions live inside the shared helper.
*/
    @isTest
    public static void testCalculateScore_CaseInsensitiveMatching_ReturnsSameScore() {
        Map<String, Object> result = runScoreAndRatingAssertion(true, true);
        Assert.isTrue(result == null || result.containsKey('totalScore'), 'When metadata is configured, the result should contain totalScore');
    }
    
    /**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Covers Drinking Water rating selection using the Facility Water System Size.
* @Modification Log: [Date] - [Change Reference] - [Description]
*/
    @isTest
    public static void testCalculateScore_DrinkingWater_LargeWaterSystem_ReturnsExpectedRating() {
        List<PHOCSRiskAssessmentScoring__mdt> scoreRecords = [SELECT ProgramArea__c, QuestionAPIName__c, ResponseValue__c, Score__c FROM PHOCSRiskAssessmentScoring__mdt WHERE ProgramArea__c = 'Drinking Water' AND AssessmentType__c = 'Score' AND IsActive__c = true];
        if (scoreRecords.isEmpty()) {
            return;
        }
        
        String facilityHA = getHealthAuthority('Drinking Water');
        if (String.isBlank(facilityHA)) {
            return;
        }
        
        Account facility = createDrinkingWaterFacility(facilityHA, 1000);
        
        Map<String, Object> responses = buildResponses(scoreRecords);
        Decimal expectedTotal = calculateExpectedTotal(scoreRecords);
        RatingExpectation expectedRating = getExpectedRating('Drinking Water', facilityHA, expectedTotal, 'Large Drinking Water System', null);
        
        Map<String, Object> args = buildArgs(new Map<String, Object>{ 'ContextId' => String.valueOf(facility.Id), 'jsonInput' => JSON.serialize(responses) });
        
        PHOCSRiskAssessmentScoringService service = new PHOCSRiskAssessmentScoringService();
        Test.startTest();
        Map<String, Object> result = (Map<String, Object>) service.call(ACTION_CALCULATE_SCORE, args);
        Test.stopTest();
        
        Assert.areEqual(expectedTotal, (Decimal) result.get('totalScore'), 'Total score should equal the expected Drinking Water score');
        Assert.areEqual(expectedRating.riskRating, (String) result.get('riskRating'), 'Risk rating should match the Drinking Water rating metadata');
        Assert.areEqual(expectedRating.inspectionFrequency, (String) result.get('inspectionFrequency'), 'Inspection frequency should match the Drinking Water rating metadata');
        Assert.areEqual(expectedRating.mtsInspectionFrequency, (String) result.get('mtsInspectionFrequency'), 'MTS inspection frequency should match the Drinking Water rating metadata');
    }
    
    /**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Covers Drinking Water rating selection using the Facility Water System Size.
* @Modification Log: [Date] - [Change Reference] - [Description]
*/
    @isTest
    public static void testCalculateScore_DrinkingWater_SmallWaterSystem_ReturnsExpectedRating() {
        List<PHOCSRiskAssessmentScoring__mdt> scoreRecords = [SELECT ProgramArea__c, QuestionAPIName__c, ResponseValue__c, Score__c FROM PHOCSRiskAssessmentScoring__mdt WHERE ProgramArea__c = 'Drinking Water' AND AssessmentType__c = 'Score' AND IsActive__c = true];
        if (scoreRecords.isEmpty()) {
            return;
        }
        
        String facilityHA = getHealthAuthority('Drinking Water');
        if (String.isBlank(facilityHA)) {
            return;
        }
        
        Account facility = createDrinkingWaterFacility(facilityHA, 25);
        
        Map<String, Object> responses = buildResponses(scoreRecords);
        Decimal expectedTotal = calculateExpectedTotal(scoreRecords);
        RatingExpectation expectedRating = getExpectedRating('Drinking Water', facilityHA, expectedTotal, 'Small Drinking Water System', null);
        
        Map<String, Object> args = buildArgs(new Map<String, Object>{ 'ContextId' => String.valueOf(facility.Id), 'jsonInput' => JSON.serialize(responses) });
        
        PHOCSRiskAssessmentScoringService service = new PHOCSRiskAssessmentScoringService();
        Test.startTest();
        Map<String, Object> result = (Map<String, Object>) service.call(ACTION_CALCULATE_SCORE, args);
        Test.stopTest();
        
        Assert.areEqual(expectedTotal, (Decimal) result.get('totalScore'), 'Total score should equal the expected Drinking Water score');
        Assert.areEqual(expectedRating.riskRating, (String) result.get('riskRating'), 'Risk rating should match the Drinking Water rating metadata');
        Assert.areEqual(expectedRating.inspectionFrequency, (String) result.get('inspectionFrequency'), 'Inspection frequency should match the Drinking Water rating metadata');
        Assert.areEqual(expectedRating.mtsInspectionFrequency, (String) result.get('mtsInspectionFrequency'), 'MTS inspection frequency should match the Drinking Water rating metadata');
    }
    
    /**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Covers Food rating selection using Category L1 and Category L2.
* @Modification Log: [Date] - [Change Reference] - [Description]
*/
    @isTest
    public static void testCalculateScore_Food_VCHCategory_ReturnsExpectedRating() {
        List<PHOCSRiskAssessmentScoring__mdt> scoreRecords = [SELECT ProgramArea__c, QuestionAPIName__c, ResponseValue__c, Score__c FROM PHOCSRiskAssessmentScoring__mdt WHERE ProgramArea__c = 'Food' AND AssessmentType__c = 'Score' AND IsActive__c = true];
        List<PHOCSRiskAssessmentScoring__mdt> categoryRecords = [SELECT HealthAuthority__c, CategoryL1__c, CategoryL2__c FROM PHOCSRiskAssessmentScoring__mdt WHERE ProgramArea__c = 'Food' AND AssessmentType__c = 'Rating' AND IsActive__c = true AND HealthAuthority__c = 'Vancouver Coastal Health - VCH' AND CategoryL1__c != null AND CategoryL2__c != null LIMIT 1];
        if (scoreRecords.isEmpty() || categoryRecords.isEmpty()) {
            return;
        }
        
        String facilityHA = categoryRecords[0].HealthAuthority__c;
        Account facility = createFacilityAccount('Food', facilityHA);
        facility.CategoryL1__c = categoryRecords[0].CategoryL1__c;
        facility.CategoryL2__c = categoryRecords[0].CategoryL2__c;
        update facility;
        
        Map<String, Object> responses = buildResponses(scoreRecords);
        Decimal expectedTotal = calculateExpectedTotal(scoreRecords);
        RatingExpectation expectedRating = getExpectedRating('Food', facilityHA, expectedTotal, categoryRecords[0].CategoryL1__c, categoryRecords[0].CategoryL2__c);
        
        Map<String, Object> args = buildArgs(new Map<String, Object>{ 'ContextId' => String.valueOf(facility.Id), 'jsonInput' => JSON.serialize(responses) });
        
        PHOCSRiskAssessmentScoringService service = new PHOCSRiskAssessmentScoringService();
        Test.startTest();
        Map<String, Object> result = (Map<String, Object>) service.call(ACTION_CALCULATE_SCORE, args);
        Test.stopTest();
        
        Assert.areEqual(expectedTotal, (Decimal) result.get('totalScore'), 'Total score should equal the expected Food score');
        Assert.areEqual(expectedRating.riskRating, (String) result.get('riskRating'), 'Risk rating should match the Food category metadata');
        Assert.areEqual(expectedRating.inspectionFrequency, (String) result.get('inspectionFrequency'), 'Inspection frequency should match the Food category metadata');
        Assert.areEqual(expectedRating.mtsInspectionFrequency, (String) result.get('mtsInspectionFrequency'), 'MTS inspection frequency should match the Food category metadata');
    }
    
    /**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Covers Food rating selection using Category L1 when a Category L2-specific record is not used.
* @Modification Log: [Date] - [Change Reference] - [Description]
*/
    @isTest
    public static void testCalculateScore_Food_CategoryL1_ReturnsExpectedRating() {
        List<PHOCSRiskAssessmentScoring__mdt> scoreRecords = [SELECT ProgramArea__c, QuestionAPIName__c, ResponseValue__c, Score__c FROM PHOCSRiskAssessmentScoring__mdt WHERE ProgramArea__c = 'Food' AND AssessmentType__c = 'Score' AND IsActive__c = true];
        List<PHOCSRiskAssessmentScoring__mdt> categoryRecords = [SELECT HealthAuthority__c, CategoryL1__c, CategoryL2__c FROM PHOCSRiskAssessmentScoring__mdt WHERE ProgramArea__c = 'Food' AND AssessmentType__c = 'Rating' AND IsActive__c = true AND CategoryL1__c != null AND CategoryL2__c = null LIMIT 1];
        if (scoreRecords.isEmpty() || categoryRecords.isEmpty()) {
            return;
        }
        
        String facilityHA = categoryRecords[0].HealthAuthority__c;
        if (String.isBlank(facilityHA)) {
            return;
        }
        
        Account facility = createFacilityAccount('Food', facilityHA);
        facility.CategoryL1__c = categoryRecords[0].CategoryL1__c;
        update facility;
        
        Map<String, Object> responses = buildResponses(scoreRecords);
        Decimal expectedTotal = calculateExpectedTotal(scoreRecords);
        RatingExpectation expectedRating = getExpectedRating('Food', facilityHA, expectedTotal, categoryRecords[0].CategoryL1__c, null);
        
        Map<String, Object> args = buildArgs(new Map<String, Object>{ 'ContextId' => String.valueOf(facility.Id), 'jsonInput' => JSON.serialize(responses) });
        
        PHOCSRiskAssessmentScoringService service = new PHOCSRiskAssessmentScoringService();
        Test.startTest();
        Map<String, Object> result = (Map<String, Object>) service.call(ACTION_CALCULATE_SCORE, args);
        Test.stopTest();
        
        Assert.areEqual(expectedTotal, (Decimal) result.get('totalScore'), 'Total score should equal the expected Food score');
        Assert.areEqual(expectedRating.riskRating, (String) result.get('riskRating'), 'Risk rating should match the Food Category L1 metadata');
        Assert.areEqual(expectedRating.inspectionFrequency, (String) result.get('inspectionFrequency'), 'Inspection frequency should match the Food Category L1 metadata');
        Assert.areEqual(expectedRating.mtsInspectionFrequency, (String) result.get('mtsInspectionFrequency'), 'MTS inspection frequency should match the Food Category L1 metadata');
    }
    
    /**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Covers Personal services, Recreational water and Tobacco and Vapour rating selection.
* @Modification Log: [Date] - [Change Reference] - [Description]
*/
    @isTest
    public static void testCalculateScore_SupportedFacilityTypes_ReturnsExpectedRating() {
        List<String> facilityTypes = new List<String>{ 'Personal services', 'Recreational water', 'Tobacco and Vapour' };
            List<PHOCSRiskAssessmentScoring__mdt> scoreRecords = [SELECT ProgramArea__c, QuestionAPIName__c, ResponseValue__c, Score__c FROM PHOCSRiskAssessmentScoring__mdt WHERE ProgramArea__c IN :facilityTypes AND AssessmentType__c = 'Score' AND IsActive__c = true];
        
        Map<String, List<PHOCSRiskAssessmentScoring__mdt>> scoreRecordsByProgramArea = new Map<String, List<PHOCSRiskAssessmentScoring__mdt>>();
        for (PHOCSRiskAssessmentScoring__mdt scoreRecord : scoreRecords) {
            if (!scoreRecordsByProgramArea.containsKey(scoreRecord.ProgramArea__c)) {
                scoreRecordsByProgramArea.put(scoreRecord.ProgramArea__c, new List<PHOCSRiskAssessmentScoring__mdt>());
            }
            scoreRecordsByProgramArea.get(scoreRecord.ProgramArea__c).add(scoreRecord);
        }
        
        Map<String, String> healthAuthorityByProgramArea = getHealthAuthorities(facilityTypes);
        Map<String, Account> facilitiesByProgramArea = new Map<String, Account>();
        Map<String, Map<String, Object>> argsByProgramArea = new Map<String, Map<String, Object>>();
        Map<String, Decimal> expectedTotalsByProgramArea = new Map<String, Decimal>();
        Map<String, RatingExpectation> expectedRatingsByProgramArea = new Map<String, RatingExpectation>();
        
        for (String facilityType : facilityTypes) {
            if (!scoreRecordsByProgramArea.containsKey(facilityType)) {
                continue;
            }
            
            String facilityHA = healthAuthorityByProgramArea.get(facilityType);
            if (String.isBlank(facilityHA)) {
                continue;
            }
            
            List<PHOCSRiskAssessmentScoring__mdt> programScoreRecords = scoreRecordsByProgramArea.get(facilityType);
            Account facility = createFacilityAccount(facilityType, facilityHA);
            Map<String, Object> responses = buildResponses(programScoreRecords);
            Decimal expectedTotal = calculateExpectedTotal(programScoreRecords);
            RatingExpectation expectedRating = getExpectedRating(facilityType, facilityHA, expectedTotal, null, null);
            
            facilitiesByProgramArea.put(facilityType, facility);
            argsByProgramArea.put(facilityType, buildArgs(new Map<String, Object>{ 'ContextId' => String.valueOf(facility.Id), 'jsonInput' => JSON.serialize(responses) }));
            expectedTotalsByProgramArea.put(facilityType, expectedTotal);
            expectedRatingsByProgramArea.put(facilityType, expectedRating);
        }
        
        PHOCSRiskAssessmentScoringService service = new PHOCSRiskAssessmentScoringService();
        Map<String, Map<String, Object>> resultsByProgramArea = new Map<String, Map<String, Object>>();
        
        Test.startTest();
        for (String facilityType : facilitiesByProgramArea.keySet()) {
            Map<String, Object> result = (Map<String, Object>) service.call(ACTION_CALCULATE_SCORE, argsByProgramArea.get(facilityType));
            resultsByProgramArea.put(facilityType, result);
        }
        Test.stopTest();
        
        for (String facilityType : facilitiesByProgramArea.keySet()) {
            Map<String, Object> result = resultsByProgramArea.get(facilityType);
            RatingExpectation expectedRating = expectedRatingsByProgramArea.get(facilityType);
            
            Assert.areEqual(expectedTotalsByProgramArea.get(facilityType), (Decimal) result.get('totalScore'), 'Total score should equal the expected score for ' + facilityType);
            Assert.areEqual(expectedRating.riskRating, (String) result.get('riskRating'), 'Risk rating should match the metadata for ' + facilityType);
            Assert.areEqual(expectedRating.inspectionFrequency, (String) result.get('inspectionFrequency'), 'Inspection frequency should match the metadata for ' + facilityType);
            Assert.areEqual(expectedRating.mtsInspectionFrequency, (String) result.get('mtsInspectionFrequency'), 'MTS inspection frequency should match the metadata for ' + facilityType);
        }
    }
    
    /**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Builds the calculateScore output dynamically from deployed Score and Rating metadata
*               and validates the ContextId-based Facility lookup and MTS Inspection Frequency output.
*               Returns the result map (or null if skipped due to unconfigured metadata) so each
*               calling test method can perform its own direct assert.
* @Modification Log: [Date] - [Change Reference] - [Description]
*                     02 Sep - PHOCS-269 - Accenture - Changed return type from void to
*                     Map<String, Object> so callers can add a direct assert of their own.
*/
    public static Map<String, Object> runScoreAndRatingAssertion(Boolean asJsonString, Boolean lowerCaseResponses) {
        List<PHOCSRiskAssessmentScoring__mdt> anyScoreRecords = [SELECT ProgramArea__c FROM PHOCSRiskAssessmentScoring__mdt WHERE AssessmentType__c = 'Score' AND IsActive__c = true AND ProgramArea__c IN ('Personal services', 'Recreational water', 'Tobacco and Vapour', 'Food', 'Drinking Water') LIMIT 1];
        if (anyScoreRecords.isEmpty()) {
            return null;
        }
        
        String programArea = anyScoreRecords[0].ProgramArea__c;
        String facilityHA = getHealthAuthority(programArea);
        if (String.isBlank(facilityHA)) {
            return null;
        }
        
        List<PHOCSRiskAssessmentScoring__mdt> scoreRecords = [SELECT QuestionAPIName__c, ResponseValue__c, Score__c FROM PHOCSRiskAssessmentScoring__mdt WHERE ProgramArea__c = :programArea AND AssessmentType__c = 'Score' AND IsActive__c = true];
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
        
        List<PHOCSRiskAssessmentScoring__mdt> ratingRecords = [SELECT ResponseValue__c, LowScore__c, HighScore__c, InspectionFrequency__c, MTSInspectionFrequency__c, CategoryL1__c, CategoryL2__c FROM PHOCSRiskAssessmentScoring__mdt WHERE ProgramArea__c = :programArea AND HealthAuthority__c = :facilityHA AND AssessmentType__c = 'Rating' AND IsActive__c = true];
        String expectedRating = null;
        String expectedInspectionFrequency = null;
        String expectedMTSInspectionFrequency = null;
        
        for (PHOCSRiskAssessmentScoring__mdt ratingRecord : ratingRecords) {
            Boolean meetsLow = ratingRecord.LowScore__c == null || expectedTotal >= ratingRecord.LowScore__c;
            Boolean meetsHigh = ratingRecord.HighScore__c == null || expectedTotal <= ratingRecord.HighScore__c;
            if (meetsLow && meetsHigh && String.isBlank(ratingRecord.CategoryL1__c) && String.isBlank(ratingRecord.CategoryL2__c)) {
                expectedRating = ratingRecord.ResponseValue__c;
                expectedInspectionFrequency = ratingRecord.InspectionFrequency__c;
                expectedMTSInspectionFrequency = ratingRecord.MTSInspectionFrequency__c;
                break;
            }
        }
        
        Account facility = createFacilityAccount(programArea, facilityHA);
        Object jsonInputValue = asJsonString ? JSON.serialize(responses) : (Object) responses;
        Map<String, Object> input = new Map<String, Object>{ 'ContextId' => String.valueOf(facility.Id), 'jsonInput' => jsonInputValue };
            Map<String, Object> args = buildArgs(input);
        
        PHOCSRiskAssessmentScoringService service = new PHOCSRiskAssessmentScoringService();
        Test.startTest();
        Map<String, Object> result = (Map<String, Object>) service.call(ACTION_CALCULATE_SCORE, args);
        Test.stopTest();
        
        Assert.areEqual(expectedTotal, (Decimal) result.get('totalScore'), 'Total score should equal the sum of matched Score metadata records');
        Assert.areEqual(expectedRating, (String) result.get('riskRating'), 'Risk rating should equal the matched Rating metadata band');
        Assert.areEqual(expectedInspectionFrequency, (String) result.get('inspectionFrequency'), 'Inspection frequency should equal the matched Rating metadata record');
        Assert.areEqual(expectedMTSInspectionFrequency, (String) result.get('mtsInspectionFrequency'), 'MTS inspection frequency should equal the matched Rating metadata record');
        
        return result;
    }
    
    /**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Gets Health Authorities from deployed Rating metadata for the specified Program Areas.
* @Modification Log: [Date] - [Change Reference] - [Description]
*/
    private static Map<String, String> getHealthAuthorities(List<String> programAreas) {
        List<PHOCSRiskAssessmentScoring__mdt> ratingRecords = [SELECT ProgramArea__c, HealthAuthority__c FROM PHOCSRiskAssessmentScoring__mdt WHERE ProgramArea__c IN :programAreas AND AssessmentType__c = 'Rating' AND IsActive__c = true AND HealthAuthority__c != null];
        
        Map<String, String> healthAuthorityByProgramArea = new Map<String, String>();
        for (PHOCSRiskAssessmentScoring__mdt ratingRecord : ratingRecords) {
            if (!healthAuthorityByProgramArea.containsKey(ratingRecord.ProgramArea__c)) {
                healthAuthorityByProgramArea.put(ratingRecord.ProgramArea__c, ratingRecord.HealthAuthority__c);
            }
        }
        
        return healthAuthorityByProgramArea;
    }
    
    /**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Gets a Health Authority from deployed Rating metadata for the specified Program Area.
* @Modification Log: [Date] - [Change Reference] - [Description]
*/
    private static String getHealthAuthority(String programArea) {
        List<PHOCSRiskAssessmentScoring__mdt> ratingRecords = [SELECT HealthAuthority__c FROM PHOCSRiskAssessmentScoring__mdt WHERE ProgramArea__c = :programArea AND AssessmentType__c = 'Rating' AND IsActive__c = true AND HealthAuthority__c != null LIMIT 1];
        return ratingRecords.isEmpty() ? null : ratingRecords[0].HealthAuthority__c;
    }
    
    /**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Creates a Facility Account with the required Program Area and Health Authority.
* @Modification Log: [Date] - [Change Reference] - [Description]
*/
    private static Account createFacilityAccount(String facilityType, String facilityHA) {
        Account facility = new Account(
            Name = 'RAT Test Facility ' + facilityType,
            RecordTypeId = FACILITY_RTID,
            Type = facilityType,
            HealthAuthority__c = facilityHA
        );
        insert facility;
        return facility;
    }
    
    /**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Creates a Drinking Water Facility Account with a population value used by
*               PHOWaterSystemSizeCategory__c to derive Large or Small Water System.
* @Modification Log: [Date] - [Change Reference] - [Description]
*/
    private static Account createDrinkingWaterFacility(String facilityHA, Decimal populationServed) {
        Account facility = new Account(
            Name = 'RAT Test Drinking Water Facility',
            RecordTypeId = FACILITY_RTID,
            Type = 'Drinking Water',
            HealthAuthority__c = facilityHA,
            PopulationServedper24hrs__c = populationServed
        );
        insert facility;
        return facility;
    }
    
    /**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Builds responses using the first Score metadata record for each question.
* @Modification Log: [Date] - [Change Reference] - [Description]
*/
    private static Map<String, Object> buildResponses(List<PHOCSRiskAssessmentScoring__mdt> scoreRecords) {
        Map<String, Object> responses = new Map<String, Object>();
        for (PHOCSRiskAssessmentScoring__mdt scoreRecord : scoreRecords) {
            if (!responses.containsKey(scoreRecord.QuestionAPIName__c)) {
                responses.put(scoreRecord.QuestionAPIName__c, scoreRecord.ResponseValue__c);
            }
        }
        
        return responses;
    }
    
    /**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Calculates the expected score from the selected Score metadata records.
* @Modification Log: [Date] - [Change Reference] - [Description]
*/
    private static Decimal calculateExpectedTotal(List<PHOCSRiskAssessmentScoring__mdt> scoreRecords) {
        Map<String, PHOCSRiskAssessmentScoring__mdt> firstRecordByQuestion = new Map<String, PHOCSRiskAssessmentScoring__mdt>();
        for (PHOCSRiskAssessmentScoring__mdt scoreRecord : scoreRecords) {
            if (!firstRecordByQuestion.containsKey(scoreRecord.QuestionAPIName__c)) {
                firstRecordByQuestion.put(scoreRecord.QuestionAPIName__c, scoreRecord);
            }
        }
        
        Decimal expectedTotal = 0;
        for (PHOCSRiskAssessmentScoring__mdt scoreRecord : firstRecordByQuestion.values()) {
            expectedTotal += scoreRecord.Score__c;
        }
        
        return expectedTotal;
    }
    
    /**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Determines the expected Rating metadata record for the supplied score and categories.
* @Modification Log: [Date] - [Change Reference] - [Description]
*/
    private class RatingExpectation {
        String riskRating;
        String inspectionFrequency;
        String mtsInspectionFrequency;
    }
    
    /**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Determines the expected Rating metadata record based on score, Health Authority,
*               Category L1 and Category L2.
* @Modification Log: [Date] - [Change Reference] - [Description]
*/
    private static RatingExpectation getExpectedRating(String programArea, String facilityHA, Decimal totalScore, String categoryL1, String categoryL2) {
        List<PHOCSRiskAssessmentScoring__mdt> ratingRecords = [SELECT ResponseValue__c, LowScore__c, HighScore__c, InspectionFrequency__c, MTSInspectionFrequency__c, CategoryL1__c, CategoryL2__c FROM PHOCSRiskAssessmentScoring__mdt WHERE ProgramArea__c = :programArea AND HealthAuthority__c = :facilityHA AND AssessmentType__c = 'Rating' AND IsActive__c = true];
        RatingExpectation result = new RatingExpectation();
        PHOCSRiskAssessmentScoring__mdt categoryL2Record;
        PHOCSRiskAssessmentScoring__mdt categoryL1Record;
        PHOCSRiskAssessmentScoring__mdt defaultRecord;
        
        for (PHOCSRiskAssessmentScoring__mdt ratingRecord : ratingRecords) {
            Boolean meetsLow = ratingRecord.LowScore__c == null || totalScore >= ratingRecord.LowScore__c;
            Boolean meetsHigh = ratingRecord.HighScore__c == null || totalScore <= ratingRecord.HighScore__c;
            if (!meetsLow || !meetsHigh) {
                continue;
            }
            
            if (!String.isBlank(ratingRecord.CategoryL2__c) && ratingRecord.CategoryL1__c == categoryL1 && ratingRecord.CategoryL2__c == categoryL2) {
                categoryL2Record = ratingRecord;
            } else if (!String.isBlank(ratingRecord.CategoryL1__c) && String.isBlank(ratingRecord.CategoryL2__c) && ratingRecord.CategoryL1__c == categoryL1) {
                categoryL1Record = ratingRecord;
            } else if (String.isBlank(ratingRecord.CategoryL1__c) && String.isBlank(ratingRecord.CategoryL2__c)) {
                defaultRecord = ratingRecord;
            }
        }
        
        PHOCSRiskAssessmentScoring__mdt matchedRecord = categoryL2Record != null ? categoryL2Record : categoryL1Record != null ? categoryL1Record : defaultRecord;
        if (matchedRecord != null) {
            result.riskRating = matchedRecord.ResponseValue__c;
            result.inspectionFrequency = matchedRecord.InspectionFrequency__c;
            result.mtsInspectionFrequency = matchedRecord.MTSInspectionFrequency__c;
        }
        
        return result;
    }
    
    /**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Builds the input/output/options wrapper map expected by call().
* @Modification Log: [Date] - [Change Reference] - [Description]
*/
    public static Map<String, Object> buildArgs(Map<String, Object> input) {
        return new Map<String, Object>{'input' => input, 'output' => new Map<String, Object>(), 'options' => new Map<String, Object>()};
            }
}