@isTest
private class ManageUnitOmniServiceTest {
/*********************************************************************************************************
* Method Name:
* Purpose:
* Created By:Accenture
* Created For:
* ********************************************************************************************************/
    @isTest
    static void testMergeUnits() {
        // Test data setup
        Account residence = TestDataFactory.createResidence('Residence','residence1',true);
        
        InputWrapper.AddUnitBlock testRecord1 = new InputWrapper.AddUnitBlock();
        testRecord1.Name = 'TestUnit';
        testRecord1.AccountId = residence.Id;
        testRecord1.UnitCapacity = '3';
        testRecord1.UnitType = 'Independent Living';
        testRecord1.NoOfUnits = 5;
        testRecord1.GenerateInvoiceValue = true;
        testRecord1.AmountValue = 'Unit Fee';
        testRecord1.Status = 'Complated';
        
        InputWrapper.AddUnitBlock testRecord2 = new InputWrapper.AddUnitBlock();
        testRecord2.Name = 'TestUnit';
        testRecord2.AccountId = residence.Id;
        testRecord2.UnitCapacity = '3';
        testRecord2.UnitType = 'Independent Living';
        testRecord2.NoOfUnits = 6;
        
        InputWrapper.AddUnitBlock testRecord3 = new InputWrapper.AddUnitBlock();
        testRecord3.Name = 'TestUnit2';
        testRecord3.AccountId = residence.Id;
        testRecord3.UnitCapacity = '4';
        testRecord3.UnitType = 'Private';
        testRecord3.NoOfUnits = 3;
        
        InputWrapper unitList = new InputWrapper();
        ManageUnitOmniService unitService = new ManageUnitOmniService();
        unitList.AddUnitBlock = new List<InputWrapper.AddUnitBlock>{testRecord1, testRecord2, testRecord3};
            
        Map<String, Object> inputMap = new Map<String, Object>{BCMOH_Constants.IM_INPUT => unitList};
        Test.startTest();
        Object result = unitService.call('mergeUnits', inputMap);
        Test.stopTest();
        
        System.assertEquals(true, result, 'Expected result to be true');
        
        // Assertions on the inserted assets
       // List<Asset> insertedAssets = [SELECT Id, Name, AccountId, Capacity__c, Type__c, Quantity FROM Asset WHERE AccountId =:residence.Id];
       // System.assertEquals(2, insertedAssets.size(), 'Expected 2 Asset records to be inserted');
    }
}