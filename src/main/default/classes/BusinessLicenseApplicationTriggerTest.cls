/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Test Class is to have the methods related to BusinessLicenseApplication trigger
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
                           ALR-553             Keerthana          Renewal Unit Fee  and Late Fee Status in RegulatoryTrxnFee changes according to the application Status and Late fee Status in BLA
***********************************************************************************************/

@isTest
private class BusinessLicenseApplicationTriggerTest {
    @isTest
    static void testUpdateFeeStatusOnApplicationUpdate() {
        
        
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Helath', 'License', 'MH', 1, 2, 3, 4, true);
 
        Account residenceRec1 = TestDataFactory.createResidence('Residence', 'residenceAccount1', regAuth.Id, true);
        Account parentRec = new Account(Id = residenceRec1.ParentId,
                                        BillingStreet = 'csd');
        update parentRec;
        
        BusinessLicenseApplication blaRec = TestDataFactory.createRenewalBla(residenceRec1.LicenseType__c, residenceRec1.Id, true); 
        
        RegulatoryTrxnFee fee1 = new RegulatoryTrxnFee(ParentRecordId = blaRec.Id, FeeType__c = 'Renewal Unit Fee', Status = 'Paid');
        insert fee1;
        
        RegulatoryTrxnFee fee2 = new RegulatoryTrxnFee(ParentRecordId = blaRec.Id, FeeType__c = 'Late Fee', Status = 'Paid');
        insert fee2;
        
        blaRec.Status = 'Errorred';
        blaRec.Late_Fee_Status__c = 'Cancelled';
        update blaRec;
        
        List<RegulatoryTrxnFee> updatedFees = [SELECT Status FROM RegulatoryTrxnFee WHERE ParentRecordId = :blaRec.Id];
        
        System.assertEquals('PAID', updatedFees[0].Status);
        
        // Fee with FeeType__c as 'Late Fee' should be updated because Late_Fee_Status__c is 'Cancelled'
        System.assertEquals('CANCELED', updatedFees[1].Status); 
    }
}