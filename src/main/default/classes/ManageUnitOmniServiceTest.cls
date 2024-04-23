/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Class is for 
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                12-4-23                        ChangeMeIn@UserSettingsUnder.SFDoc
                           ALR-185             ACN-ALR        Generating Transaction Fee  
                           ALR-726             ACN-ALR        Issues on Business License Application and Regulatory Fee            
***********************************************************************************************/
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
        //ALR-185 - added auth 
        //RegulatoryAuthorizationType
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Helath', 'License', 'MH', 1, 2, 3, 4, true);
 
        Account residence = TestDataFactory.createResidence('Residence','residence1', regAuth.Id, true);
        
        InputWrapper.AddUnitBlock testRecord1 = new InputWrapper.AddUnitBlock();
        testRecord1.Name = 'TestUnit';
        testRecord1.AccountId = residence.Id;
        testRecord1.UnitCapacity = '3';
        testRecord1.UnitType = 'Independent Living';
        testRecord1.NoOfUnits = 5;
        testRecord1.GenerateInvoiceValue = true;
        testRecord1.AmountValue = 'Unit Fee';
        testRecord1.Description = 'Unit Fee provided';
        testRecord1.Status = 'Waived';
        
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
        
        //ALR-726
        InputWrapper.AddUnitBlock testRecord5 = new InputWrapper.AddUnitBlock();
        testRecord5.Name = 'TestUnit';
        testRecord5.AccountId = residence.Id;
        testRecord5.UnitCapacity = '3';
        testRecord5.UnitType = 'Public';
        testRecord5.NoOfUnits = 5;
        testRecord5.GenerateInvoiceValue = true;
        testRecord5.AmountValue = 'Full Unit Fee';
        testRecord5.Status = 'Waived';
        
        InputWrapper unitList = new InputWrapper();
        ManageUnitOmniService unitService = new ManageUnitOmniService();
        unitList.AddUnitBlock = new List<InputWrapper.AddUnitBlock>{testRecord1, testRecord2, testRecord3, testRecord5};
            
        InputWrapper.AddUnitBlock testRecord4 = new InputWrapper.AddUnitBlock();
        testRecord4.Name = 'TestUnit2';
        testRecord4.AccountId = residence.Id;
        testRecord4.UnitCapacity = '4';
        testRecord4.UnitType = 'Private';
        testRecord4.NoOfUnits = 13;
        InputWrapper unitList1 = new InputWrapper();
        ManageUnitOmniService unitService1 = new ManageUnitOmniService();
        unitList1.AddUnitBlock = new List<InputWrapper.AddUnitBlock>{testRecord4};
            
        Map<String, Object> inputMap = new Map<String, Object>{BCMOH_Constants.IM_INPUT => unitList};
        Map<String, Object> inputMap1 = new Map<String, Object>{BCMOH_Constants.IM_INPUT => unitList1};
        Test.startTest();
        Object result = unitService.call('mergeUnits', inputMap);
        Object result1 = unitService1.call('mergeUnits', inputMap1);
        //Test.stopTest();
        
        Assert.areEqual(true, result, 'Expected result to be true');
        //Test.startTest();
        RegulatoryTrxnFee regTransFeeRec = [SELECT Id, Status FROM RegulatoryTrxnFee limit 1];
        system.debug('ghh'+regTransFeeRec);
        regTransFeeRec.Status = BCMOH_Constants.feeStatus;
        Database.Update(regTransFeeRec);
        Test.stopTest();
    }
}