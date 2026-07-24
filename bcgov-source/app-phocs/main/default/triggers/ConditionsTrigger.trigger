/**********************************************************************************************
* @Author:Accenture PHOCS Dev Team   
* @Date:       
* @Description: The purpose of this Trigger is to have the methods related to Conditions trigger
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
						   PHOCS-3081		   Rahul			  Conditions object field Health authority population from account ( for record sharing )
***********************************************************************************************/




trigger ConditionsTrigger on Conditions__c (before insert) {
	 if(Trigger.isBefore && (Trigger.isInsert)){
           PhocsHealthAuthorityHandler.populateHealthAuthority(Trigger.new, 'Account_Name__c');         
        }
}