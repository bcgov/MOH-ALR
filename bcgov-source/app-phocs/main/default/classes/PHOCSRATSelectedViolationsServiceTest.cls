/**********************************************************************************************
* @Author:      Accenture
* @Date:        04 Sep 2026
* @Description: Test class for PHOCSRATSelectedViolationsService.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
***********************************************************************************************/
@IsTest
private class PHOCSRATSelectedViolationsServiceTest {
    
    /**
* @author: Deepak
* @date: 04 Sep 2026
* @description: Tests successful serialization of selectedViolations and validates the returned JSON output.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testSaveSelectedViolations() {
        PHOCSRATSelectedViolationsService service = new PHOCSRATSelectedViolationsService();
        
        List<Object> selectedViolations = new List<Object>{
            new Map<String, Object>{
                'violationId' => '0fvAq000007jU9CIAU',
                'category' => 'Care and Supervision',
                'regulatoryCode' => '5(2)(a)',
                'inspectionQuestion' => 'Test inspection question',
                'scope' => 'Isolated',
                'severity' => 'Potential for more than minimal harm',
                'comments' => null
            },
            new Map<String, Object>{
                'violationId' => '0fvAq000007jU9DIAU',
                'category' => 'Care and Supervision',
                'regulatoryCode' => '13(1)',
                'inspectionQuestion' => 'Test inspection question 2',
                'scope' => 'Pattern',
                'severity' => 'Potential for significant harm',
                'comments' => 'Test comments'
            }
        };
        
        Map<String, Object> input = new Map<String, Object>{
            'selectedViolations' => selectedViolations
        };
        
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => output,
            'options' => options
        };
        
        Test.startTest();
        Object result = service.call('saveSelectedViolations', args);
        Test.stopTest();
        
        Map<String, Object> resultMap = (Map<String, Object>) result;
        String selectedViolationsJson = (String) resultMap.get('selectedViolationsJson');
        List<Object> serializedViolations = (List<Object>) JSON.deserializeUntyped(selectedViolationsJson);
        
        Assert.areEqual(2, serializedViolations.size(), 'Two selected violations should be serialized.');
        
        Map<String, Object> firstViolation = (Map<String, Object>) serializedViolations[0];
        Assert.areEqual('0fvAq000007jU9CIAU', firstViolation.get('violationId'), 'Violation Id should match.');
        Assert.areEqual('Care and Supervision', firstViolation.get('category'), 'Category should match.');
        Assert.areEqual('5(2)(a)', firstViolation.get('regulatoryCode'), 'Regulatory code should match.');
        Assert.areEqual('Test inspection question', firstViolation.get('inspectionQuestion'), 'Inspection question should match.');
        Assert.areEqual('Isolated', firstViolation.get('scope'), 'Scope should match.');
        Assert.areEqual('Potential for more than minimal harm', firstViolation.get('severity'), 'Severity should match.');
        Assert.areEqual(null, firstViolation.get('comments'), 'Comments should be null.');
        
        Map<String, Object> secondViolation = (Map<String, Object>) serializedViolations[1];
        Assert.areEqual('0fvAq000007jU9DIAU', secondViolation.get('violationId'), 'Violation Id should match.');
        Assert.areEqual('Pattern', secondViolation.get('scope'), 'Scope should match.');
        Assert.areEqual('Potential for significant harm', secondViolation.get('severity'), 'Severity should match.');
        Assert.areEqual('Test comments', secondViolation.get('comments'), 'Comments should match.');
    }
    
    /**
* @author: Deepak
* @date: 04 Sep 2026
* @description: Tests successful serialization when Callable arguments are provided as a flat input map.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testSaveSelectedViolationsFlatInput() {
        PHOCSRATSelectedViolationsService service = new PHOCSRATSelectedViolationsService();
        
        List<Object> selectedViolations = new List<Object>{
            new Map<String, Object>{
                'violationId' => '0fvAq000007jU9CIAU',
                'scope' => 'Isolated',
                'severity' => 'Potential for more than minimal harm'
            }
        };
        
        Map<String, Object> args = new Map<String, Object>{
            'selectedViolations' => selectedViolations
        };
        
        Test.startTest();
        Object result = service.call('saveSelectedViolations', args);
        Test.stopTest();
        
        Map<String, Object> resultMap = (Map<String, Object>) result;
        String selectedViolationsJson = (String) resultMap.get('selectedViolationsJson');
        List<Object> serializedViolations = (List<Object>) JSON.deserializeUntyped(selectedViolationsJson);
        
        Assert.areEqual(1, serializedViolations.size(), 'One selected violation should be serialized.');
        
        Map<String, Object> violation = (Map<String, Object>) serializedViolations[0];
        Assert.areEqual('0fvAq000007jU9CIAU', violation.get('violationId'), 'Violation Id should match.');
        Assert.areEqual('Isolated', violation.get('scope'), 'Scope should match.');
        Assert.areEqual('Potential for more than minimal harm', violation.get('severity'), 'Severity should match.');
    }
    
    /**
* @author: Deepak
* @date: 04 Sep 2026
* @description: Tests serialization when selectedViolations is null.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testSaveSelectedViolationsNull() {
        PHOCSRATSelectedViolationsService service = new PHOCSRATSelectedViolationsService();
        
        Map<String, Object> input = new Map<String, Object>{
            'selectedViolations' => null
        };
        
        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        };
        
        Test.startTest();
        Object result = service.call('saveSelectedViolations', args);
        Test.stopTest();
        
        Map<String, Object> resultMap = (Map<String, Object>) result;
        String selectedViolationsJson = (String) resultMap.get('selectedViolationsJson');
        
        Assert.areEqual('[]', selectedViolationsJson, 'Null selectedViolations should return an empty JSON array.');
    }
    
    /**
* @author: Deepak
* @date: 04 Sep 2026
* @description: Tests serialization when selectedViolations contains a non-list value.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testSaveSelectedViolationsInvalidType() {
        PHOCSRATSelectedViolationsService service = new PHOCSRATSelectedViolationsService();
        
        Map<String, Object> input = new Map<String, Object>{
            'selectedViolations' => 'Invalid Value'
        };
        
        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        };
        
        Test.startTest();
        Object result = service.call('saveSelectedViolations', args);
        Test.stopTest();
        
        Map<String, Object> resultMap = (Map<String, Object>) result;
        String selectedViolationsJson = (String) resultMap.get('selectedViolationsJson');
        
        Assert.areEqual('[]', selectedViolationsJson, 'A non-list selectedViolations value should return an empty JSON array.');
    }
    
    /**
* @author: Deepak
* @date: 04 Sep 2026
* @description: Tests validation when the Callable action is blank.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testBlankAction() {
        PHOCSRATSelectedViolationsService service = new PHOCSRATSelectedViolationsService();
        String exceptionMessage;
        
        Test.startTest();
        try {
            service.call(null, new Map<String, Object>());
        } catch (AuraHandledException ex) {
            exceptionMessage = ex.getMessage();
        }
        Test.stopTest();
        
        Assert.areEqual('Callable action is required.', exceptionMessage, 'Expected blank action validation message.');
    }
    
    /**
* @author: Deepak
* @date: 04 Sep 2026
* @description: Tests validation when Callable arguments are null.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testNullArguments() {
        PHOCSRATSelectedViolationsService service = new PHOCSRATSelectedViolationsService();
        String exceptionMessage;
        
        Test.startTest();
        try {
            service.call('saveSelectedViolations', null);
        } catch (AuraHandledException ex) {
            exceptionMessage = ex.getMessage();
        }
        Test.stopTest();
        
        Assert.areEqual('Callable arguments are required.', exceptionMessage, 'Expected null arguments validation message.');
    }
    
    /**
* @author: Deepak
* @date: 04 Sep 2026
* @description: Tests validation when an unsupported Callable action is provided.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testUnsupportedAction() {
        PHOCSRATSelectedViolationsService service = new PHOCSRATSelectedViolationsService();
        String exceptionMessage;
        
        Test.startTest();
        try {
            service.call('invalidAction', new Map<String, Object>());
        } catch (AuraHandledException ex) {
            exceptionMessage = ex.getMessage();
        }
        Test.stopTest();
        
        Assert.areEqual('Unsupported callable action: invalidAction', exceptionMessage, 'Expected unsupported action validation message.');
    }
    
    /**
* @author: Deepak
* @date: 04 Sep 2026
* @description: Tests validation when the input map passed directly to saveSelectedViolations is null.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testNullInput() {
        PHOCSRATSelectedViolationsService service = new PHOCSRATSelectedViolationsService();
        String exceptionMessage;
        
        Test.startTest();
        try {
            service.saveSelectedViolations(null, new Map<String, Object>(), new Map<String, Object>());
        } catch (AuraHandledException ex) {
            exceptionMessage = ex.getMessage();
        }
        Test.stopTest();
        
        Assert.areEqual('Input is required.', exceptionMessage, 'Expected null input validation message.');
    }
}