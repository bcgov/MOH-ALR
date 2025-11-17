@isTest
public class PHOCSFoodPremiseLicenseControllerTest {

    @testSetup
    static void setupData() {
        // Create Operating Hours records
        List<OperatingHours> hoursList = new List<OperatingHours>();
        for (Integer i = 0; i < 2; i++) {
            hoursList.add(new OperatingHours(Name = 'Hours ' + i));
        }
        insert hoursList;
		
		RegulatoryAuthorizationType  foodLicenceType = new RegulatoryAuthorizationType(
			Name='Food Premise Operating Permit');
        insert foodLicenceType;
		
	    //Create Facility Account
        Account acc = new Account(
			Name = 'Test Food Premise',
			RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId(),
			Type = 'Food',
            CategoryL1__c = 'Food store',
            CategoryL2__c = 'Food retailer',
            CategoryL3__c = 'Corner store',
            Phone = '1234567890',
			LicenseType__c = foodLicenceType.Id); //'0ehbZ0000002UOeQAM'
        insert acc;
    }

    @isTest
    static void testGetOperatingHoursNames() {
        //Prepare args
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>();

        // Call the controller
        PHOCSFoodPremiseLicenseController controller = new PHOCSFoodPremiseLicenseController();
        Object result = controller.call('OperatingHoursNames', new Map<String, Object>{
            'input' => inputMap,
            'output' => outputMap,
            'options' => optionsMap
        });

             
        List<Object> options = (List<Object>)outputMap.get('options');
        System.assertEquals(2, options.size(), 'Should return 2 Operating Hours options');
    }

    @isTest
    static void testUpdateAccountOperatingHours_Success() {
        // Get test data
        Account acc = [SELECT Id FROM Account LIMIT 1];
        OperatingHours oh = [SELECT Id FROM OperatingHours LIMIT 1];

        // Prepare input and output maps
        Map<String, Object> inputMap = new Map<String, Object>{
            'accountIdParam' => acc.Id,
            'operatingHourParam' => oh.Id
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>();

        // Call the controller
        PHOCSFoodPremiseLicenseController controller = new PHOCSFoodPremiseLicenseController();
        Object result = controller.call('UpdateAccountOperatingHours', new Map<String, Object>{
            'input' => inputMap,
            'output' => outputMap,
            'options' => optionsMap
        });

        // Assertions
        System.assertEquals(true, result, 'Expected success from UpdateAccountOperatingHours');
        System.assertEquals('success', outputMap.get('status'), 'Status should be success');
        System.assertEquals(acc.Id, outputMap.get('accountId'), 'AccountId should match');
        System.assertEquals(oh.Id, outputMap.get('operatingHoursId'), 'OperatingHoursId should match');

        // Verify DB update
        Account updatedAcc = [SELECT OperatingHoursId FROM Account WHERE Id = :acc.Id];
        System.assertEquals(oh.Id, updatedAcc.OperatingHoursId, 'Account should be updated with OperatingHoursId');
    }

    @isTest
    static void testUpdateAccountOperatingHours_MissingParams() {
        // Prepare input with missing params
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>();

        // Call the controller
        PHOCSFoodPremiseLicenseController controller = new PHOCSFoodPremiseLicenseController();
        Object result = controller.call('UpdateAccountOperatingHours', new Map<String, Object>{
            'input' => inputMap,
            'output' => outputMap,
            'options' => optionsMap
        });

        // Assertions
        System.assertEquals(false, result, 'Expected failure due to missing params');
        System.assertEquals('error', outputMap.get('status'), 'Status should be error');
        System.assert(outputMap.get('message') != null, 'Error message should be populated');
    }

    @isTest
    static void testInvalidMethodName() {
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>();

        PHOCSFoodPremiseLicenseController controller = new PHOCSFoodPremiseLicenseController();
        Object result = controller.call('InvalidMethod', new Map<String, Object>{
            'input' => inputMap,
            'output' => outputMap,
            'options' => optionsMap
        });

        System.assertEquals(false, result, 'Expected false for invalid method');
        System.assertEquals('error', outputMap.get('status'), 'Status should be error');
        System.assert(outputMap.get('message').toString().contains('Invalid method name'), 'Message should indicate invalid method');
    }
    
    @isTest
    static void testGetOperatingHourByID() {
        // Fetch test data
        OperatingHours oh = [SELECT Id FROM OperatingHours LIMIT 1];

        // Prepare input and output maps
        Map<String, Object> inputMap = new Map<String, Object>{
            'operatingHourParam' => oh.Id
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>();

        // Call method
        Test.startTest();       
        PHOCSFoodPremiseLicenseController controller = new PHOCSFoodPremiseLicenseController();
        Object result = controller.call('OperatingHourByID', new Map<String, Object>{
            'input' => inputMap,
            'output' => outMap,
            'options' => optionsMap
        });
        Test.stopTest();

        // Assertions
        System.assertEquals(true, result, 'Method should return true');
        System.assertEquals(oh.Id, outMap.get('operatingHoursId'), 'OperatingHoursId should match');
        System.assertNotEquals(null, outMap.get('operatingHoursName'), 'OperatingHoursName should not be null');
    }
    
    @isTest
    static void testGetOperatingHourByAccountID() {
        // Fetch test data
        Account acc = [SELECT Id, OperatingHoursId FROM Account LIMIT 1];

        // Prepare input and output maps
        Map<String, Object> inputMap = new Map<String, Object>{
            'accountIdParam' => acc.Id
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>();

        // Call method
        Test.startTest();       
        PHOCSFoodPremiseLicenseController controller = new PHOCSFoodPremiseLicenseController();
        Object result = controller.call('OperatingHourByAccountID', new Map<String, Object>{
            'input' => inputMap,
            'output' => outMap,
            'options' => optionsMap
        });
        
        Test.stopTest();

        // Assertions
        System.assertEquals(true, result, 'Method should return true');
        System.assertEquals(acc.OperatingHoursId, outMap.get('operatingHoursId'), 'OperatingHoursId should match');        
    }
}