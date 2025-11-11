global without sharing class PHOCSFoodPremiseLicenseController implements Callable {

    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> input   = (Map<String, Object>)args.get('input');
        Map<String, Object> output  = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');
        return invokeMethod(action, input, output, options);
    }

    public Object invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        if (methodName == 'OperatingHoursNames') {
            return getOperatingHoursNames(outMap);
        } else if (methodName == 'UpdateAccountOperatingHours') {
            return updateAccountOperatingHours(inputMap, outMap);
        } else {
            outMap.put('status', 'error');
            outMap.put('message', 'Invalid method name: ' + methodName);
            return false;
        }
    }

    private Boolean getOperatingHoursNames(Map<String, Object> outMap) {
        try {
            List<Map<String, String>> UIoptions = new List<Map<String, String>>();
            for (OperatingHours oh : [SELECT Id, Name FROM OperatingHours WHERE IsDeleted = FALSE ORDER BY Name ASC]) {
                Map<String, String> tempMap = new Map<String, String>();
                tempMap.put('name', oh.Id);
                tempMap.put('value', oh.Name);
                UIoptions.add(tempMap);
            }
            outMap.put('options', UIoptions);
            outMap.put('status', 'success');
            return true;

        } catch (Exception e) {
            outMap.put('status', 'error');
            outMap.put('message', e.getMessage());
            return false;
        }
    }

    private Boolean updateAccountOperatingHours(Map<String, Object> inputMap, Map<String, Object> outMap) {
        try {     
            
            Id accountId = (Id)inputMap.get('accountIdParam');
            Id operatingHoursId = (Id)inputMap.get('operatingHourParam');
            
            if (accountId == null || operatingHoursId == null) {
                outMap.put('status', 'error');
                outMap.put('message', 'Missing accountId or operatingHoursId');
                return false;
            }

            Account acc = [SELECT Id, OperatingHoursId FROM Account WHERE Id = :accountId LIMIT 1];
            acc.OperatingHoursId = operatingHoursId;
            update acc;
            
            outMap.put('status', 'success');
            outMap.put('message', 'Account updated successfully');
            outMap.put('accountId', acc.Id);
            outMap.put('operatingHoursId', acc.OperatingHoursId);
            return true;

        } catch (Exception e) {            
            outMap.put('status', 'error');
            outMap.put('message', e.getMessage());
            return false;
        }
    }
}