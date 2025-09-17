global with sharing class PHOCSWaterRightsService implements Callable {
    global Object call(String action, Map<String, Object> args) {
        Map<String, Object> input   = (Map<String, Object>) args.get('input');
        Map<String, Object> output  = (Map<String, Object>) args.get('output');
        Map<String, Object> options = (Map<String, Object>) args.get('options');
        return invokeMethod(action, input, output, options);
    }

    private Object invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        if (methodName == 'getWellLicenseDetails') {
            // Get Account → fetch License → call external service
            Account acc = getAccountDetails(String.valueOf(inputMap.get('recordId')));
            if (acc != null && String.isNotBlank(acc.WaterLicenseNumber__c)) {
                PHOCSWLSWaterRightsWrapper response = getDynamicQueryResults(acc.WaterLicenseNumber__c);
                
                // Put the wrapper directly into the output map
                outMap.put('result', response);
            } else {
                outMap.put('result', null);
            }
        }
        return outMap; // always return the whole map
    }

    private PHOCSWLSWaterRightsWrapper getDynamicQueryResults(String licenceNumber) {
        return PHOCSWLSWaterService.getWaterRightsByLicence(licenceNumber);
    }

    private Account getAccountDetails(String recordId) {
        return [
            SELECT Id, WaterLicenseNumber__c, WaterLicenseApplicationNumber__c, 
                   WellTagNumber__c, AquiferNumber__c 
            FROM Account 
            WHERE Id = :recordId 
            LIMIT 1
        ];
    }
}