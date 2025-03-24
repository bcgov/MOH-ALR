/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Class is to Create Regulatory Transaction Fee and Regulatory Transaction Fee Item records related to BLA
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]  
                              ALR-660           Siddharth     Generating Regulatory Transaction Fee
***********************************************************************************************/
public with sharing class GenerateFeeRecords {
    public static String className = 'GenerateFeeRecords';
/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is to return RTF Id and create RTF and RTFI records
* @return:  List of String
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @InvocableMethod
    public static List<String> recordCreations(List<id> blaids){
        List<String> rTFId = new List<String>();
        try{
            BusinessLicenseApplication blarec = new BusinessLicenseApplication(Id = blaids[0]);
            //check if Application Fee record is present
            List<RegulatoryTrxnFee> rTFIds = [SELECT id FROM RegulatoryTrxnFee 
                                              WHERE ParentRecordId =: blarec.Id and FeeType__c = 'Application Fee' 
                                              WITH SECURITY_ENFORCED LIMIT 1];
            if(rTFIds.size()>0){
                rTFId.add(rTFIds[0].Id);
                return rTFId;
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
            Database.SaveResult rTFrec = Database.Insert(transFeeRec);
            rTFId.add(rTFrec.getId());
            //Create Regulatory Transaction Fee Item record
            RegulatoryTrxnFeeItem transFeeItemRec = new RegulatoryTrxnFeeItem(
                RegulatoryTrxnFeeId = rTFrec.getId(),
                Name = 'Application Fee',
                FeeAmount = blaList[0].LicenseType.OneTimeFee__c,
                Amount__c = blaList[0].LicenseType.OneTimeFee__c
            );
            //Insert RegulatoryTrxnFeeItem record
            Database.SaveResult rTFIrec = Database.Insert(transFeeItemRec);
        }
        catch(exception ex){
            LogService.logAndPublish(className, 'recordCreations', '', ex);
        }
        return rTFId;
    }

}