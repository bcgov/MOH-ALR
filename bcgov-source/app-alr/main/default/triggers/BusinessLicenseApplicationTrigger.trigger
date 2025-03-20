/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Trigger is to have the methods related to BusinessLicenseApplication trigger
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
                           ALR-553             Keerthana          Renewal Unit Fee  and Late Fee Status in RegulatoryTrxnFee changes according to the application Status and Late fee Status in BLA
***********************************************************************************************/




trigger BusinessLicenseApplicationTrigger on BusinessLicenseApplication (after update) {
    if(Trigger.isAfter && Trigger.isUpdate){
            BusinessLicenseApplicationHelper.updateFeeStatus(Trigger.New);            
        }
}