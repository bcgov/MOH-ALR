/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Class is for 
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                11-8-23    ALR-907             ACN-ALR        Validation Error is not getting populated on Remove Existing Units.      
                           ALR-185             ACN-ALR        Generating Transaction Fee  
                           ALR-726             ACN-ALR        Issues on Business License Application and Regulatory Fee                  
***********************************************************************************************/
@isTest
public class ManageUnitsControllerTest {
    
     @testSetup
    public static void makeData(){
        Id parentAssetRTId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Units_Record_Type').getRecordTypeId();
        //ALR-185 - added auth 
        //RegulatoryAuthorizationType
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Helath', 'License', 'MH', 1, 2, 3, 4, true);
        Account residence = TestDataFactory.createResidence('Residence','residence1', regAuth.Id, true);
        BusinessLicenseApplication blaRec = TestDataFactory.createRenewalBla(residence.LicenseType__c, residence.Id, true);
        Asset unit1 = TestDataFactory.createUnit('1','Private',2,residence.Id,true);
        Asset unit2 = TestDataFactory.createUnit('1','Public',2,residence.Id,true);
        unit1.recordTypeId = parentAssetRTId;
        unit2.recordTypeId = parentAssetRTId;
        update unit1;
        update unit2;
        
    }
     @isTest
    static void unitInsertTest(){
        List<Asset> updateUnits = new List<Asset>();
        Account residence =[SELECT Id FROM account WHERE RecordTypeId = :Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Registrant').getRecordTypeId() limit 1];        
        Asset unit = [SELECT id,Quantity,AccountId FROM Asset limit 1]; 
        Asset unitupdate = new Asset();
        unitupdate.Quantity = 1;
        unitupdate.Id = unit.Id;
        unitupdate.AccountId=unit.AccountId;
        unitupdate.GenerateRenewalInvoice__c=true;
        
        updateUnits.add(unitupdate);
        object data =(object)updateUnits;   
        Asset unit2 = [SELECT id,AccountId FROM Asset WHERE Type__c='Public' limit 1];   
               
        try{
        ManageUnitsController.getUnitBasedOnResidence(residence.Id);
        ManageUnitsController.updateUnits(updateUnits);
        unitupdate.GenerateInvoice__c= true;
        unitupdate.ParentId=unit2.id;
        unitupdate.AccountId=unit2.AccountId;
        unitupdate.Status='Pending Invoice';
        unitupdate.recordTypeId=Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Unit_Request_Record_Type').getRecordTypeId();
        Asset unitupdate2 = new Asset();
        unitupdate2.Quantity = 1;
        unitupdate2.Id = unit.Id;
        unitupdate2.AccountId=unit.AccountId;
        unitupdate2.Type__c='Public';
        unitupdate2.recordTypeId=Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Unit_Request_Record_Type').getRecordTypeId();
        unitupdate2.GenerateRenewalInvoice__c=true;
        
        updateUnits.add(unitupdate2);
       
        data =(object)updateUnits;
           
        GenerateInvoiceController.generateInvoices(updateUnits);
        }Catch(Exception e){
            Assert.areEqual('Script-thrown exception', e.getMessage());  
        } 
        Assert.areEqual(unitupdate.Quantity,1); 
    }
    
    @isTest
    static void unitInsertExpTest(){
        List<Asset> updateUnits = new List<Asset>();
        Account residence =[SELECT Id FROM account limit 1];        
        Asset unit = [SELECT id,Quantity,AccountId FROM Asset limit 1]; 
        Asset unitupdate = new Asset();
        unitupdate.Quantity = 1;
        unitupdate.Id = unitupdate.Id;
        unitupdate.AccountId=residence.Id;
        updateUnits.add(unitupdate);
        object data =(object)updateUnits;   
        try{
        ManageUnitsController.getUnitBasedOnResidence(residence.Id);
        ManageUnitsController.updateUnits(data);
        }Catch(Exception e){
            Assert.areEqual('Script-thrown exception', e.getMessage());  
        }
    }
}