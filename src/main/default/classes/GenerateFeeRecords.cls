/**
* @Name              : GenerateFeeRecords
* @Description       : Create Regulatory Transaction Fee and Regulatory Transaction Fee Item records related to BLA
* @Author            : Siddharth (Accenture)
* @StoryNo           : ALR-660
**/


public class GenerateFeeRecords {
    //method to return RTF Id and create RTF and RTFI records
    @InvocableMethod
    public static List<String> recordCreations(List<id> blaids){
        List<String> RTFId = new List<String>();
        try{
            BusinessLicenseApplication blarec = new BusinessLicenseApplication(Id = blaids[0]);
            //check if Application Fee record is present
            List<RegulatoryTrxnFee> RTFids = [select id from RegulatoryTrxnFee where ParentRecordId =: blarec.Id and FeeType__c = 'Application Fee' LIMIT 1];
            if(RTFids.size()>0){
                RTFId.add(RTFids[0].Id);
                return RTFId;
            }
            //Create Regulatory Transaction Fee record
            List<BusinessLicenseApplication> blaList = [Select AccountId, LicenseType.OneTimeFee__c from BusinessLicenseApplication where id =: blarec.Id LIMIT 1];
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
            system.debug(ex.getMessage());
        }
        return RTFId;
    }

}