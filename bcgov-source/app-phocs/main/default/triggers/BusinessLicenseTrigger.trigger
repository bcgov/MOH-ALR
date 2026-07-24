/**********************************************************************************************
* @Author:Accenture PHOCS Dev Team   
* @Date:       
* @Description: The purpose of this Trigger is to have the methods related to Conditions trigger
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
						   PHOCS-3081		   Rahul			  Business License object field Health authority population from account ( for record sharing )
***********************************************************************************************/




trigger BusinessLicenseTrigger on BusinessLicense (before insert) {
	 if(Trigger.isBefore && (Trigger.isInsert )){
           PhocsHealthAuthorityHandler.populateHealthAuthority(Trigger.new, 'Account__c');         
        }
}