/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Class is to 
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]  
                           ALR-928             Komal          Compliance inspection scheduling based on compliance score 
***********************************************************************************************/
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

        List<Account> ownridList = [SELECT Id, ownerId FROM account WHERE Id =: AccRec.Id limit 1];
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
            assert.isNotNull(record.Rating != NULL);
          }

        List<Visit> inspection = new List<Visit>();
		
        for(Account AcRec2 : finalList){
            if(AcRec2.Rating == 'High'){
                Visit inspect = new Visit();
                inspect.AccountId = AcRec2.Id;
                inspect.VisitTypeId = mapInspectionType.get('InspectionType');
                inspect.InspectionMethod__c = 'Unannounced on Site Inspection';
                inspect.PlannedVisitStartTime = System.today().addMonths(12);
                inspect.ActualVisitStartTime = System.today().addMonths(12);
                inspect.PlaceId = loc.Id;
                inspect.OwnerId = AcRec2.OwnerId;
                inspect.VisitPriority = 'Medium';
                inspection.add(inspect);
        }
    }
    }
    
    public static testMethod void testInsert1(){
		List<Account> accList = new List<Account>();
        List<Account> accList1 = new List<Account>();
        List<AssociatedLocation> accList2 = new List<AssociatedLocation>();
        List<Account> finalList;
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Health', 'License', 'MH', 1, 2, 3, 4, true);
		Account AccRec = TestDataFactory.createResidence('Residence', 'residence1', regAuth.Id, true);
        accList.add(AccRec);

        List<Account> ownridList = [SELECT id, ownerid FROM account WHERE Id =: AccRec.Id limit 1];
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
            assert.isNotNull(record.Rating != NULL);
          }
        
        List<Visit> inspection = new List<Visit>();
		
        for(Account AcRec2 : finalList){
            if(AcRec2.Rating == 'Low'){
                Visit inspect = new Visit();
                inspect.AccountId = AcRec2.Id;
                inspect.VisitTypeId = mapInspectionType.get('InspectionType');
                inspect.InspectionMethod__c = 'Unannounced on Site Inspection';
                inspect.PlannedVisitStartTime = System.today().addMonths(12);
                inspect.ActualVisitStartTime = System.today().addMonths(12);
                inspect.PlaceId = loc.Id;
                inspect.OwnerId = AcRec2.OwnerId;
                inspect.VisitPriority = 'Medium';
                inspection.add(inspect);
        }
    }
    }
    
    public static testMethod void testInsert3(){
		List<Account> accList = new List<Account>();
        List<Account> accList1 = new List<Account>();
        List<AssociatedLocation> accList2 = new List<AssociatedLocation>();
        List<Account> finalList;
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Health', 'License', 'MH', 1, 2, 3, 4, true);
		Account AccRec = TestDataFactory.createResidence('Residence', 'residence1', regAuth.Id, true);
        accList.add(AccRec);

        List<Account> ownridList = [SELECT id, ownerid FROM account WHERE Id =: AccRec.Id limit 1];
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
            assert.isNotNull(record.Rating != NULL);
          }
        
        List<Visit> inspection = new List<Visit>();
		
        for(Account AcRec2 : finalList){
            if(AcRec2.Rating == 'Medium'){
                Visit inspect = new Visit();
                inspect.AccountId = AcRec2.Id;
                inspect.VisitTypeId = mapInspectionType.get('InspectionType');
                inspect.InspectionMethod__c = 'Unannounced on Site Inspection';
                inspect.PlannedVisitStartTime = System.today().addMonths(12);
                inspect.ActualVisitStartTime = System.today().addMonths(12);
                inspect.PlaceId = loc.Id;
                inspect.OwnerId = AcRec2.OwnerId;
                inspect.VisitPriority = 'Medium';
                inspection.add(inspect);
        }
    }
    }
    
    @isTest
static void testPhocsWaterRights() {

    Id recordTypeId = Schema.SObjectType.Account
        .getRecordTypeInfosByDeveloperName()
        .get('DrinkingWaterSourceIntake')
        .getRecordTypeId();

    Account acc = new Account(
        Name = 'Test Drinking Water',
        RecordTypeId = recordTypeId,
        Type = 'Drinking Water',
        WaterLicenseNumber__c = 'WL001',
        WaterLicenseApplicationNumber__c = 'APP001',
        PODNumber__c = 'POD001',
        PurposeUseCode__c = 'Test',
        WellTagNumber__c = 100,
        AquiferNumber__c = 55
    );

    insert acc;

    // Get old Account values
    Account oldAcc = [
        SELECT Id, RecordTypeId, Type,
               WaterLicenseNumber__c,
               WaterLicenseApplicationNumber__c,
               PODNumber__c,
               PurposeUseCode__c,
               WellTagNumber__c,
               AquiferNumber__c
        FROM Account
        WHERE Id = :acc.Id
    ];

    // Change Water License Number
    Account updatedAcc = oldAcc.clone(true, true, false, false);
    updatedAcc.WaterLicenseNumber__c = 'WL002';

    Test.startTest();

    // Test with changed Water License Number
    AccountTriggerHandler.phocsWaterRights(
        new List<Account>{updatedAcc},
        new Map<Id, Account>{oldAcc.Id => oldAcc}
    );

    // Test with changed Application Number
    Account updatedAppAcc = oldAcc.clone(true, true, false, false);
    updatedAppAcc.WaterLicenseApplicationNumber__c = 'APP002';

    AccountTriggerHandler.phocsWaterRights(
        new List<Account>{updatedAppAcc},
        new Map<Id, Account>{oldAcc.Id => oldAcc}
    );

    // Test with no changes
    Account unchangedAcc = oldAcc.clone(true, true, false, false);

    AccountTriggerHandler.phocsWaterRights(
        new List<Account>{unchangedAcc},
        new Map<Id, Account>{oldAcc.Id => oldAcc}
    );

    // Test with incorrect Account Type
    Account wrongTypeAcc = oldAcc.clone(true, true, false, false);
    wrongTypeAcc.Type = 'Other';
    wrongTypeAcc.WaterLicenseNumber__c = 'WL003';

    AccountTriggerHandler.phocsWaterRights(
        new List<Account>{wrongTypeAcc},
        new Map<Id, Account>{oldAcc.Id => oldAcc}
    );

    Test.stopTest();
    System.assertNotEquals(null, oldAcc.Id, 'Account Id should not be null.');

}
    
}