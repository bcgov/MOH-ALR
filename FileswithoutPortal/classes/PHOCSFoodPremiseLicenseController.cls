/*************************************************************************************************
* @Author:Accenture_PHOCS Dev Team   
* @Date:       
* @Description: Standard Operating Hours object and records are not available for the external users
				through Omni Studio tools (Integration procedures, Datamapers etc). This class is 
				provides the utility methods for Food Premise Licese Creation Features
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]    
                  		  EHIS-2540				Shinoj		 Initial version
**************************************************************************************************/

global with sharing class PHOCSFoodPremiseLicenseController implements Callable {
    
    private static final String FETCH_ALL_OPERATING_HOURS_METHOD = 'OperatingHoursNames';
    private static final String UPDATE_OPERATING_HOURS_METHOD = 'UpdateAccountOperatingHours'; 
    private static final String FETCH_OPERATING_HOUR_BY_ACCOUNT_ID_METHOD = 'OperatingHourByAccountID';
    private static final String FETCH_OPERATING_HOUR_BY_ID_METHOD = 'OperatingHourByID';
    
	public Object call(String action, Map<String, Object> args) {        
        Map<String, Object> input   = (Map<String, Object>)args.get('input');
        Map<String, Object> output  = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');
        return invokeMethod(action, input, output, options);
    }

    public Object invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        
        if (FETCH_ALL_OPERATING_HOURS_METHOD.equals(methodName)) {
            return getOperatingHoursNames(outMap);
        } else if (UPDATE_OPERATING_HOURS_METHOD.equals(methodName)){
            return updateAccountOperatingHours(inputMap, outMap);
        }else if(FETCH_OPERATING_HOUR_BY_ACCOUNT_ID_METHOD.equals(methodName)){           
            return getOperatingHourByAccountID(inputMap, outMap);
        }else if(FETCH_OPERATING_HOUR_BY_ID_METHOD.equals(methodName)){           
            return getOperatingHourByID(inputMap, outMap);
        } else {
            outMap.put('status', 'error');
            outMap.put('message', 'Invalid method name: ' + methodName);
            return false;
        }
    }
/*********************************************************************************************************************
 * @Description - This method returns all the operating hours. This data will be available on the Operating hours 
 * 				  Lookup feld on the Food Premise Permit request screen
 * @Param - No Input params
 * @Return - A map contains Name-ID Key-value pairs of Operating Hours
 * *******************************************************************************************************************/
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
/*********************************************************************************************************************
 * @Description - This method is used to update the Operating Hour on the Account. 
 * @Param - Input JSON from OmniScript. accountIdParam and operatingHourParam params are used to perform the DML
 * @Return - boolean representing the status of operation
 * *******************************************************************************************************************/
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
    
 /*********************************************************************************************************************
 * @Description - This method is used to feth the Operating Hour for a given Operating Hour ID. 
 * 				  This will be used to display the operating hour name on the review screen
 * @Param	- Input JSON from OmniScript. operatingHourParam param is used to perform the DML
 * @Return  - boolean representing the status of operation
 * *******************************************************************************************************************/
   private static Boolean getOperatingHourByID( Map<String, Object> inputMap, Map<String, Object> outMap) {
        try {            
            Id operatingHoursId = (Id)inputMap.get('operatingHourParam');           
            if (operatingHoursId != null) {
                OperatingHours oh = [SELECT Id, Name FROM OperatingHours WHERE Id = :operatingHoursId LIMIT 1];
                outMap.put('operatingHoursId', oh.Id);
                outMap.put('operatingHoursName', oh.Name);
            } else {
                outMap.put('error', 'Operating Hours Id is null');
            }
        } catch (Exception e) {
            outMap.put('error', e.getMessage());
        }        
        return true;
    }
/*********************************************************************************************************************
 * @Description - This method is used to feth the Operating Hour for a given Account ID.
 * 				  This will be used to display the operating hour name  defaulted for existing facility
 * @Param  - Input JSON from OmniScript. accountIdParam param is used to perform the DML
 * @Return - boolean representing the status of operation
 * *******************************************************************************************************************/    
 	private static Boolean getOperatingHourByAccountID( Map<String, Object> inputMap, Map<String, Object> outMap) {
        try {            
            Id accountId = (Id)inputMap.get('accountIdParam');            
            if (accountId != null) {
                Account oh = [SELECT Id, OperatingHoursId, OperatingHours.Name FROM Account WHERE Id = :accountId];
                outMap.put('operatingHoursId', oh.OperatingHoursId);
                outMap.put('operatingHoursName', oh.OperatingHours.Name);
            } else {
                outMap.put('error', 'Operating Hours Id is null');
            }
        } catch (Exception e) {
            outMap.put('error', e.getMessage());
        }       
        return true;
    }
}