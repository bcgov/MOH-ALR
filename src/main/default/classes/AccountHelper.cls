/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Class is to have the methods related to account trigger
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
                           ALR-928             Komal          Compliance inspection scheduling based on compliance score
***********************************************************************************************/
public with sharing class AccountHelper {
    static String className = 'AccountHelper';
/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is to create Inspection Records
* @return:  void
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static void createInspection(List<Account> accList){
        try{
            List<Visit> inspectList = new List<Visit>();
            Map<String, Id> mapInspectionType = new Map<String, Id>();
            String aCCRATINGLOW = 'Low'; 
            String aCCRATINGMEDIUM = 'Medium'; 
            String aCCRATINGHIGH = 'High'; 
            List<Account> accList1 = [SELECT Id, Name, Rating, OwnerId, 
                                      (SELECT Id, Location.VisitorAddress.Address, LocationId 
                                       FROM AssociatedLocations LIMIT 1) 
                                      FROM Account WHERE Id IN: accList AND Rating != NULL WITH SECURITY_ENFORCED];
            List<InspectionType> insTypeList = [SELECT Id, Name FROM InspectionType 
                                                WHERE Name = 'Compliance Monitoring Inspection' WITH SECURITY_ENFORCED LIMIT 1];
            mapInspectionType.put('InspectionType', insTypeList.get(0).Id);
            
            for(Account accObj : accList1){
                Integer noOfMonths = aCCRATINGLOW.containsIgnoreCase(accObj.Rating) ? 12 : 
                aCCRATINGMEDIUM.containsIgnoreCase(accObj.Rating) ? 12 :
                aCCRATINGHIGH.containsIgnoreCase(accObj.Rating) ? 12 : 0;
                if(accObj.Rating != NULL){
                    Visit inspection = new Visit();
                    inspection.AccountId = accObj.Id;
                    inspection.InspectionMethod__c = 'Unannounced on site inspection';
                    inspection.VisitPriority = 'Medium';
                    inspection.VisitTypeId = mapInspectionType.get('InspectionType');
                    inspection.OwnerId = accObj.OwnerId;
                    inspection.PlaceId = accObj.AssociatedLocations[0].LocationId;
                    inspection.PlannedVisitStartTime = System.today().addMonths(noOfMonths);
                    inspection.ActualVisitStartTime = System.today().addMonths(noOfMonths);
                    inspectList.add(inspection);
                }
            }
            if(!inspectList.isEmpty()){
                SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.CREATABLE, inspectList);
                insert securityDecision.getRecords();
            }
        }catch (Exception e) {
            LogService.logAndPublish(className, 'createInspection', '', e);
        }
    }
}