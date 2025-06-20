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
           
            Datetime plannedDate=System.today().addMonths(12);
                    
            List<Account> accList1 = [SELECT Id, Name, Rating, OwnerId, 
                                      (SELECT Id, Location.VisitorAddress.Address, LocationId 
                                       FROM AssociatedLocations LIMIT 1) 
                                      FROM Account WHERE Id IN: accList AND Rating != NULL WITH SECURITY_ENFORCED];
            List<InspectionType> insTypeList = [SELECT Id, Name FROM InspectionType 
                                                WHERE Name = 'Compliance Monitoring Inspection' WITH SECURITY_ENFORCED LIMIT 1];
            mapInspectionType.put('InspectionType', insTypeList.get(0).Id);

            Id complianceMonitoringTypeId = insTypeList.isEmpty() ? null : insTypeList[0].Id;

             // Query existing planned compliance monitoring visits within 12 months for the given accounts
             // if found dont create new one
            Map<Id, List<Visit>> accountToExistingVisits = new Map<Id, List<Visit>>();
            for (Visit v : [
                SELECT Id, AccountId, PlannedVisitStartTime ,name
                FROM Visit 
                WHERE AccountId IN :accList1
                AND VisitTypeId = :complianceMonitoringTypeId
                AND Status= 'Planned'
                AND  PlannedVisitStartTime >=:plannedDate
                AND  PlannedVisitStartTime <:plannedDate.addDays(1)
             
            ]) {
                if (!accountToExistingVisits.containsKey(v.AccountId)) {
                    accountToExistingVisits.put(v.AccountId, new List<Visit>());
                }
                accountToExistingVisits.get(v.AccountId).add(v);
            }
            
            
            for(Account accObj : accList1){
                Integer noOfMonths = aCCRATINGLOW.containsIgnoreCase(accObj.Rating) ? 12 : 
                aCCRATINGMEDIUM.containsIgnoreCase(accObj.Rating) ? 12 :
                aCCRATINGHIGH.containsIgnoreCase(accObj.Rating) ? 12 : 0;
                if(accObj.Rating != NULL && !accountToExistingVisits.containsKey(accObj.Id)){
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