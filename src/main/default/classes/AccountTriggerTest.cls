@isTest
public class AccountTriggerTest {
    public static testMethod void testInsert(){
        
    RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Health', 'License', 'MH', 1, 2, 3, 4, true);
	Account AcRec1 = TestDataFactory.createResidence('Residence', 'residence1', regAuth.Id, true);
       Account ownrid = [select id, ownerid from account where name ='residence1' limit 1];
        system.debug(ownrid);
        InspectionType insType = new InspectionType();
        insType.Name = 'Compliance Monitoring Inspection';
        insert insType;
         Map<String, Id> mapInspectionType = new Map<String, Id>();
        mapInspectionType.put('InspectionType', insType.Id);
        
        Schema.Location loc = new Schema.Location();
        loc.Name = 'U.S. 101N';
		loc.Longitude = 28.635308;
		loc.Latitude = 28.635308;
		insert loc;
        String insmethod = 'virtual site inspection';
       Boolean dmlmthd = true;
    Visit inspec = TestDataFactory.createinspection(AcRec1.Id,insType.Id,loc.Id,insmethod,dmlmthd);    
         inspec.OwnerId =ownrid.OwnerId;
        update inspec;
        Test.StartTest();
 		AcRec1.Rating = 'High';
       // database.update(AcRec1);
        
        System.debug('accList'+AcRec1);
        
        AcRec1 = [Select OwnerID, Owner.ID, Rating From Account where ID = :AcRec1.id];
        system.assertNOTEquals(null,AcRec1.OwnerID);
        system.assertNOTEquals(null,AcRec1.Owner.ID);
        
        List<Account> accList = new List<Account>();
        accList.add(AcRec1);
        
        List<Account> accList1 = [SELECT Id, Name, Rating, OwnerId, (SELECT Id, Location.VisitorAddress.Address, LocationId FROM AssociatedLocations WHERE LocationId =: loc.Id LIMIT 1) FROM Account WHERE Rating != NULL AND Id =: AcRec1.Id];
    	System.debug('accList'+accList1);
         Account acc = new Account(Name='Test Account', Rating='Low',LicenseType__c= regAuth.Id,Status__c = 'Registered Active with Conditions');
        insert acc;
        
        // Run trigger by updating the account
        acc.Rating = 'Medium';
       // update acc;
        AcRec1.Rating ='High';
           database.update(AcRec1);
        
        // Query the created Visit records
        List<Visit> visits = [SELECT Id, AccountId FROM Visit];
        
        // Assert that the Visit records are created as expected
        System.assertEquals(1, visits.size(), 'One Visit record should have been created');
        //System.assertEquals(acc.Id, visits[0].AccountId, 'Visit record should be associated with the Account');
        //insert inspection Type
        
        List<Visit> inspection = new List<Visit>();
		
        if(AcRec1.Rating == 'High'){
        Visit inspect = new Visit();
        inspect.AccountId = AcRec1.Id;
        inspect.VisitTypeId = insType.Id;
        inspect.InspectionMethod__c = 'Unannounced on Site Inspection';
        inspect.PlannedVisitStartTime = System.today().addMonths(12);
        inspect.PlaceId = loc.Id;
        inspect.OwnerId = AcRec1.OwnerId;
        inspect.VisitPriority = 'Medium';
        inspection.add(inspect);
        System.debug('inspection'+inspection);
        insert inspection;
            Test.StopTest();
            
            
            
        }
        
    }
}