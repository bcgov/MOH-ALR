/**
* @Name              : AccountTrigger
* @Description       : class is to create Inspection Records
* @Author            : Komal Gupta (Accenture)
* @StoryNo           : ALR-928
**/
trigger AccountTrigger on Account (after update) {
    List<Visit> inspectList = new List<Visit>();
    Map<String, Id> mapInspectionType = new Map<String, Id>();
    Map<String, Id> mapAccount = new Map<String, Id>();
    InspectionType insType = [SELECT Id, Name FROM InspectionType WHERE Name = 'Compliance Monitoring Inspection' LIMIT 1];
    mapInspectionType.put('InspectionType', insType.Id);
    
    for(Account accObj1 : Trigger.New){
        mapAccount.put('AccountId', accObj1.Id);
    }
    List<Account> accList = [SELECT Id, Name, Rating, OwnerId, (SELECT Id, Location.VisitorAddress.Address, LocationId FROM AssociatedLocations LIMIT 1) FROM Account WHERE Rating != NULL AND Id =: mapAccount.get('AccountId')];
    for(Account accObj : accList){
        if(accObj.Rating != NULL){
            if(accObj.Rating == 'Low'){
            Visit inspection = new Visit();
            inspection.AccountId = accObj.Id;
            inspection.InspectionMethod__c = 'Unannounced on site inspection';
            inspection.VisitPriority = 'Medium';
            inspection.VisitTypeId = mapInspectionType.get('InspectionType');
            inspection.OwnerId = accObj.OwnerId;
            inspection.PlaceId = accObj.AssociatedLocations[0].LocationId;
            inspection.PlannedVisitStartTime = System.today().addMonths(3);
            inspectList.add(inspection);
    }
        else if (accObj.Rating == 'Medium'){
            Visit inspection = new Visit();
            inspection.AccountId = accObj.Id;
            inspection.InspectionMethod__c = 'Unannounced on site inspection';
            inspection.VisitPriority = 'Medium';
            inspection.VisitTypeId = mapInspectionType.get('InspectionType');
            inspection.PlaceId = accObj.AssociatedLocations[0].LocationId;
            inspection.OwnerId = accObj.OwnerId;
            inspection.PlannedVisitStartTime = System.today().addMonths(6);
            inspectList.add(inspection);
        }
        else if (accObj.Rating == 'High'){
            Visit inspection = new Visit();
            inspection.AccountId = accObj.Id;
            inspection.InspectionMethod__c = 'Unannounced on site inspection';
            inspection.VisitPriority = 'Medium';
            inspection.VisitTypeId = mapInspectionType.get('InspectionType');
            inspection.PlaceId = accObj.AssociatedLocations[0].LocationId;
            inspection.OwnerId = accObj.OwnerId;
            inspection.PlannedVisitStartTime = System.today().addMonths(12);
            inspectList.add(inspection);
        }
        }
        
    }
    if(!inspectList.isEmpty()){
    insert inspectList;
    }
}