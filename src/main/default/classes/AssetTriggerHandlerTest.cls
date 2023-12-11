/**
* @Name              : AssetTriggerHandlerTest
* @Description       : Test class for AssetTriggerHandler and AssetTriggerUtility
* @Author            : Sweta (Accenture)
* @StoryNo           : ALR-40
**/
@isTest
public class AssetTriggerHandlerTest {
    //test data setup
    @testSetup public static void setupData() {
        //fetch record type Ids
        Id parentAssetRTId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Units_Record_Type').getRecordTypeId();
        Id childAssetRTId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Unit_Request_Record_Type').getRecordTypeId();
        
        //RegulatoryAuthorizationType
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Helath', 'License', 'MH', 1, 2, 3, 4, true);
        
        //account - insert scenario
        Account residenceRec1 = TestDataFactory.createResidence('Residence', 'residenceAccount1',true);
        //bla
        BusinessLicenseApplication blaRec = TestDataFactory.createRenewalBla(residenceRec1.ClassType__c, residenceRec1.Id, true); 
        //asset parent
        Asset unitRec1 = TestDataFactory.createUnit('1', 'Private', 5, residenceRec1.Id, false);
        unitRec1.recordTypeId = parentAssetRTId;
        unitRec1.GenerateInvoice__c = true;
        unitRec1.Amount__c = 'Unit Fee';
        Database.Insert(unitRec1);
        
        //account 2 - remove/update scenario
        Account residenceRec2 = TestDataFactory.createResidence('Residence', 'residenceAccount2', true);
        //bla 2
        BusinessLicenseApplication blaRec2 = TestDataFactory.createRenewalBla(residenceRec2.ClassType__c, residenceRec2.Id, true); 
        //asset Parent 2      
        Asset unitRec3 = TestDataFactory.createUnit('1', 'Public', 3, residenceRec2.Id, false);
        unitRec3.recordTypeId = parentAssetRTId;
        unitRec3.Amount__c = 'Partial Unit Fee';
        Database.Insert(unitRec3);
        //asset child 3
        Asset unitRec4 = TestDataFactory.createUnit('1', 'Public', 3, residenceRec2.Id, false);
        unitRec4.recordTypeId = childAssetRTId;
        unitRec4.parentId = unitRec3.Id;
        Database.Insert(unitRec4);
        
        //account 3
        Account residenceRec3 = TestDataFactory.createResidence('Residence', 'residenceAccount3',true);
        Asset unitRec5 = TestDataFactory.createUnit('1', 'Private', 5, residenceRec3.Id, true);
    }
    //insert scenario
    @isTest
    static void insertAssetHandlerTest() {
        List<Asset> assetList = new List<Asset>();
        Id childAssetRTId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Unit_Request_Record_Type').getRecordTypeId();
        Account accRec = [SELECT Id FROM Account WHERE Name = 'residenceAccount1' LIMIT 1];
        Asset parentAssetRec = [SELECT Id FROM Asset WHERE AccountId =: accRec.Id LIMIT 1];
        Test.startTest();
        Asset assetRec = TestDataFactory.createUnit('1', 'Private', 2, accRec.Id, false);
        assetRec.GenerateInvoice__c = true;
        assetRec.recordTypeId = childAssetRTId;
        assetRec.ParentId = parentAssetRec.Id;
        Asset assetRec2 = TestDataFactory.createUnit('1', 'Private', 3, accRec.Id, false);
        assetRec2.GenerateInvoice__c = true;
        assetRec2.recordTypeId = childAssetRTId;
        assetRec2.ParentId = parentAssetRec.Id;
        assetRec2.Status = BCMOH_Constants.pendingInvoiceStatus;
        assetList.add(assetRec);
        assetList.add(assetRec2);
        Database.Insert(assetList, false);
        Test.stopTest();
        RegulatoryTrxnFeeItem regFeeRec = [SELECT Id FROM RegulatoryTrxnFeeItem LIMIT 1];
        Assert.isTrue(regFeeRec.Id != NULL);
    }
    //update scenario
    @isTest
    static void updateAssetHandlerTest() {
        List<Asset> assetList = new List<Asset>();
        Id parentAssetRTId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Units_Record_Type').getRecordTypeId();        Account accRec = [SELECT Id FROM Account WHERE Name = 'residenceAccount1' LIMIT 1];
        Account accRec1 = [SELECT Id FROM Account WHERE Name = 'residenceAccount2' LIMIT 1];
        Asset parentAssetRec = [SELECT Id FROM Asset WHERE AccountId =: accRec1.Id 
                                AND recordTypeId =: parentAssetRTId LIMIT 1];
        Test.startTest();
        parentAssetRec.GenerateRenewalInvoice__c = true;
        parentAssetRec.Quantity = 2;
        Database.Update(parentAssetRec);
        Test.stopTest();
        RegulatoryTrxnFeeItem regFeeRec = [SELECT Id, Unit__r.RecordTypeId FROM RegulatoryTrxnFeeItem LIMIT 1];
        Assert.areEqual(regFeeRec.Unit__r.RecordTypeId, parentAssetRTId);
    }
    //delete scenario
    @isTest
    static void deleteAssetHandlerTest() {
        Test.startTest();
        Asset assetRec = [SELECT Id, isDeleted FROM Asset WHERE Account.Name = 'residenceAccount3' LIMIT 1];
        Database.DeleteResult drRec = Database.delete(assetRec, false);
        Database.UndeleteResult udRec = Database.undelete(assetRec, false);
        Test.stopTest();
        Assert.isTrue(drRec.isSuccess());
    }
}