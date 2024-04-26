/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Class is to calculate the Inspection Score and is called in Omniscript (RiskAssessment) and LWC (ShowRegulatoryViolationRecords)
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
                            ALR -860           Komal Gupta    Performing CAT Inspection - Part A (Inspection assessment)
***********************************************************************************************/
global with sharing class calculateInspectionScore implements Callable {
    public static String className = 'calculateInspectionScore';
    
/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is to
* @return:  Boolean
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/    
    public Object call(String action, Map<String,Object> args){
        Map<String,Object> output = (Map<String,Object>)args.get(BCMOH_Constants.IM_OUTPUT);
        Map<String,Object> options = (Map<String,Object>)args.get(BCMOH_Constants.IM_OPTIONS);
        return invokeMethod(action,args,output,options);
    }

/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is to
* @return:  Boolean
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options){
        Boolean result = false;
        try{
            if(methodName == 'getInspectionScores') {   
                getInspectionScores(inputMap, outMap); // Correct method name and pass 'outMap'
                result = true;
            }
        } catch(exception ex) {
            LogService.logAndPublish(className, 'execute', '', ex);
        }
        return result;
    }

/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is to
* @return:  Map<String, Object>
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/    
    public static Map<String, Object> getInspectionScores(Map<String,Object> inputMap, Map<String, Object> outMap){
        
        String jsonInput = Json.serialize(inputMap.get('input'));
        Map<String, Object> inputMap1 = (Map<String, Object>) JSON.deserializeUntyped(jsonInput);
        String inspectionId = (String)(inputMap1.get('InspectionId'));
        
        try {
            // Fetch all Regulatory Code Violations for the given Inspection record
            List<RegulatoryCodeViolation> rcvList = [SELECT Id, InspectionId, Scope__c, Severity__c, InspectionAssmntIndId, UserScore__c,
                                                     InspectionAssmntInd.AssessmentIndDefinition.Category__c
                                                     FROM RegulatoryCodeViolation WHERE InspectionId =: inspectionId WITH SECURITY_ENFORCED];
            
            // Initialize a map to store top Regulatory Code Violation scores category-wise
            Map<String, List<Decimal>> top3ScoresMap = new Map<String, List<Decimal>>();
            List<Decimal> scoresList = new List<Decimal>();
            List<Decimal> top3Scores = new List<Decimal>();
            Decimal score;
            String categoryKey;
            Decimal totalScore = 0;
            // Loop through each Regulatory Code Violation
            Map<Id, Id> insMap = new Map<Id, Id>();
            Map<Id, Id> assessmentMap = new Map<Id, Id>();
            for(RegulatoryCodeViolation rcv : rcvList){
                insMap.put(rcv.Id ,rcv.InspectionAssmntIndId);
            }
            
            for (RegulatoryCodeViolation rcv : rcvList) {
                if(rcv.UserScore__c != NULL){
                    score = rcv.UserScore__c;
                    categoryKey = rcv.InspectionAssmntInd.AssessmentIndDefinition.Category__c;
                } else {
                    score = 0;
                }
                if (!top3ScoresMap.containsKey(categoryKey)) {
                    top3ScoresMap.put(categoryKey, new List<Decimal>());
                }
                // Add the User Score to the list
                top3ScoresMap.get(categoryKey).add(score);
                // Keep only the top 3 scores
                scoresList = top3ScoresMap.get(categoryKey);
                scoresList.sort();
                
                if (scoresList.size() > 3) {
                    scoresList.remove(0);
                }
            }
            // Initialize a map to store the total scores for each category
            Map<String, Decimal> categoryScoreMap = new Map<String, Decimal>();
            // Loop through the top3ScoresMap and calculate the total for each category
            for (String categoryKey1 : top3ScoresMap.keySet()) {
                if(top3ScoresMap.get(categoryKey1) != NULL){
                    top3Scores = top3ScoresMap.get(categoryKey1);
                }                
                for (Decimal score1 : top3Scores) {
                    totalScore = totalScore + score1;
                } 
            } 
            // Add the categoryScoreMap to the resultMap
            outMap.put('RiskMatrix', totalScore);
            
        } catch (Exception e) {
            LogService.logAndPublish(className, 'getInspectionScores', '', e);
        }
        return outMap;
    }

/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is to
* @return:  List of RegulatoryCodeViolation
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @AuraEnabled(cacheable=true)
    public static List<RegulatoryCodeViolation> getRecords(String recordId){
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.READABLE, [SELECT Id, Scope__c, Severity__c, Description, InspectionAssmntIndId, UserScore__c,
                RegulatoryCode.Name, InspectionAssmntInd.AssessmentIndDefinition.Name, InspectionAssmntInd.AssessmentIndDefinition.Category__c
                FROM RegulatoryCodeViolation
                WHERE InspectionId =:recordId AND Inspection.VisitType.Name = 'Compliance Monitoring Inspection'] );
               return decision.getRecords();
    }  
}