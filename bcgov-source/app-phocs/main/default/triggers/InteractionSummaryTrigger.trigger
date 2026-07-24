/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Trigger is to have the methods related to BusinessLicenseApplication trigger
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
                           ALR-553             Keerthana          Renewal Unit Fee  and Late Fee Status in RegulatoryTrxnFee changes according to the application Status and Late fee Status in BLA
						   PHOCS-3081		   Rahul			  PHOCS BLA Health authority population from account ( for record sharing )
***********************************************************************************************/
trigger InteractionSummaryTrigger on InteractionSummary (before insert) {
	 if(Trigger.isBefore && (Trigger.isInsert)){
           PhocsHealthAuthorityHandler.populateHealthAuthority(Trigger.new, 'AccountId');         
        }
}