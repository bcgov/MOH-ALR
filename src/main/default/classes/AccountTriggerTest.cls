/**
* @Name              : AccountTriggerTest
* @Description       : Test class of AccountTrigger and AccountHelper
* @Author            : Komal Gupta (Accenture)
* @StoryNo           : ALR-928
**/
@isTest
public class AccountTriggerTest {
    public static testMethod void testInsert(){
		List<Account> accList = new List<Account>();
        List<Account> accList1 = new List<Account>();
        List<AssociatedLocation> accList2 = new List<AssociatedLocation>();
        List<Account> finalList;
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Health', 'License', 'MH', 1, 2, 3, 4, true);
		Account AccRec = TestDataFactory.createResidence('Residence', 'residence1', regAuth.Id, true);
        accList.add(AccRec);

        List<Account> ownridList = [select id, ownerid from account where Id =: AccRec.Id limit 1];
        accList.addAll(ownridList);
        accList.sort();

        Schema.Location loc = new Schema.Location();
        loc.Name = 'U.S. 101N';
		loc.Longitude = 28.635308;
		loc.Latitude = 28.635308;
		insert loc;
        
        for(Account acc1 : accList){
            AssociatedLocation assosicatedloc = new AssociatedLocation();
            assosicatedloc.ParentRecordId = acc1.Id;
            assosicatedloc.LocationId = loc.Id;
            accList2.add(assosicatedloc);
        }
        insert accList2;
        
        Set<Id> AccSet= new Set<Id>();
        for(Account acc : accList){
            AccSet.add(acc.Id);
        }
        InspectionType insType = new InspectionType();
        insType.Name = 'Compliance Monitoring Inspection';
        insert insType;
        Map<String, Id> mapInspectionType = new Map<String, Id>();
        mapInspectionType.put('InspectionType', insType.Id);
        
        finalList = [SELECT Id, Name, Rating, OwnerId, (SELECT Id, Location.VisitorAddress.Address, LocationId FROM AssociatedLocations LIMIT 1) FROM Account WHERE  Id IN : AccSet];
        
        for(Account accRec1 : finalList){
            accRec1.Rating = 'High';
            accList1.add(accRec1);
        }
        Test.startTest();
        update accList1;
        Test.stopTest();
        
        for(Account record: accList1) {
            System.assert(record.Rating != NULL);
          }

        List<Visit> inspection = new List<Visit>();
		
        for(Account AcRec2 : finalList){
            if(AcRec2.Rating == 'High'){
                Visit inspect = new Visit();
                inspect.AccountId = AcRec2.Id;
                inspect.VisitTypeId = mapInspectionType.get('InspectionType');
                inspect.InspectionMethod__c = 'Unannounced on Site Inspection';
                inspect.PlannedVisitStartTime = System.today().addMonths(12);
                inspect.PlaceId = loc.Id;
                inspect.OwnerId = AcRec2.OwnerId;
                inspect.VisitPriority = 'Medium';
                inspection.add(inspect);
        }
    }
        Database.update(inspection, false);
    }
    
    public static testMethod void testInsert1(){
		List<Account> accList = new List<Account>();
        List<Account> accList1 = new List<Account>();
        List<AssociatedLocation> accList2 = new List<AssociatedLocation>();
        List<Account> finalList;
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Health', 'License', 'MH', 1, 2, 3, 4, true);
		Account AccRec = TestDataFactory.createResidence('Residence', 'residence1', regAuth.Id, true);
        accList.add(AccRec);

        List<Account> ownridList = [select id, ownerid from account where Id =: AccRec.Id limit 1];
        accList.addAll(ownridList);
        accList.sort();

        Schema.Location loc = new Schema.Location();
        loc.Name = 'U.S. 101N';
		loc.Longitude = 28.635308;
		loc.Latitude = 28.635308;
		insert loc;
        
        for(Account acc1 : accList){
            AssociatedLocation assosicatedloc = new AssociatedLocation();
            assosicatedloc.ParentRecordId = acc1.Id;
            assosicatedloc.LocationId = loc.Id;
            accList2.add(assosicatedloc);
        }
        insert accList2;
        
        Set<Id> AccSet= new Set<Id>();
        for(Account acc : accList){
            AccSet.add(acc.Id);
        }
        
        InspectionType insType = new InspectionType();
        insType.Name = 'Compliance Monitoring Inspection';
        insert insType;
        Map<String, Id> mapInspectionType = new Map<String, Id>();
        mapInspectionType.put('InspectionType', insType.Id);
        
        finalList = [SELECT Id, Name, Rating, OwnerId, (SELECT Id, Location.VisitorAddress.Address, LocationId FROM AssociatedLocations LIMIT 1) FROM Account WHERE  Id IN : AccSet];
        
        for(Account accRec1 : finalList){
            accRec1.Rating = 'Low';
            accList1.add(accRec1);
        }
        Test.startTest();
        update accList1;
        Test.stopTest();
        
        for(Account record: accList1) {
            System.assert(record.Rating != NULL);
          }
        
        List<Visit> inspection = new List<Visit>();
		
        for(Account AcRec2 : finalList){
            if(AcRec2.Rating == 'Low'){
                Visit inspect = new Visit();
                inspect.AccountId = AcRec2.Id;
                inspect.VisitTypeId = mapInspectionType.get('InspectionType');
                inspect.InspectionMethod__c = 'Unannounced on Site Inspection';
                inspect.PlannedVisitStartTime = System.today().addMonths(3);
                inspect.PlaceId = loc.Id;
                inspect.OwnerId = AcRec2.OwnerId;
                inspect.VisitPriority = 'Medium';
                inspection.add(inspect);
        }
    }
        Database.update(inspection, false);
    }
    
    public static testMethod void testInsert3(){
		List<Account> accList = new List<Account>();
        List<Account> accList1 = new List<Account>();
        List<AssociatedLocation> accList2 = new List<AssociatedLocation>();
        List<Account> finalList;
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Health', 'License', 'MH', 1, 2, 3, 4, true);
		Account AccRec = TestDataFactory.createResidence('Residence', 'residence1', regAuth.Id, true);
        accList.add(AccRec);

        List<Account> ownridList = [select id, ownerid from account where Id =: AccRec.Id limit 1];
        accList.addAll(ownridList);
        accList.sort();

        Schema.Location loc = new Schema.Location();
        loc.Name = 'U.S. 101N';
		loc.Longitude = 28.635308;
		loc.Latitude = 28.635308;
		insert loc;
        
        for(Account acc1 : accList){
            AssociatedLocation assosicatedloc = new AssociatedLocation();
            assosicatedloc.ParentRecordId = acc1.Id;
            assosicatedloc.LocationId = loc.Id;
            accList2.add(assosicatedloc);
        }
        insert accList2;
        
        Set<Id> AccSet= new Set<Id>();
        for(Account acc : accList){
            AccSet.add(acc.Id);
        }
        
        InspectionType insType = new InspectionType();
        insType.Name = 'Compliance Monitoring Inspection';
        insert insType;
        Map<String, Id> mapInspectionType = new Map<String, Id>();
        mapInspectionType.put('InspectionType', insType.Id);
        
        finalList = [SELECT Id, Name, Rating, OwnerId, (SELECT Id, Location.VisitorAddress.Address, LocationId FROM AssociatedLocations LIMIT 1) FROM Account WHERE  Id IN : AccSet];
        
        for(Account accRec1 : finalList){
            accRec1.Rating = 'Medium';
            accList1.add(accRec1);
        }
        Test.startTest();
        update accList1;
        Test.stopTest();
        
        for(Account record: accList1) {
            System.assert(record.Rating != NULL);
          }
        
        List<Visit> inspection = new List<Visit>();
		
        for(Account AcRec2 : finalList){
            if(AcRec2.Rating == 'Medium'){
                Visit inspect = new Visit();
                inspect.AccountId = AcRec2.Id;
                inspect.VisitTypeId = mapInspectionType.get('InspectionType');
                inspect.InspectionMethod__c = 'Unannounced on Site Inspection';
                inspect.PlannedVisitStartTime = System.today().addMonths(6);
                inspect.PlaceId = loc.Id;
                inspect.OwnerId = AcRec2.OwnerId;
                inspect.VisitPriority = 'Medium';
                inspection.add(inspect);
        }
    }
        Database.update(inspection, false);
    }
}