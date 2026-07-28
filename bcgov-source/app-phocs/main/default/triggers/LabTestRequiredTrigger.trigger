/**********************************************************************************************
* @Author:      Accenture 
* @Date:        30 Oct 2025
* @Description: The purpose of this Trigger is to trigger on particular events
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                30 Oct -  PHOCS-402         -  Accenture   -  Update Owner to Queue for PHOCS Web PC records.
                21 july -  EHIS- 3081       - Accenture - health authority update
***********************************************************************************************/
trigger LabTestRequiredTrigger on LabTestRequired__c (before insert, before update) {

if(Trigger.isBefore && (Trigger.isInsert || Trigger.IsUpdate)){
        PhocsHealthAuthorityHandler.populateHealthAuthority(Trigger.new);         
    }
    

}