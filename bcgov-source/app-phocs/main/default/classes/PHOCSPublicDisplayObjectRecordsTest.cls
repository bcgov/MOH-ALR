@isTest(SeeAllData=false)
private class PHOCSPublicDisplayObjectRecordsTest {
    static Account createTestAccount() {
        Account acc = new Account(
            Name = 'Test Facility',
            RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('DrinkingWaterSystem').getRecordTypeId(),
            Type = 'Drinking Water',
            CategoryL1__c = 'Community Water System',
            CategoryL2__c = 'Local Gov System',
            HealthAuthority__c = 'Vancouver Coastal Health - VCH',
            Phone = '1234567890'     
        );
        acc.Physical_Address__Street__s = '123 Main St';
        acc.Physical_Address__City__s = 'Cityville';
        acc.Physical_Address__StateCode__s = 'BC';
        acc.Physical_Address__PostalCode__s = 'V9A1A1';
        acc.Physical_Address__CountryCode__s = 'CA';
        acc.PHOCSLastInspectionDate__c = Date.newInstance(2024, 12, 31);
        insert acc;
        
        return acc;
    }
/******************************************************************************************
* @description : EHIS-3277 - createBeachFacilityAccount method has setup data to call the test methods 
* @author :      Yuvashree Perumal
* @date :        12/08/2026
*******************************************************************************************/
    static Account createBeachFacilityAccount() {
        Id accountRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId();
        Account acc = new Account(
            Name = 'Test Recreational Beach Facility',
            RecordTypeId = accountRtId,
            Type = 'Recreational Water',
            CategoryL1__c = 'Beach',
            HealthAuthority__c = 'Vancouver Coastal Health - VCH',
            Phone = '1234567890'
        );        
        acc.Physical_Address__Street__s = '123 Beach St';
        acc.Physical_Address__City__s = 'Cityville';
        acc.Physical_Address__StateCode__s = 'BC';
        acc.Physical_Address__PostalCode__s = 'V9A1A1';
        acc.Physical_Address__CountryCode__s = 'CA';        
        insert acc;
        return acc;
    }
    
    static void runTestCallMethod(String action, Map<String, Object> input) {
        PHOCSPublicDisplayObjectRecords handler = new PHOCSPublicDisplayObjectRecords();
        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
                'output' => new Map<String, Object>(),
                'options' => new Map<String, Object>()
                };
                    
                    handler.call(action, args);
        System.assert(args.get('output') != null);
        System.assert(((Map<String, Object>)args.get('output')).containsKey('result'), 'Missing result in output for action: ' + action);
    }
    
    @isTest
    static void testGetRecordsList() {
        Test.startTest();
        Account acc = createTestAccount();
        Map<String, Object> input = new Map<String, Object>{
            'recordId' => acc.Id,
                'configName' => 'FacilitiesList'
                };
                    Test.stopTest();
        
        PHOCSPublicDisplayObjectRecords handler = new PHOCSPublicDisplayObjectRecords();
        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
                'output' => new Map<String, Object>(),
                'options' => new Map<String, Object>()
                };
                    
                    handler.call('getRecordsList', args);
        System.assert(args.get('output') != null);
        System.assert(((Map<String, Object>)args.get('output')).containsKey('result'), 'Missing result in output for action: getRecordsList');
    }
    
    @isTest
    static void testGetRecordDetails() {
        Test.startTest();
        Account acc = createTestAccount();
        
        Contact con = new Contact();
        con.AccountId = acc.Id;
        con.LastName = 'Test';
        con.Email = 'testuser@moh.com';
        Insert con;
        
        Case caseRec = new Case(AccountId=acc.Id, Status = 'Open');
        insert caseRec;
        
        LabTestRequisition__c req = new LabTestRequisition__c();
        req.CollectionDateTime__c = DateTime.now();
        req.FacilityName__c = acc.Id;
        req.SamplerName__c = 'Test';
        insert req;
        
        LabTestMasterList__c master = new LabTestMasterList__c();
        master.Name = 'LabTestMasterList';
        master.ParameterType__c = 'test';
        master.TestCategory__c = 'Drinking Water';
        master.SampleTestType__c = 'Chemical';
        master.UnitOfMeasure__c = 'test';
        master.PhysicalQuantity__c = 'test';
        master.Active__c = true;
        master.RecordTypeId = Schema.SObjectType.LabTestMasterList__c.getRecordTypeInfosByName().get('PHOCS Water Lab Test').getRecordTypeId();
        insert master;
        
        LabTestRequired__c required = new LabTestRequired__c();
        required.Test__c = master.Id;
        required.Status__c = 'Requested';
        required.TestCategory__c = 'Drinking Water';
        required.RecordTypeId = Schema.SObjectType.LabTestRequired__c.getRecordTypeInfosByName().get('PHOCS Water Lab Test Required').getRecordTypeId();
        insert required;
        Test.stopTest();
        
        Map<String, Object> input = new Map<String, Object>{
            'recordId' => acc.Id,
                'configName' => 'FacilityDetail'
                };     
                    runTestCallMethod('getRecordDetails', input);
        
        input = new Map<String, Object>{
            'recordId' => master.Id
                };     
                    runTestCallMethod('getRecordDetails', input);
        
        input = new Map<String, Object>{
            'recordId' => caseRec.Id,
                'configName' => 'FacilityWaterAdvisoryDetail'
                };     
                    runTestCallMethod('getRecordDetails', input);
        
        input = new Map<String, Object>{
            'recordId' => req.Id,
                'configName' => 'FacilityWaterSampleDetail'
                }; 
                    PHOCSPublicDisplayObjectRecords handler = new PHOCSPublicDisplayObjectRecords();
        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
                'output' => new Map<String, Object>(),
                'options' => new Map<String, Object>()
                };
                    
                    handler.call('getRecordDetails', args);
        System.assert(args.get('output') != null);
        System.assert(((Map<String, Object>)args.get('output')).containsKey('result'), 'Missing result in output for action: getRecordDetails');
    }
    
    @isTest
    static void testGetRelatedList() {
        Test.startTest();
        Account acc = createTestAccount();  
        
        LabTestRequisition__c req = new LabTestRequisition__c();
        req.CollectionDateTime__c = DateTime.now();
        req.FacilityName__c = acc.Id;
        req.SamplerName__c = 'Test';
        insert req;
        
        LabTestMasterList__c master = new LabTestMasterList__c();
        master.Name = 'LabTestMasterList';
        master.ParameterType__c = 'test';
        master.TestCategory__c = 'Drinking Water';
        master.SampleTestType__c = 'Chemical';
        master.UnitOfMeasure__c = 'test';
        master.PhysicalQuantity__c = 'test';
        master.Active__c = true;
        master.RecordTypeId = Schema.SObjectType.LabTestMasterList__c.getRecordTypeInfosByName().get('PHOCS Water Lab Test').getRecordTypeId();
        insert master;
        
        LabTestRequired__c required = new LabTestRequired__c();
        required.Test__c = master.Id;
        required.Status__c = 'Requested';
        required.TestCategory__c = 'Drinking Water';
        required.RecordTypeId = Schema.SObjectType.LabTestRequired__c.getRecordTypeInfosByName().get('PHOCS Water Lab Test Required').getRecordTypeId();
        insert required;
        
        Test.stopTest();
        
        Map<String, Object> input = new Map<String, Object>{
            'recordId' => acc.Id,
                'configName' => 'FacilityInspectionList'
                };
                    runTestCallMethod('getRelatedList', input);
        
        input = new Map<String, Object>{
            'recordId' => req.Id,
                'configName' => 'FacilityWaterSampleDetailTestResults'
                };
                    PHOCSPublicDisplayObjectRecords handler = new PHOCSPublicDisplayObjectRecords();
        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
                'output' => new Map<String, Object>(),
                'options' => new Map<String, Object>()
                };
                    
                    handler.call('getRelatedList', args);
        System.assert(args.get('output') != null);
        System.assert(((Map<String, Object>)args.get('output')).containsKey('result'), 'Missing result in output for action: getRelatedList');
    } 
    
    @isTest 
    static void testGetFacilityList() {
        Test.startTest();
        createTestAccount(); // Ensure there's a facility of type Food
        Test.stopTest();
        
        Map<String, Object> input = new Map<String, Object>{
            'programArea' => 'food'
                };
                    runTestCallMethod('getFacilityList', input);
        
        input = new Map<String, Object>{
            'programArea' => 'food'
                };
                    runTestCallMethod('getFacilityList', input);
        
        input = new Map<String, Object>{
            'programArea' => 'drinking-water-system'
                };
                    runTestCallMethod('getFacilityList', input);
        
        input = new Map<String, Object>{
            'programArea' => 'residential-care'
                };
                    runTestCallMethod('getFacilityList', input);
        
        input = new Map<String, Object>{
            'programArea' => 'hospital'
                };
                    runTestCallMethod('getFacilityList', input);
        
        input = new Map<String, Object>{
            'programArea' => 'child-care'
                };
                    runTestCallMethod('getFacilityList', input);
        
        input = new Map<String, Object>{
            'programArea' => 'personal-services'
                };
                    runTestCallMethod('getFacilityList', input);
        
        input = new Map<String, Object>{
            'programArea' => 'tobacco-vapour'
                };
                    runTestCallMethod('getFacilityList', input);
        
        input = new Map<String, Object>{
            'programArea' => 'recreational-water'
                };
                    runTestCallMethod('getFacilityList', input);
        
        input = new Map<String, Object>{
            'programArea' => 'industrial-camps'
                };
                    runTestCallMethod('getFacilityList', input);
        
        input = new Map<String, Object>{
            'programArea' => 'sewerage-facilities'
                };
                    runTestCallMethod('getFacilityList', input);
        
        input = new Map<String, Object>{
            'programArea' => 'childcareowl'
                };
                    runTestCallMethod('getFacilityList', input);
        
        input = new Map<String, Object>{
            'programArea' => 'residentialcareowl'
                };
                    runTestCallMethod('getFacilityList', input);
        
        input = new Map<String, Object>{
            'programArea' => ''
                };
                    PHOCSPublicDisplayObjectRecords handler = new PHOCSPublicDisplayObjectRecords();
        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
                'output' => new Map<String, Object>(),
                'options' => new Map<String, Object>()
                };
                    handler.call('getFacilityList', args);
        System.assert(args.get('output') != null);
        System.assert(((Map<String, Object>)args.get('output')).containsKey('result'), 'Missing result in output for action: getFacilityList');
    }
    
    @isTest
    static void testInvokeMethod_getInspectionDetails() {
        Test.startTest();
        Account acc = createTestAccount();
        Test.stopTest();
        
        Map<String, Object> input = new Map<String, Object>{
            'objectAPIName' => 'Account'
                };
                    
                    PHOCSPublicDisplayObjectRecords handler = new PHOCSPublicDisplayObjectRecords();
        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
                'output' => new Map<String, Object>(),
                'options' => new Map<String, Object>()
                };
                    handler.call('getInspectionDetails', args);
        System.assert(((Map<String, Object>)args.get('output')).containsKey('result'));
    }
    
    @isTest
    static void testInvokeMethod_getRecordById() {
        Test.startTest();
        Account acc = createTestAccount();
        Test.stopTest();
        
        Map<String, Object> input = new Map<String, Object>{
            'recordId' => acc.Id
                };
                    PHOCSPublicDisplayObjectRecords handler = new PHOCSPublicDisplayObjectRecords();
        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
                'output' => new Map<String, Object>(),
                'options' => new Map<String, Object>()
                };
                    
                    handler.call('getRecordById', args);
        System.assert(((Map<String, Object>)args.get('output')).containsKey('result'));
    }
    
    @isTest
    static void testInvokeMethod_getRelatedListById() {
        Test.startTest();
        Account acc = createTestAccount();
        Test.stopTest();
        
        Map<String, Object> input = new Map<String, Object>{
            'recordId' => acc.Id,
                'childSobjectAPIName' => 'Visit'
                };
                    
                    PHOCSPublicDisplayObjectRecords handler = new PHOCSPublicDisplayObjectRecords();
        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
                'output' => new Map<String, Object>(),
                'options' => new Map<String, Object>()
                };
                    
                    handler.call('getRelatedListById', args);
        System.assert(((Map<String, Object>)args.get('output')).containsKey('result'));
    }
/********************************************************************************
* Method Name: testGetRecordDetails_FacilityBanner
* Created Date: 12/08/2026
* Created By: Yuvashree Perumal
* Description: EHIS-3277 - Method to cover getBeachAdvisoryDetails method for Facility Banner
**********************************************************************************/
    @isTest
    static void testGetRecordDetails_FacilityBanner() {
        Account acc = createBeachFacilityAccount();      
        Id caseRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PHOCSWaterAdvisories').getRecordTypeId();      
        Case c1 = new Case(
            AccountId = acc.Id,
            RecordTypeId = caseRtId,
            Status = 'Open',
            Origin = 'Web',
            Type = 'Recreational Water',
            TypeOfAdvisory__c = 'Beach Closure',
            ReasonForAdvisory__c = 'Chemical & physical parameters in excess'
        );       
        Case c2 = new Case(
            AccountId = acc.Id,
            RecordTypeId = caseRtId,
            Status = 'Open',
            Origin = 'Web',
            Type = 'Recreational Water',
            TypeOfAdvisory__c = 'Not Suitable for Swimming',
            ReasonForAdvisory__c = 'Excessive turbidity'
        );       
        Case c3 = new Case(
            AccountId = acc.Id,
            RecordTypeId = caseRtId,
            Status = 'Open',
            Origin = 'Web',
            Type = 'Recreational Water',
            TypeOfAdvisory__c = 'Beach Closure'
        );        
        insert new List<Case>{ c1, c2, c3 };            
            Test.startTest();        
        Map<String, Object> input = new Map<String, Object>{
            'recordId' => acc.Id,
            'configName' => 'FacilityDetail'
                };
                    PHOCSPublicDisplayObjectRecords handler = new PHOCSPublicDisplayObjectRecords();
        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => new Map<String, Object>(),
            'options' => new Map<String, Object>()
                };
                    handler.call('getRecordDetails', args);
        Test.stopTest();       
        Map<String, Object> output = (Map<String, Object>) args.get('output');
        List<Object> results = (List<Object>) output.get('result');     
        System.assert(!results.isEmpty(), 'Expected one result from getRecordDetails');        
        Map<String, Object> record = (Map<String, Object>) results[0];        
        System.assertEquals(true,record.get('HasBeachAdvisories'),'Expected beach advisories to be true');     
        String bannerHtml = (String) record.get('BeachAdvisoryBannerHtml');     
        System.assert(String.isNotBlank(bannerHtml),'Expected BeachAdvisoryBannerHtml to be populated');     
        System.assert(bannerHtml.contains('This beach is currently closed as of'),'Expected Beach Closure banner text');    
        System.assert(bannerHtml.contains('This beach is currently under a beach advisory as of'),'Expected Not Suitable for Swimming banner text');
        Integer bannerCount = bannerHtml.split('This beach is currently').size() - 1;       
        System.assertEquals(3, bannerCount,'Expected 3 banners, one per eligible open Advisory Case');        
        Integer reasonLineCount = bannerHtml.split('Reason:').size() - 1;        
        System.assertEquals(2,reasonLineCount,'Expected Reason line only for cases where ReasonForAdvisory__c is populated');
    }
    @isTest
    static void testGetInspectionResults_EmptyResult() {
        Account acc = createTestAccount();      
        Test.startTest();     
        Map<String, Object> input = new Map<String, Object>{
            'recordId' => acc.Id
                };                    
                    PHOCSPublicDisplayObjectRecords handler = new PHOCSPublicDisplayObjectRecords();    
        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => new Map<String, Object>(),
            'options' => new Map<String, Object>()
                };                  
                    handler.call('getInspectionResults', args);       
        Test.stopTest();      
        Map<String, Object> output = (Map<String, Object>) args.get('output');     
        System.assert(output.containsKey('result'), 'Expected result key');      
        List<Object> results = (List<Object>) output.get('result');       
        System.assertEquals(0,results.size(),'Expected empty inspection result');
    }
}