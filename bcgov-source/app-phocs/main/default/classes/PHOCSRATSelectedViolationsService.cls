/**********************************************************************************************
* @Author:      Accenture
* @Date:        03 Sep 2026
* @Description: Remote action for serializing the selectedViolations OmniScript array into a JSON string.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
***********************************************************************************************/
global with sharing class PHOCSRATSelectedViolationsService implements Callable {    
    private static final String ACTION_SAVE_SELECTED_VIOLATIONS = 'saveSelectedViolations';
    
    /**
* @author: Deepak
* @date: 03 Sep 2026
* @description: Call method for remote context. Validates the action and arguments, then dispatches to saveSelectedViolations().
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    global Object call(String action, Map<String, Object> args) {
        if (String.isBlank(action)) {
            throw buildException('Callable action is required.');
        }        
        if (args == null) {
            throw buildException('Callable arguments are required.');
        }        
        if (ACTION_SAVE_SELECTED_VIOLATIONS.equalsIgnoreCase(action)) {
            return saveSelectedViolations(args);
        }
        
        throw buildException('Unsupported callable action: ' + action);
    }
    
    /**
* @author: Deepak
* @date: 03 Sep 2026
* @description: Unwraps the Callable args map into input/output/options, serializes the selectedViolations array into valid JSON, and populates the output map.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public Object saveSelectedViolations(Map<String, Object> args) {
        Map<String, Object> input = args.containsKey('input') && args.get('input') instanceof Map<String, Object> ? (Map<String, Object>) args.get('input') : args;
        Map<String, Object> output = args.containsKey('output') && args.get('output') instanceof Map<String, Object> ? (Map<String, Object>) args.get('output') : new Map<String, Object>();
        Map<String, Object> options = args.containsKey('options') && args.get('options') instanceof Map<String, Object> ? (Map<String, Object>) args.get('options') : new Map<String, Object>();
        
        saveSelectedViolations(input, output, options);        
        return output;
    }
    
    /**
* @author: Deepak
* @date: 03 Sep 2026
* @description: Serializes the selectedViolations OmniScript array into a JSON string and returns it in the output map.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public void saveSelectedViolations(Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) {
        if (input == null) {
            throw buildException('Input is required.');
        }        
        List<Object> selectedViolations = getListValue(input.get('selectedViolations'));
        String selectedViolationsJson = JSON.serialize(selectedViolations);
        
        output.put('selectedViolationsJson', selectedViolationsJson);
    }
    
    /**
* @author: Deepak
* @date: 03 Sep 2026
* @description: Safely casts an Object to a List<Object>, returning an empty list for null or any non-list value.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private List<Object> getListValue(Object value) {
        if (value == null) {
            return new List<Object>();
        }
        if (value instanceof List<Object>) {
            return (List<Object>) value;
        }
        
        return new List<Object>();
    }
    
    /**
* @author: Deepak
* @date: 03 Sep 2026
* @description: Creates an AuraHandledException and explicitly sets its message.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static AuraHandledException buildException(String message) {
        AuraHandledException auraException = new AuraHandledException(message);
        auraException.setMessage(message);
        return auraException;
    }
}