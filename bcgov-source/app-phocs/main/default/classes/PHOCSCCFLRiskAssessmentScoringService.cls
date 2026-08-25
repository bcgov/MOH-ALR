/**********************************************************************************************
* @Author:      Accenture
* @Date:        25 Aug 2026
* @Description: Remote action for Risk Assessments that combine a Part A violation-matrix score
*               (Risk Matrix + Interval Score Table) with a Part B question-based score, e.g. the CCFL/Tobacco and Vapour RAT.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
*               25 Aug - PHOCS-4817         -  Deepak      - Remote action for CCFL RAT
***********************************************************************************************/
global with sharing class PHOCSCCFLRiskAssessmentScoringService implements Callable {
    
    private static final String ACTION_CALCULATE_SCORE = 'calculateScore';
    private static final String ASSESSMENT_TYPE_RISK_MATRIX = 'RiskMatrix';
    private static final String ASSESSMENT_TYPE_SCORE = 'Score';
    private static final String ASSESSMENT_TYPE_INTERVAL_SCORE = 'IntervalScore';
    private static final String ASSESSMENT_TYPE_RATING = 'Rating';
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: call method for remote context. Validates the action and arguments, then
*              dispatches to calculateScore().
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    global Object call(String action, Map<String, Object> args) {
        if (String.isBlank(action)) {
            throw buildException('Callable action is required.');
        }
        if (args == null) {
            throw buildException('Callable arguments are required.');
        }
        if (ACTION_CALCULATE_SCORE.equalsIgnoreCase(action)) {
            return calculateScore(args);
        }
        throw buildException('Unsupported callable action: ' + action);
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Unwraps the Callable args map into input/output/options, tolerating either the
*              standard {input, output, options} wrapper shape or a flat args map used directly as input.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public Object calculateScore(Map<String, Object> args) {
        Map<String, Object> input = args.containsKey('input') && args.get('input') instanceof Map<String, Object> ? (Map<String, Object>) args.get('input') : args;
        Map<String, Object> output = args.containsKey('output') && args.get('output') instanceof Map<String, Object> ? (Map<String, Object>) args.get('output') : new Map<String, Object>();
        Map<String, Object> options = args.containsKey('options') && args.get('options') instanceof Map<String, Object> ? (Map<String, Object>) args.get('options') : new Map<String, Object>();
        
        calculateScore(input, output, options);
        return output;
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Core scoring flow - resolves the facility type, loads all relevant scoring
*              metadata in a single query, computes Part A (Risk Matrix -> Interval Score) and Part B
*              (question-based) scores, determines the overall Risk Rating from the combined total, and
*              populates the output map.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public void calculateScore(Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) {
        if (input == null) {
            throw buildException('Input is required.');
        }
        
        String facilityType = getStringValue(input.get('facilityType'));
        
        if (String.isBlank(facilityType)) {
            throw buildException('Facility Type is required.');
        }
        
        List<Object> selectedViolations = getListValue(input.get('selectedViolations'));
        Map<String, Object> partBAnswers = getMapValue(input.get('PartBThreeYearOperationalHistoryAssessment'));
        
        Map<String, List<PHOCSRiskAssessmentScoring__mdt>> scoringMetadata = loadScoringMetadata(facilityType);
        
        Decimal partAMatrixScore = calculatePartAMatrixScore(selectedViolations, scoringMetadata.get(ASSESSMENT_TYPE_RISK_MATRIX));
        Decimal partAScore = calculateIntervalScore(partAMatrixScore, scoringMetadata.get(ASSESSMENT_TYPE_INTERVAL_SCORE));
        
        Decimal partBScore = calculatePartBScore(partBAnswers, scoringMetadata.get(ASSESSMENT_TYPE_SCORE));
        
        Decimal totalScore = partAScore + partBScore;
        
        PHOCSRiskAssessmentScoring__mdt ratingMetadata = getRatingMetadata(totalScore, scoringMetadata.get(ASSESSMENT_TYPE_RATING));
        
        String riskRating = ratingMetadata == null ? null : ratingMetadata.ResponseValue__c;
        String inspectionFrequency = ratingMetadata == null ? null : ratingMetadata.InspectionFrequency__c;
        
        populateOutput(output, partAMatrixScore, partAScore, partBScore, totalScore, riskRating, inspectionFrequency);
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Loads every PHOCSRiskAssessmentScoring__mdt record for the given facility type
*              across all four assessment types in one query, and buckets the results by AssessmentType__c.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private Map<String, List<PHOCSRiskAssessmentScoring__mdt>> loadScoringMetadata(String facilityType) {
        List<PHOCSRiskAssessmentScoring__mdt> records = [SELECT DeveloperName, MasterLabel, ProgramArea__c, AssessmentType__c, QuestionAPIName__c, ResponseValue__c, Score__c, LowScore__c, HighScore__c, InspectionFrequency__c FROM PHOCSRiskAssessmentScoring__mdt WHERE ProgramArea__c = :facilityType AND AssessmentType__c IN :new Set<String>{ASSESSMENT_TYPE_RISK_MATRIX, ASSESSMENT_TYPE_SCORE, ASSESSMENT_TYPE_INTERVAL_SCORE, ASSESSMENT_TYPE_RATING}];
        
        Map<String, List<PHOCSRiskAssessmentScoring__mdt>> metadataByType = new Map<String, List<PHOCSRiskAssessmentScoring__mdt>>();
        
        for (PHOCSRiskAssessmentScoring__mdt record : records) {
            if (!metadataByType.containsKey(record.AssessmentType__c)) {
                metadataByType.put(record.AssessmentType__c, new List<PHOCSRiskAssessmentScoring__mdt>());
            }
            metadataByType.get(record.AssessmentType__c).add(record);
        }
        
        return metadataByType;
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Sums the Risk Matrix output (Severity x Scope -> Score__c) across every
*              selected violation. Returns 0 when there are no violations; throws when violations exist but
*              no Risk Matrix metadata is configured, a violation is missing Severity/Scope, or a specific
*              Severity/Scope combination has no matching metadata.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private Decimal calculatePartAMatrixScore(List<Object> selectedViolations, List<PHOCSRiskAssessmentScoring__mdt> riskMatrixRecords) {
        Decimal totalScore = 0;
        
        if (selectedViolations == null || selectedViolations.isEmpty()) {
            return totalScore;
        }        
        if (riskMatrixRecords == null || riskMatrixRecords.isEmpty()) {
            throw buildException('No Risk Matrix scoring metadata was found for the selected facility type.');
        }
        
        Map<String, Decimal> scoreByResponse = new Map<String, Decimal>();
        
        for (PHOCSRiskAssessmentScoring__mdt record : riskMatrixRecords) {
            String key = buildMatrixKey(record.QuestionAPIName__c, record.ResponseValue__c);            
            if (record.Score__c != null) {
                scoreByResponse.put(key, record.Score__c);
            }
        }
        
        for (Object violationObject : selectedViolations) {
            if (!(violationObject instanceof Map<String, Object>)) {
                continue;
            }
            
            Map<String, Object> violation = (Map<String, Object>) violationObject;            
            String severity = getStringValue(violation.get('severity'));
            String scope = getStringValue(violation.get('scope'));            
            if (String.isBlank(severity) || String.isBlank(scope)) {
                throw buildException('Every selected violation must have both Scope and Severity.');
            }
            
            String key = buildMatrixKey(severity, scope);            
            if (!scoreByResponse.containsKey(key)) {
                throw buildException('No Risk Matrix scoring metadata was found for Severity "' + severity + '" and Scope "' + scope + '".');
            }            
            totalScore += scoreByResponse.get(key);
        }
        
        return totalScore;
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Converts the summed Part A matrix score into the Interval Score using
*              LowScore__c/HighScore__c-bounded IntervalScore records. Throws when no Interval Score
*              metadata is configured for the facility type, or when the matrix score falls outside every
*              configured range.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private Decimal calculateIntervalScore(Decimal partAMatrixScore, List<PHOCSRiskAssessmentScoring__mdt> intervalRecords) {
        if (partAMatrixScore == null) {
            return 0;
        }
        
        if (intervalRecords == null || intervalRecords.isEmpty()) {
            throw buildException('No Interval Score metadata was found for the selected facility type.');
        }
        
        for (PHOCSRiskAssessmentScoring__mdt record : intervalRecords) {
            if (record.LowScore__c == null || record.HighScore__c == null || record.Score__c == null) {
                continue;
            }
            
            if (partAMatrixScore >= record.LowScore__c && partAMatrixScore <= record.HighScore__c) {
                return record.Score__c;
            }
        }
        
        throw buildException('No Interval Score configuration was found for Part A Matrix Score ' + String.valueOf(partAMatrixScore) + '.');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Sums Part B question scores by matching QuestionAPIName__c/ResponseValue__c
*              Score records against the submitted answers. Unanswered or unconfigured questions are
*              skipped silently; an answered question with a configured metadata set but no matching
*              response value throws.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private Decimal calculatePartBScore(Map<String, Object> partBAnswers, List<PHOCSRiskAssessmentScoring__mdt> scoreRecords) {
        Decimal totalScore = 0;        
        if (partBAnswers == null || partBAnswers.isEmpty()) {
            return totalScore;
        }        
        if (scoreRecords == null || scoreRecords.isEmpty()) {
            return totalScore;
        }
        
        Map<String, Map<String, Decimal>> scoreMap = new Map<String, Map<String, Decimal>>();
        
        for (PHOCSRiskAssessmentScoring__mdt record : scoreRecords) {
            if (String.isBlank(record.QuestionAPIName__c) || String.isBlank(record.ResponseValue__c) || record.Score__c == null) {
                continue;
            }
            
            if (!scoreMap.containsKey(record.QuestionAPIName__c)) {
                scoreMap.put(record.QuestionAPIName__c, new Map<String, Decimal>());
            }
            
            scoreMap.get(record.QuestionAPIName__c).put(record.ResponseValue__c, record.Score__c);
        }
        
        for (String questionApiName : partBAnswers.keySet()) {
            Object answerObject = partBAnswers.get(questionApiName);
            
            if (answerObject == null) {
                continue;
            }
            
            String answer = getStringValue(answerObject);
            
            if (String.isBlank(answer)) {
                continue;
            }
            
            if (!scoreMap.containsKey(questionApiName)) {
                continue;
            }
            
            Map<String, Decimal> responseScores = scoreMap.get(questionApiName);
            
            if (!responseScores.containsKey(answer)) {
                throw buildException('No Part B scoring metadata was found for Question "' + questionApiName + '" and Response "' + answer + '".');
            }
            
            totalScore += responseScores.get(answer);
        }
        
        return totalScore;
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Finds the Rating record whose LowScore__c/HighScore__c range contains the
*              combined total score. Throws when no Rating metadata is configured for the facility type, or
*              when the total score falls outside every configured range.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private PHOCSRiskAssessmentScoring__mdt getRatingMetadata(Decimal totalScore, List<PHOCSRiskAssessmentScoring__mdt> ratingRecords) {
        if (ratingRecords == null || ratingRecords.isEmpty()) {
            throw buildException('No Risk Rating metadata was found for the selected facility type.');
        }
        
        for (PHOCSRiskAssessmentScoring__mdt record : ratingRecords) {
            if (record.LowScore__c == null || record.HighScore__c == null) {
                continue;
            }
            
            if (totalScore >= record.LowScore__c && totalScore <= record.HighScore__c) {
                return record;
            }
        }
        
        throw buildException('No Risk Rating configuration was found for Total Score ' + String.valueOf(totalScore) + '.');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Populates the output map with the Part A matrix total, Part A interval score,
*              Part B score, combined total score, Risk Rating, and Inspection Frequency.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private void populateOutput(Map<String, Object> outMap, Decimal partAMatrixScore, Decimal partAScore, Decimal partBScore, Decimal totalScore, String riskRating, String inspectionFrequency) {
        outMap.put('PartAMatrixScore', partAMatrixScore);
        outMap.put('PartAScore', partAScore);
        outMap.put('PartBScore', partBScore);
        outMap.put('TotalScore', totalScore);
        outMap.put('RiskRating', riskRating);
        outMap.put('InspectionFrequency', inspectionFrequency);
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Builds a case-insensitive lookup key for Risk Matrix Severity/Scope pairs.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private String buildMatrixKey(String questionApiName, String responseValue) {
        return String.valueOf(questionApiName).trim().toLowerCase() + '|' + String.valueOf(responseValue).trim().toLowerCase();
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Safely converts an Object to a trimmed String, returning null for null input.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private String getStringValue(Object value) {
        return value == null ? null : String.valueOf(value).trim();
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Safely casts an Object to a List<Object>, returning an empty list for null or
*              any non-list value.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private List<Object> getListValue(Object value) {
        if (value == null) {
            return new List<Object>();
        }
        
        if (value instanceof List<Object>) {
            return (List<Object>) value;
        }
        
        return new List<Object>();
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Safely casts an Object to a Map<String, Object>, returning an empty map for null or
*              any non-map value.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private Map<String, Object> getMapValue(Object value) {
        if (value == null) {
            return new Map<String, Object>();
        }
        
        if (value instanceof Map<String, Object>) {
            return (Map<String, Object>) value;
        }
        
        return new Map<String, Object>();
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Creates an AuraHandledException and explicitly sets its message so that
*              getMessage() returns the intended validation message in tests and runtime.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static AuraHandledException buildException(String message) {
        AuraHandledException auraException = new AuraHandledException(message);
        auraException.setMessage(message);
        return auraException;
    }
}