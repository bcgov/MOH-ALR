/**********************************************************************************************
* @Author:Accenture_ALR Team   
* @Date:      
* @Description: The purpose of this Trigger is to trigger on particular events for Account
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]  
                           ALR-928               Komal
***********************************************************************************************/
trigger AccountTrigger on Account (after update) {
    List<Account> accList = new List<Account>();
    if(Trigger.isAfter && Trigger.isUpdate){
        for(Account acc : Trigger.New){
            if(acc.Rating != NULL){
                accList.add(acc);
            }
        }
    }
    if(!accList.isEmpty()){
        AccountHelper.createInspection(accList);
    }
}