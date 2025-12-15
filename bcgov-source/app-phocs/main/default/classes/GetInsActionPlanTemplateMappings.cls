/**********************************************************************************************
* @Author:Accenture_PHOCS Dev Team   
* @Date: 26-11-2025       
* @Description: The purpose of this class is to provide Inspection Action Plan Template name based on criteria defined in custom metadata mapping. (PHOCS Action Plan Template Decision Map)
* @Revision(s): [26-11-2025 ] - [V1] - [Rahul Patle] - [Created the class for the purpose of providing action plant template name based on metadata criteria]    
EHIS-2691             Anilkumar     Error while creating the inspection

***********************************************************************************************/
public with sharing class GetInsActionPlanTemplateMappings {
    
  /*  @InvocableMethod(label='Get Template Name')
    public static List<Response> resolve(List<Request> requests) {
        List<Response> results = new List<Response>();
        
        // Get all metadata records of action plan template mapping with criteria.
        Map<String, PHOCSActionPlanTemplateDecisionMap__mdt> mappingByKey = new Map<String, PHOCSActionPlanTemplateDecisionMap__mdt>();
        List<PHOCSActionPlanTemplateDecisionMap__mdt> actionTempMetadataList = [SELECT InspectionAccountType__c, InspectionType__c, ActionPlanTemplateName__c, Active__c
                                                                                FROM PHOCSActionPlanTemplateDecisionMap__mdt WHERE Active__c = TRUE];
        System.debug('###actionTempMetadataList'+actionTempMetadataList);
        for (PHOCSActionPlanTemplateDecisionMap__mdt row : actionTempMetadataList) {
            //Set up unique key for each metadata records.
            String key = row.InspectionAccountType__c + '||' + row.InspectionType__c;
            mappingByKey.put(key, row);
        }
        System.debug('###mappingByKey'+mappingByKey);
        // Check through Flow inputs 
        for (Request req : requests) {
            String lookupKey = req.AccountType + '||' + req.InspectionType;
            System.debug('###lookupKey'+lookupKey);
            // Setting up the same key that we created above for metadata
            Response r = new Response();
            // Check if metadata key value map has a match for this flow input key combination
            if (mappingByKey.containsKey(lookupKey)) {
                r.TemplateName = mappingByKey.get(lookupKey).ActionPlanTemplateName__c;
            } else {
                // If no match found the return null to flow for running existing logic on decision matrix.
                r.TemplateName = null;
            }
            
            results.add(r);
        }
        System.debug('###results'+results);
        return results;
    } */
    
    @InvocableMethod(label='Get Template Name')
    public static List<Response> resolve(List<Request> requests) {
        List<Response> results = new List<Response>();
        
        // Map of key → list of metadata rows
        Map<String, List<PHOCSActionPlanTemplateDecisionMap__mdt>> mappingByKey = new Map<String, List<PHOCSActionPlanTemplateDecisionMap__mdt>>();
        
        // Query all metadata
        List<PHOCSActionPlanTemplateDecisionMap__mdt> actionTempMetadataList = [SELECT InspectionAccountType__c, InspectionType__c, ActionPlanTemplateName__c, Active__c
                                                                                FROM PHOCSActionPlanTemplateDecisionMap__mdt WHERE Active__c = TRUE];
        
        // Build map with LISTS
        for (PHOCSActionPlanTemplateDecisionMap__mdt row : actionTempMetadataList) {
            String key = row.InspectionAccountType__c + '||' + row.InspectionType__c;
            
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