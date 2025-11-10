@isTest
public class PHOCSWaterRightsSystemServiceTest {
    @testSetup
    static void setupTestData() {
        // Create test Account record
        // 
        Account accParent = new Account(
            Name = 'Test Facility Parent',
            RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('DrinkingWaterSystem').getRecordTypeId()
        );
        insert accParent;
        Account acc = new Account(
            Name = 'Test Facility',
            WaterLicenseNumber__c = '502581',
            ParentId = accParent.Id,
            ParentAccount__c = accParent.Id,
            RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('DrinkingWaterSourceIntake').getRecordTypeId(),
            WaterLicenseApplicationNumber__c = 'WLA20160113-0001'
        );
        insert acc;
    }
    
    static Account getAccount(){
        return [Select Id, Name, WaterLicenseNumber__c, WaterLicenseApplicationNumber__c from Account where Name = 'Test Facility' limit 1];
    }
    
    @isTest
    static void testWaterRightServiceWithValidValues(){
        Test.setMock(HttpCalloutMock.class, new PHOCSWaterRightsCommonMock());
        
        Map<String, Object> resultMap;
        
        // Prepare input for FlexCard-style call
        Map<String, Object> input   = new Map<String, Object>{ 'recordId' => getAccount().Id };
        Map<String, Object> output  = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();        
        
        Test.startTest();
        // Call service
        Object result = new PHOCSWaterRightsSystemService().call(
            'getAllData',
            new Map<String, Object>{
                'input'   => input,
                    'output'  => output,
                    'options' => options
                    }
        );
        Test.stopTest();
        System.Assert.isNotNull(result, 'Contains Key with Values');
    }
    
    @isTest
    static void testWaterRightServiceWithBlankValues(){
        Test.setMock(HttpCalloutMock.class, new PHOCSWaterRightsCommonMock());
        Map<String, Object> resultMap;
        
        Test.startTest();
        
        Account acc = getAccount();
        acc.WaterLicenseNumber__c = null;
        acc.WaterLicenseApplicationNumber__c = null;
        update acc;
        
        // Prepare input for FlexCard-style call
        Map<String, Object> input   = new Map<String, Object>{ 'recordId' => getAccount().Id };
        Map<String, Object> output  = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();        
        
        // Call service
        Object result = new PHOCSWaterRightsSystemService().call(
            'getAllData',
            new Map<String, Object>{
                'input'   => input,
                    'output'  => output,
                    'options' => options
                    }
        );
        Test.stopTest();
        System.Assert.isNotNull(result, 'Contains Error Key');
    }        
}