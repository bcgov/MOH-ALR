/**********************************************************************************************
* @Author:Accenture_PHOCS Dev Team   
* @Date: 26-11-2025       
* @Description: The purpose of this class is to provide Inspection Action Plan Template name based on criteria defined in custom metadata mapping. (PHOCS Action Plan Template Decision Map)
* @Revision(s): [26-11-2025 ] - [V1] - [Rahul Patle] - [Created the class for the purpose of providing action plant template name based on metadata criteria]    
EHIS-2691             Anilkumar     Error while creating the inspection

***********************************************************************************************/
public with sharing class GetInsActionPlanTemplateMappings {
    @InvocableMethod(label='Get Template Name')
    public static List<Response> resolve(List<Request> requests) {
        List<Response> results = new List<Response>();
        
        // Map of key → list of metadata rows
        Map<String, List<PHOCSActionPlanTemplateDecisionMap__mdt>> mappingByKey = new Map<String, List<PHOCSActionPlanTemplateDecisionMap__mdt>>();
        
        // Query all metadata
        List<PHOCSActionPlanTemplateDecisionMap__mdt> actionTempMetadataList = [SELECT InspectionFacilityType__c, InspectionCategory__c, ActionPlanTemplateName__c, Active__c
                                                                                FROM PHOCSActionPlanTemplateDecisionMap__mdt WHERE Active__c = TRUE];
        
        // Build map with LISTS
        for (PHOCSActionPlanTemplateDecisionMap__mdt row : actionTempMetadataList) {
            String key = row.InspectionFacilityType__c + '||' + row.InspectionCategory__c;
            
            if (!mappingByKey.containsKey(key)) {
                mappingByKey.put(key, new List<PHOCSActionPlanTemplateDecisionMap__mdt>());
            }
            mappingByKey.get(key).add(row);
        }
        
        // Build Response list
        for (Request req : requests) {
            String lookupKey = req.AccountType + '||' + req.InspectionType;
            
            if (mappingByKey.containsKey(lookupKey)) {
                for (PHOCSActionPlanTemplateDecisionMap__mdt match : mappingByKey.get(lookupKey)) {
                    Response r = new Response();
                    r.TemplateName = match.ActionPlanTemplateName__c;
                    results.add(r);
                }
            } else {
                // No matches → still return one response with null
                Response r = new Response();
                r.TemplateName = null;
                results.add(r);
            }
        }        
        return results;
    }
    
    
    public class Request {
        @InvocableVariable public String AccountType;
        @InvocableVariable public String InspectionType;
    }
    
    public class Response {
        @InvocableVariable public String TemplateName;
    }
    
    
}