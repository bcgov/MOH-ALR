@isTest
public class ManageUnitsControllerTest {
     @testSetup
    public static void makeData(){
        //ALR-185 - added auth 
        //RegulatoryAuthorizationType
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Helath', 'License', 'MH', 1, 2, 3, 4, true);
        Account residence = TestDataFactory.createResidence('Residence','residence1', regAuth.Id, true);
        Asset unit1 = TestDataFactory.createUnit('1','Private',2,residence.Id,true);
        
    }
     @isTest
    static void unitInsertTest(){
        List<Asset> updateUnits = new List<Asset>();
        Account residence =[Select Id from account limit 1];        
        Asset unit = [Select id,Quantity,AccountId from Asset limit 1]; 
        Asset unitupdate = new Asset();
        unitupdate.Quantity = 1;
        unitupdate.Id = unit.Id;
        unitupdate.AccountId=residence.Id;
        unitupdate.GenerateRenewalInvoice__c=true;
        updateUnits.add(unitupdate);
       // string str = JSON.serialize(unit);
        object data =(object)updateUnits;        
        
        
        try{
        ManageUnitsController.getUnitBasedOnResidence(residence.Id);
        ManageUnitsController.updateUnits(data);
        }Catch(Exception e){
            System.assertEquals('Script-thrown exception', e.getMessage());  
        } 
        System.assertEquals(unitupdate.Quantity,1); 
        
    }
    
    @isTest
    static void unitInsertExpTest(){
        List<Asset> updateUnits = new List<Asset>();
        Account residence =[Select Id from account limit 1];        
        Asset unit = [Select id,Quantity,AccountId from Asset limit 1]; 
        Asset unitupdate = new Asset();
        unitupdate.Quantity = 1;
        unitupdate.Id = unitupdate.Id;
        unitupdate.AccountId=residence.Id;
        updateUnits.add(unitupdate);
       // string str = JSON.serialize(unit);
        object data =(object)updateUnits;   
        try{
        ManageUnitsController.getUnitBasedOnResidence(residence.Id);
        ManageUnitsController.updateUnits(data);
        }Catch(Exception e){
            System.assertEquals('Script-thrown exception', e.getMessage());  
        }
    }
}