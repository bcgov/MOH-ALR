/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this class is 
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
                           ALR-40              Sweta
***********************************************************************************************/
//@isTest
public class RegulatoryTrxnFeeTriggerHandlerTest {
}
    //test data setup
    /*@testSetup public static void setupData() {
        //fetch record type Ids
        Id parentAssetRTId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Units_Record_Type').getRecordTypeId();
        Id childAssetRTId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Unit_Request_Record_Type').getRecordTypeId();
        String transFeeRecTypeId = Schema.getGlobalDescribe().get('RegulatoryTrxnFee').getDescribe().getRecordTypeInfosByDeveloperName().get('TransactionFee').getRecordTypeId();
        Id feeRecTypeId;
        //RegulatoryAuthorizationType
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Helath', 'License', 'MH', 1, 2, 3, 4, true);
        
        //account - insert scenario
        Account residenceRec1 = TestDataFactory.createResidence('Residence', 'residenceAccount1', regAuth.Id, true);
        //bla
        BusinessLicenseApplication blaRec = TestDataFactory.createRenewalBla(residenceRec1.LicenseType__c, residenceRec1.Id, true); 
        //asset parent
        Asset unitRec1 = TestDataFactory.createUnit('1', 'Private', 0, residenceRec1.Id, false);
        unitRec1.recordTypeId = parentAssetRTId;
        //unitRec1.GenerateInvoice__c = true;
        unitRec1.Amount__c = 'Full Unit Fee';
        Database.Insert(unitRec1);
        //asset child
        Asset unitRec2 = TestDataFactory.createUnit('1', 'Private', 5, residenceRec1.Id, false);
        unitRec2.recordTypeId = childAssetRTId;
        unitRec2.GenerateInvoice__c = true;
        unitRec2.ParentId = unitRec1.Id;
        unitRec2.Status = BCMOH_Constants.pendingInvoiceStatus;
        Database.Insert(unitRec2);
        //asset child
        /*Asset unitRec3 = TestDataFactory.createUnit('1', 'Private', 4, residenceRec1.Id, false);
        unitRec3.recordTypeId = childAssetRTId;
        unitRec3.GenerateInvoice__c = true;
        unitRec3.ParentId = unitRec1.Id;
        unitRec3.Status = BCMOH_Constants.pendingInvoiceStatus;
        Database.Insert(unitRec3);
        //asset child
        Asset unitRec3 = TestDataFactory.createUnit('1', 'Private', 4, residenceRec1.Id, false);
        unitRec3.recordTypeId = childAssetRTId;
        unitRec3.parentId = unitRec1.Id;
        unitRec3.GenerateInvoice__c = true;
        unitRec3.Status = BCMOH_Constants.pendingInvoiceStatus;
        Database.Insert(unitRec3);
        //regTrans Fee renewal
        //RegulatoryTrxnFee regTransRec = TestDataFactory.createTransFeeRecord(transFeeRecTypeId, residenceRec1.Id, blaRec.Id, BCMOH_Constants.feeType, BCMOH_Constants.dueFeeStatus, true);
        //regTrans Fee unit
        RegulatoryTrxnFee regTransRec2 = TestDataFactory.createTransFeeRecord(transFeeRecTypeId, residenceRec1.Id, blaRec.Id, BCMOH_Constants.unitFeeType, BCMOH_Constants.dueFeeStatus, true);
        //regTransFee Item renewal
        RegulatoryTrxnFeeItem regTransItem = TestDataFactory.createTransFeeItemRecord(feeRecTypeId, regTransRec.Id, unitRec2.Id, unitRec2.Type__c, regAuth.UnitFee__c, unitRec2.Quantity, BCMOH_Constants.feeType, true);
    }
    //update scenario to paid
    @isTest
    static void updateRegulatoryTrxnFeeHandlerTest() {
        Test.startTest();
        RegulatoryTrxnFee regTransFeeRec = [SELECT Id, Status FROM RegulatoryTrxnFee limit 1];
        regTransFeeRec.Status = BCMOH_Constants.feeStatus;
        Database.Update(regTransFeeRec);
        Test.stopTest();
        RegulatoryTrxnFeeItem regFeeRec = [SELECT Id, Unit__r.Status FROM RegulatoryTrxnFeeItem
                                           WHERE RegulatoryTrxnFeeId =: regTransFeeRec.Id LIMIT 1];
        Asset assetRec = [SELECT Id, Status FROM Asset WHERE Id =: regFeeRec.Unit__c LIMIT 1];
        Assert.isTrue(regFeeRec.Unit__r.Status == BCMOH_Constants.feeStatus);
    }
    //update scenario to canceled
    @isTest
    static void updateCancelRegulatoryTrxnFeeHandlerTest() {
        Test.startTest();
        RegulatoryTrxnFee regTransFeeRec = [SELECT Id, Status FROM RegulatoryTrxnFee limit 1];
        regTransFeeRec.Status = BCMOH_Constants.cancelledStatus;
        Database.Update(regTransFeeRec);
        Test.stopTest();
        /*RegulatoryTrxnFeeItem regFeeRec = [SELECT Id, Unit__c FROM RegulatoryTrxnFeeItem
                                           WHERE RegulatoryTrxnFeeId =: regTransFeeRec.Id LIMIT 1];
        Asset assetRec = [SELECT Id, Status FROM Asset WHERE Id =: regFeeRec.Unit__c LIMIT 1];
        Assert.isTrue(assetRec.Id != NULL);
    }
}*/