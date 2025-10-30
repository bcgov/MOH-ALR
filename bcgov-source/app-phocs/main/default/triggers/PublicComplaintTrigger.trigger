/**********************************************************************************************
* @Author:      Accenture 
* @Date:        30 Oct 2025
* @Description: The purpose of this Trigger is to trigger on particular events
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                30 Oct -  PHOCS-402         -  Accenture   -  Update Owner to Queue for PHOCS Web PC records.
***********************************************************************************************/
trigger PublicComplaintTrigger on PublicComplaint (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        PublicComplaintTriggerHandler.updatePHOCSPCOwner(Trigger.new);
    }
}