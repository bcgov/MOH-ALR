/**********************************************************************************************
* @Author:      Accenture 
* @Date:        14 Jul 2026
* @Description: The purpose of this class is to remote action for RAT
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
                06 Aug -  PHOCS-269         -  Deepak      -  remote action for RAT
                09 Aug -  PHOCS-269         -  Deepak      -  flatten nested question groups
***********************************************************************************************/
global without sharing class PHOCSRiskAssessmentScoringService implements Callable {
    private static final String ACTION_CALCULATE_SCORE = 'calculateScore';
    private static final String ASSESSMENT_TYPE_SCORE = 'Score';
    private static final String ASSESSMENT_TYPE_RATING = 'Rating';
    private static final String FACILITY_TYPE_DRINKING_WATER = 'Drinking Water';
    private static final String FACILITY_TYPE_FOOD = 'Food';
    private static final String FACILITY_TYPE_PERSONAL_SERVICES = 'Personal services';
    private static final String FACILITY_TYPE_RECREATIONAL_WATER = 'Recreational water';
    private static final String FACILITY_TYPE_TOBACCO_VAPOUR = 'Tobacco and Vapour';
    private static final Id FACILITY_RTID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId();

/**
* @author: Deepak
* @date: 14 Jul 2026
* @description: call method for remote context. Dispatches to calculateScore() for the
* calculateScore action and throws for any other action.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    global Object call(String action, Map<String, Object> args) {
        Map<String, Object> input = (Map<String, Object>) args.get('input');
        Map<String, Object> output = (Map<String, Object>) args.get('output');
        Map<String, Object> options = (Map<String, Object>) args.get('options');

        if (action == ACTION_CALCULATE_SCORE) {
            calculateScore(input, output);
            return output;
        }
        throwError('Unsupported action: ' + action);
        return output;
    }

/**
* @author: Deepak
* @date: 14 Jul 2026
* @description: Core scoring flow - resolves the Facility from ContextId, validates the facility
* type and Health Authority, flattens and scores the submitted Part B responses, determines the
* Risk Rating via the facility-type-specific rating logic, and populates the output map.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private void calculateScore(Map<String, Object> inputMap, Map<String, Object> outMap) {
        String contextId = (String) inputMap.get('ContextId');
        Object jsonInputRaw = inputMap.get('jsonInput');
        validateInput(contextId, jsonInputRaw);

        Id facilityId;
        try {
            facilityId = Id.valueOf(contextId);
        } catch (Exception ex) {
            throwError('ContextId must be a valid Account Id.');
            return;
        }

        Account facility = getFacility(facilityId);
        String facilityType = facility.Type;
        String facilityHA = facility.HealthAuthority__c;
        String categoryL1 = facility.CategoryL1__c;
        String categoryL2 = facility.CategoryL2__c;
        String waterSystemSizeCategory = facility.PHOWaterSystemSizeCategory__c;

        validateFacility(facilityType, facilityHA);

        Map<String, Object> rawResponses = parseJsonInput(jsonInputRaw);
        Map<String, Object> responses = flattenResponses(rawResponses);

        List<PHOCSRiskAssessmentScoring__mdt> scoreRecords = loadScoringMetadata(facilityType, ASSESSMENT_TYPE_SCORE);
        Map<String, Decimal> scoreLookup = buildScoreLookupMap(scoreRecords);
        Decimal totalScore = calculateTotalScore(responses, scoreLookup);

        RatingResult ratingResult = determineRiskRating(facilityType, totalScore, facilityHA, categoryL1, categoryL2, waterSystemSizeCategory);

        populateOutput(outMap, totalScore, ratingResult.riskRating, ratingResult.inspectionFrequency, ratingResult.mtsInspectionFrequency);
    }

/**
* @author: Deepak
* @date: 14 Jul 2026
* @description: Queries the Facility Account for the given Id, restricted to the Facility record
* type. Throws if no matching Facility is found.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private Account getFacility(Id facilityId) {
        List<Account> facilities = [SELECT Id, Type, HealthAuthority__c, CategoryL1__c, CategoryL2__c, PHOWaterSystemSizeCategory__c
                                    FROM Account WHERE Id = :facilityId LIMIT 1];
        if (facilities.isEmpty()) {
            throwError('The ContextId does not reference a valid Facility Account.');
        }
        return facilities[0];
    }

/**
* @author: Deepak
* @date: 14 Jul 2026
* @description: Validates that ContextId is present and that jsonInput is present and not blank
* (whether supplied as a String or a Map).
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private void validateInput(String contextId, Object jsonInputRaw) {
        if (String.isBlank(contextId)) {
            throwError('ContextId is required.');
        }

        Boolean isBlankString = jsonInputRaw instanceof String && String.isBlank((String) jsonInputRaw);
        Boolean isEmptyMap = jsonInputRaw instanceof Map<String, Object> && ((Map<String, Object>) jsonInputRaw).isEmpty();

        if (jsonInputRaw == null || isBlankString || isEmptyMap) {
            throwError('jsonInput is required.');
        }
    }

/**
* @author: Deepak
* @date: 14 Jul 2026
* @description: Validates that the Facility has both a Type and a Health Authority, and that the
* Type is one of the supported facility types.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private void validateFacility(String facilityType, String facilityHA) {
        if (String.isBlank(facilityType)) {
            throwError('Facility Type is required.');
        }

        if (String.isBlank(facilityHA)) {
            throwError('Health Authority is required.');
        }

        if (facilityType != FACILITY_TYPE_DRINKING_WATER && facilityType != FACILITY_TYPE_FOOD && facilityType != FACILITY_TYPE_PERSONAL_SERVICES &&
            facilityType != FACILITY_TYPE_RECREATIONAL_WATER && facilityType != FACILITY_TYPE_TOBACCO_VAPOUR) {
            throwError('Unsupported facility type: ' + facilityType);
        }
    }

/**
* @author: Deepak
* @date: 14 Jul 2026
* @description: Parses jsonInput into a Map, accepting either a JSON string or a native Map.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private Map<String, Object> parseJsonInput(Object jsonInputRaw) {
        if (jsonInputRaw instanceof String) {
            return (Map<String, Object>) JSON.deserializeUntyped((String) jsonInputRaw);
        }

        if (jsonInputRaw instanceof Map<String, Object>) {
            return (Map<String, Object>) jsonInputRaw;
        }

        throwError('jsonInput must be a JSON string or a map.');
        return null;
    }

/**
* @author: Deepak
* @date: 09 Aug 2026
* @description: Recursively flattens arbitrarily nested question groups into a single flat map of
* questionApiName to answer text.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private Map<String, Object> flattenResponses(Map<String, Object> responses) {
        Map<String, Object> flattened = new Map<String, Object>();
        flattenInto(responses, flattened);
        return flattened;
    }

/**
* @author: Deepak
* @date: 09 Aug 2026
* @description: Recursion helper for flattenResponses() - copies any non-Map value straight into
* the target map, and recurses into any value that is itself a Map.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private void flattenInto(Map<String, Object> source, Map<String, Object> target) {
        for (String key : source.keySet()) {
            Object value = source.get(key);

            if (value instanceof Map<String, Object>) {
                flattenInto((Map<String, Object>) value, target);
            } else {
                target.put(key, value);
            }
        }
    }

/**
* @author: Deepak
* @date: 14 Jul 2026
* @description: Loads active PHOCSRiskAssessmentScoring__mdt records for the given Program Area
* and Assessment Type (e.g. Score).
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private List<PHOCSRiskAssessmentScoring__mdt> loadScoringMetadata(String programArea, String assessmentType) {
        return [SELECT QuestionAPIName__c, ResponseValue__c, Score__c, LowScore__c, HighScore__c, InspectionFrequency__c FROM PHOCSRiskAssessmentScoring__mdt WHERE ProgramArea__c = :programArea AND AssessmentType__c = :assessmentType AND IsActive__c = true];
    }

/**
* @author: Deepak
* @date: 14 Jul 2026
* @description: Loads active Rating-type PHOCSRiskAssessmentScoring__mdt records for the given
* Program Area and Health Authority.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private List<PHOCSRiskAssessmentScoring__mdt> loadRatingMetadata(String programArea, String facilityHA) {
        return [SELECT ResponseValue__c, LowScore__c, HighScore__c, InspectionFrequency__c, MTSInspectionFrequency__c, CategoryL1__c, CategoryL2__c FROM PHOCSRiskAssessmentScoring__mdt WHERE ProgramArea__c = :programArea AND HealthAuthority__c = :facilityHA AND AssessmentType__c = :ASSESSMENT_TYPE_RATING AND IsActive__c = true];
    }

/**
* @author: Accenture
* @date: 14 Jul 2026
* @description: Builds a QuestionAPIName|ResponseValue lookup map of Score__c values from a list
* of Score metadata records.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private Map<String, Decimal> buildScoreLookupMap(List<PHOCSRiskAssessmentScoring__mdt> records) {
        Map<String, Decimal> lookup = new Map<String, Decimal>();

        for (PHOCSRiskAssessmentScoring__mdt scoreRecord : records) {
            String key = buildLookupKey(scoreRecord.QuestionAPIName__c, scoreRecord.ResponseValue__c);
            lookup.put(key, scoreRecord.Score__c);
        }
        return lookup;
    }

/**
* @author: Deepak
* @date: 14 Jul 2026
* @description: Builds a case-insensitive, trimmed lookup key from a question API name and a
* response value.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private String buildLookupKey(String questionApiName, String responseValue) {
        String question = questionApiName == null ? '' : questionApiName.trim().toUpperCase();
        String response = responseValue == null ? '' : responseValue.trim().toUpperCase();
        return question + '|' + response;
    }

/**
* @author: Deepak
* @date: 14 Jul 2026
* @description: Sums the Score__c values matched between the flattened responses and the
* QuestionAPIName|ResponseValue lookup map. Unanswered or unmatched questions contribute 0.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private Decimal calculateTotalScore(Map<String, Object> responses, Map<String, Decimal> scoreLookup) {
        Decimal totalScore = 0;

        for (String questionApiName : responses.keySet()) {
            Object rawValue = responses.get(questionApiName);

            if (rawValue == null) {
                continue;
            }

            String key = buildLookupKey(questionApiName, String.valueOf(rawValue));

            if (scoreLookup.containsKey(key)) {
                totalScore += scoreLookup.get(key);
            }
        }
        return totalScore;
    }

/**
* @author: Deepak
* @date: 14 Jul 2026
* @description: Carrier for the resolved Risk Rating, Inspection Frequency, and MTS Inspection
* Frequency for a single scoring result.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private class RatingResult {
        String riskRating;
        String inspectionFrequency;
        String mtsInspectionFrequency;
    }

/**
* @author: Deepak
* @date: 14 Jul 2026
* @description: Dispatches to the facility-type-specific Risk Rating determination method based
* on the Facility's Type. Throws for any unsupported facility type.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private RatingResult determineRiskRating(String facilityType, Decimal totalScore, String facilityHA, String categoryL1, String categoryL2, String waterSystemSizeCategory) {
        if (facilityType == FACILITY_TYPE_DRINKING_WATER) {
            return determineDrinkingWaterRiskRating(totalScore, facilityHA, waterSystemSizeCategory);
        }

        if (facilityType == FACILITY_TYPE_FOOD) {
            return determineFoodRiskRating(totalScore, facilityHA, categoryL1, categoryL2);
        }

        if (facilityType == FACILITY_TYPE_PERSONAL_SERVICES) {
            return determinePersonalServicesRiskRating(totalScore, facilityHA);
        }

        if (facilityType == FACILITY_TYPE_RECREATIONAL_WATER) {
            return determineRecreationalWaterRiskRating(totalScore, facilityHA);
        }

        if (facilityType == FACILITY_TYPE_TOBACCO_VAPOUR) {
            return determineTobaccoAndVapourRiskRating(totalScore, facilityHA);
        }

        throwError('Unsupported facility type: ' + facilityType);
        return new RatingResult();
    }

/**
* @author: Deepak
* @date: 14 Jul 2026
* @description: Determines the Risk Rating for a Drinking Water facility. Resolves CategoryL1 as
* Large or Small Drinking Water System from the water system size category, then matches on
* score range and that resolved category.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private RatingResult determineDrinkingWaterRiskRating(Decimal totalScore, String facilityHA, String waterSystemSizeCategory) {
        String categoryL1;

        if (!String.isBlank(waterSystemSizeCategory) && waterSystemSizeCategory.contains('Large')) {
            categoryL1 = 'Large Drinking Water System';
        } else if (!String.isBlank(waterSystemSizeCategory) && waterSystemSizeCategory.contains('Small')) {
            categoryL1 = 'Small Drinking Water System';
        } else {
            throwError('Drinking Water system size could not be determined.');
        }

        List<PHOCSRiskAssessmentScoring__mdt> ratingRecords = loadRatingMetadata(FACILITY_TYPE_DRINKING_WATER, facilityHA);
        return findRatingByScoreAndCategory(totalScore, ratingRecords, categoryL1, null);
    }

/**
* @author: Deepak
* @date: 14 Jul 2026
* @description: Determines the Risk Rating for a Food facility. Vancouver Coastal Health uses
* CategoryL1/CategoryL2-based matching; all other Health Authorities use plain score-range
* matching.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private RatingResult determineFoodRiskRating(Decimal totalScore, String facilityHA, String categoryL1, String categoryL2) {
        List<PHOCSRiskAssessmentScoring__mdt> ratingRecords = loadRatingMetadata(FACILITY_TYPE_FOOD, facilityHA);

        if (facilityHA == 'Vancouver Coastal Health - VCH') {
            return findFoodRatingByCategory(totalScore, ratingRecords, categoryL1, categoryL2);
        }

        return findRatingByScore(totalScore, ratingRecords);
    }

/**
* @author: Deepak
* @date: 14 Jul 2026
* @description: Determines the Risk Rating for a Personal Services facility via plain score-range
* matching.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private RatingResult determinePersonalServicesRiskRating(Decimal totalScore, String facilityHA) {
        List<PHOCSRiskAssessmentScoring__mdt> ratingRecords = loadRatingMetadata(FACILITY_TYPE_PERSONAL_SERVICES, facilityHA);
        return findRatingByScore(totalScore, ratingRecords);
    }

/**
* @author: Deepak
* @date: 14 Jul 2026
* @description: Determines the Risk Rating for a Recreational Water facility via plain
* score-range matching.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private RatingResult determineRecreationalWaterRiskRating(Decimal totalScore, String facilityHA) {
        List<PHOCSRiskAssessmentScoring__mdt> ratingRecords = loadRatingMetadata(FACILITY_TYPE_RECREATIONAL_WATER, facilityHA);
        return findRatingByScore(totalScore, ratingRecords);
    }

/**
* @author: Deepak
* @date: 14 Jul 2026
* @description: Determines the Risk Rating for a Tobacco and Vapour facility via plain
* score-range matching.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private RatingResult determineTobaccoAndVapourRiskRating(Decimal totalScore, String facilityHA) {
        List<PHOCSRiskAssessmentScoring__mdt> ratingRecords = loadRatingMetadata(FACILITY_TYPE_TOBACCO_VAPOUR, facilityHA);
        return findRatingByScore(totalScore, ratingRecords);
    }

/**
* @author: Deepak
* @date: 14 Jul 2026
* @description: Finds the first Rating record whose LowScore__c/HighScore__c range contains the
* total score and that has no CategoryL1__c/CategoryL2__c set (i.e. a plain, non-categorized
* rating record).
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private RatingResult findRatingByScore(Decimal totalScore, List<PHOCSRiskAssessmentScoring__mdt> ratingRecords) {
        RatingResult result = new RatingResult();

        for (PHOCSRiskAssessmentScoring__mdt ratingRecord : ratingRecords) {
            Boolean meetsLow = ratingRecord.LowScore__c == null || totalScore >= ratingRecord.LowScore__c;
            Boolean meetsHigh = ratingRecord.HighScore__c == null || totalScore <= ratingRecord.HighScore__c;

            if (meetsLow && meetsHigh && String.isBlank(ratingRecord.CategoryL1__c) && String.isBlank(ratingRecord.CategoryL2__c)) {
                result.riskRating = ratingRecord.ResponseValue__c;
                result.inspectionFrequency = ratingRecord.InspectionFrequency__c;
                result.mtsInspectionFrequency = ratingRecord.MTSInspectionFrequency__c;
                break;
            }
        }
        return result;
    }

/**
* @author: Deepak
* @date: 14 Jul 2026
* @description: Finds the first Rating record whose LowScore__c/HighScore__c range contains the
* total score, whose CategoryL1__c matches the supplied category, and that has no
* CategoryL2__c set.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private RatingResult findRatingByScoreAndCategory(Decimal totalScore, List<PHOCSRiskAssessmentScoring__mdt> ratingRecords, String categoryL1, String categoryL2) {
        RatingResult result = new RatingResult();

        for (PHOCSRiskAssessmentScoring__mdt ratingRecord : ratingRecords) {
            Boolean meetsLow = ratingRecord.LowScore__c == null || totalScore >= ratingRecord.LowScore__c;
            Boolean meetsHigh = ratingRecord.HighScore__c == null || totalScore <= ratingRecord.HighScore__c;

            if (meetsLow && meetsHigh && ratingRecord.CategoryL1__c == categoryL1 && String.isBlank(ratingRecord.CategoryL2__c)) {
                result.riskRating = ratingRecord.ResponseValue__c;
                result.inspectionFrequency = ratingRecord.InspectionFrequency__c;
                result.mtsInspectionFrequency = ratingRecord.MTSInspectionFrequency__c;
                break;
            }
        }

        return result;
    }

/**
* @author: Deepak
* @date: 14 Jul 2026
* @description: Finds the best-matching Food Rating record within the score range, preferring an
* exact CategoryL1+CategoryL2 match, falling back to a CategoryL1-only match, and finally to a
* record with neither category set.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private RatingResult findFoodRatingByCategory(Decimal totalScore, List<PHOCSRiskAssessmentScoring__mdt> ratingRecords, String categoryL1, String categoryL2) {
        RatingResult result = new RatingResult();
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
* @author: Deepak
* @date: 14 Jul 2026
* @description: Populates the output map with totalScore, riskRating, inspectionFrequency, and
* mtsInspectionFrequency.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private void populateOutput(Map<String, Object> outMap, Decimal totalScore, String riskRating, String inspectionFrequency, String mtsInspectionFrequency) {
        outMap.put('totalScore', totalScore);
        outMap.put('riskRating', riskRating);
        outMap.put('inspectionFrequency', inspectionFrequency);
        outMap.put('mtsInspectionFrequency', mtsInspectionFrequency);
    }

/**
* @author: Deepak
* @date: 14 Jul 2026
* @description: Throws an AuraHandledException, explicitly setting its message so getMessage()
* returns the intended validation message rather than the default sanitized placeholder.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private void throwError(String message) {
        AuraHandledException ex = new AuraHandledException(message);
        ex.setMessage(message);
        throw ex;
    }
}