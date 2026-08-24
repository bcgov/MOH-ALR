/**********************************************************************************************
* @Author:      Accenture 
* @Date:        14 Jul 2026
* @Description: The purpose of this class is to remote action for RAT
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
                06 Aug -  PHOCS-269         -  Accenture   -  remote action for RAT
                09 Aug -  PHOCS-269         -  Accenture   -  flatten nested question groups
***********************************************************************************************/
global without sharing class PHOCSRiskAssessmentScoringService implements Callable {

    private static final String ACTION_CALCULATE_SCORE = 'calculateScore';
    private static final String ASSESSMENT_TYPE_SCORE = 'Score';
    private static final String ASSESSMENT_TYPE_RATING = 'Rating';

/**
* @author: Deepak
* @date: 06 Aug 2026
* @description: call method for remote context.
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

    private void calculateScore(Map<String, Object> inputMap, Map<String, Object> outMap) {
        String programArea = (String) inputMap.get('facilityType');
        Object jsonInputRaw = inputMap.get('jsonInput');
        validateInput(programArea, jsonInputRaw);

        Map<String, Object> rawResponses = parseJsonInput(jsonInputRaw);
        Map<String, Object> responses = flattenResponses(rawResponses);

        List<PHOCSRiskAssessmentScoring__mdt> scoreRecords = loadScoringMetadata(programArea, ASSESSMENT_TYPE_SCORE);
        Map<String, Decimal> scoreLookup = buildScoreLookupMap(scoreRecords);
        Decimal totalScore = calculateTotalScore(responses, scoreLookup);

        List<PHOCSRiskAssessmentScoring__mdt> ratingRecords = loadScoringMetadata(programArea, ASSESSMENT_TYPE_RATING);
        RatingResult ratingResult = determineRiskRating(totalScore, ratingRecords);

        populateOutput(outMap, totalScore, ratingResult.riskRating, ratingResult.inspectionFrequency);
    }

    private void validateInput(String programArea, Object jsonInputRaw) {
        if (String.isBlank(programArea)) {
            throwError('facilityType is required.');
        }
        Boolean isBlankString = jsonInputRaw instanceof String && String.isBlank((String) jsonInputRaw);
        Boolean isEmptyMap = jsonInputRaw instanceof Map<String, Object> && ((Map<String, Object>) jsonInputRaw).isEmpty();
        if (jsonInputRaw == null || isBlankString || isEmptyMap) {
            throwError('jsonInput is required.');
        }
    }

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
* @author: Accenture
* @date: 09 Aug 2026
* @description: Recursively flattens arbitrarily nested question groups (e.g. ComplianceHistory,
* FoodHistory - names and nesting depth are not known ahead of time) into a single flat map of
* questionApiName to answer text, so grouped questions score the same as top-level ones.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private Map<String, Object> flattenResponses(Map<String, Object> responses) {
        Map<String, Object> flattened = new Map<String, Object>();
        flattenInto(responses, flattened);
        return flattened;
    }

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

    private List<PHOCSRiskAssessmentScoring__mdt> loadScoringMetadata(String programArea, String assessmentType) {
        return [SELECT QuestionAPIName__c, ResponseValue__c, Score__c, LowScore__c, HighScore__c, InspectionFrequency__c FROM PHOCSRiskAssessmentScoring__mdt 
                WHERE ProgramArea__c = :programArea AND AssessmentType__c =: assessmentType];
    }

    private Map<String, Decimal> buildScoreLookupMap(List<PHOCSRiskAssessmentScoring__mdt> records) {
        Map<String, Decimal> lookup = new Map<String, Decimal>();
        for (PHOCSRiskAssessmentScoring__mdt scoreRecord : records) {
            String key = buildLookupKey(scoreRecord.QuestionAPIName__c, scoreRecord.ResponseValue__c);
            lookup.put(key, scoreRecord.Score__c);
        }
        return lookup;
    }

    private String buildLookupKey(String questionApiName, String responseValue) {
        String question = questionApiName == null ? '' : questionApiName.trim().toUpperCase();
        String response = responseValue == null ? '' : responseValue.trim().toUpperCase();
        return question + '|' + response;
    }

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
* @author: Accenture
* @date: 06 Aug 2026
* @description: Simple carrier for the matched Rating record's ResponseValue__c and
* InspectionFrequency__c, since a single Apex method can only return one value directly.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private class RatingResult {String riskRating; String inspectionFrequency;}

    private RatingResult determineRiskRating(Decimal totalScore, List<PHOCSRiskAssessmentScoring__mdt> ratingRecords) {
        RatingResult result = new RatingResult();
        for (PHOCSRiskAssessmentScoring__mdt ratingRecord : ratingRecords) {
            Boolean meetsLow = ratingRecord.LowScore__c == null || totalScore >= ratingRecord.LowScore__c;
            Boolean meetsHigh = ratingRecord.HighScore__c == null || totalScore <= ratingRecord.HighScore__c;
            if (meetsLow && meetsHigh) {
                result.riskRating = ratingRecord.ResponseValue__c;
                result.inspectionFrequency = ratingRecord.InspectionFrequency__c;
                break;
            }
        }
        return result;
    }

    private void populateOutput(Map<String, Object> outMap, Decimal totalScore, String riskRating, String inspectionFrequency) {
        outMap.put('totalScore', totalScore);
        outMap.put('riskRating', riskRating);
        outMap.put('inspectionFrequency', inspectionFrequency);
    }

    private void throwError(String message) {
        AuraHandledException ex = new AuraHandledException(message);
        ex.setMessage(message);
        throw ex;
    }
}