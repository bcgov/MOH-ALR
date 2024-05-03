/**********************************************************************************************
* @Author:Accenture_ALR Team   
* @Date:      
* @Description: The purpose of this Trigger is to trigger on particular events for Account
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]  
                           ALR-928               Komal        Compliance inspection scheduling based on compliance score
***********************************************************************************************/
trigger AccountTrigger on Account (after update) {
        if(Trigger.isAfter && Trigger.isUpdate){
            AccountHelper.createInspection(Trigger.New);
        }
    }
