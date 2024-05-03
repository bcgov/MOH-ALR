/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Class is to Create Regulatory Transaction Fee and Regulatory Transaction Fee Item records related to BLA
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]  
                              ALR-660           Siddharth
***********************************************************************************************/
public with sharing class GenerateFeeRecords {
    public static String className = 'GenerateFeeRecords';
    //method to return RTF Id and create RTF and RTFI records

/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is to
* @return:  
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @InvocableMethod
    public static List<String> recordCreations(List<id> blaids){
        List<String> RTFId = new List<String>();
        try{
            BusinessLicenseApplication blarec = new BusinessLicenseApplication(Id = blaids[0]);
            //check if Application Fee record is present
            List<RegulatoryTrxnFee> RTFids = [SELECT id FROM RegulatoryTrxnFee 
                                              WHERE ParentRecordId =: blarec.Id and FeeType__c = 'Application Fee' 
                                              WITH SECURITY_ENFORCED LIMIT 1];
            if(RTFids.size()>0){
                RTFId.add(RTFids[0].Id);
                return RTFId;
            }
            //Create Regulatory Transaction Fee record
            List<BusinessLicenseApplication> blaList = [SELECT AccountId, LicenseType.OneTimeFee__c 
                                                        FROM BusinessLicenseApplication WHERE id =: blarec.Id 
                                                        WITH SECURITY_ENFORCED LIMIT 1];
            RegulatoryTrxnFee transFeeRec = new RegulatoryTrxnFee(
                AccountId = blaList[0].AccountId,
                DueDate = BCMOH_Constants.feeDueDateTime,
                FeeType__c = 'Application Fee',
                ParentRecordId = blarec.Id,
                Status = 'Paid'
            );
            //Insert RegulatoryTrxnFee record
            Database.SaveResult RTFrec = Database.Insert(transFeeRec);
            RTFId.add(RTFrec.getId());
            //Create Regulatory Transaction Fee Item record
            RegulatoryTrxnFeeItem transFeeItemRec = new RegulatoryTrxnFeeItem(
                RegulatoryTrxnFeeId = RTFrec.getId(),
                Name = 'Application Fee',
                FeeAmount = blaList[0].LicenseType.OneTimeFee__c,
                Amount__c = blaList[0].LicenseType.OneTimeFee__c
            );
            //Insert RegulatoryTrxnFeeItem record
            Database.SaveResult RTFIrec = Database.Insert(transFeeItemRec);
        }
        catch(exception ex){
            LogService.logAndPublish(className, 'recordCreations', '', ex);
        }
        return RTFId;
    }

}