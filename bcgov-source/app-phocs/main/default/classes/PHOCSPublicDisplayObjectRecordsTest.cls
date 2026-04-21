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
}