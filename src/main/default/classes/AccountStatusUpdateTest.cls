/**
* @Name              : AccountStatusUpdate
* @Description       : Test Class for Updating Account Status on April 1st and May 1st
* @Author            : Keerthana Srinivasan (Accenture)
* @StoryNo           : ALR-1289
**/

@isTest
private class AccountStatusUpdateTest {

    @isTest
    static void testUpdateAccountStatusToRegisteredActivePendingRenewals() {
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Helath', 'License', 'MH', 1, 2, 3, 4, true);
 
        Account residenceRec1 = TestDataFactory.createResidence('Residence', 'residenceAccount1', regAuth.Id, true);
        Account parentRec = new Account(Id = residenceRec1.ParentId,
                                        BillingStreet = 'csd');
        update parentRec;
        
       BusinessLicenseApplication blaRec = TestDataFactory.createRenewalBla(residenceRec1.LicenseType__c, residenceRec1.Id, true); 
        
        // Ensure that the BLA status matches the conditions in the query
        blaRec.Status = BCMOH_Constants.blaCreatedStatus;
        update blaRec;
        
       RegulatoryTrxnFee fee1 = new RegulatoryTrxnFee(ParentRecordId = blaRec.Id, FeeType__c = 'Renewal Unit Fee', Status = 'Due');
        insert fee1;

        Test.startTest();
        AccountStatusUpdate.updateAccountStatusToRegisteredActivePendingRenewals();
        Test.stopTest();

        residenceRec1 = [SELECT Status__c FROM Account WHERE Id = :residenceRec1.Id];
        System.assertEquals('Registered Active with Conditions', residenceRec1.Status__c);
       }

    @isTest
    static void testUpdateAccountStatusToUnregisteredActivePendingRenewals() {
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Helath', 'License', 'MH', 1, 2, 3, 4, true);
 
        Account residenceRec1 = TestDataFactory.createResidence('Residence', 'residenceAccount1', regAuth.Id, true);
        Account parentRec = new Account(Id = residenceRec1.ParentId,
                                        BillingStreet = 'csd');
        update parentRec;
        
        BusinessLicenseApplication blaRec = TestDataFactory.createRenewalBla(residenceRec1.LicenseType__c, residenceRec1.Id, true); 
        // Ensure that the BLA status matches the conditions in the query
        blaRec.Status = BCMOH_Constants.blaCreatedStatus;
        update blaRec;
        
        RegulatoryTrxnFee fee1 = new RegulatoryTrxnFee(ParentRecordId = blaRec.Id, FeeType__c = 'Renewal Unit Fee', Status = 'Due');
        insert fee1;
        
         Test.startTest();
      
        AccountStatusUpdate.updateAccountStatusToUnregisteredActivePendingRenewals();
        residenceRec1 = [SELECT Status__c FROM Account WHERE Id = :residenceRec1.Id];
        System.assertEquals('Registered Active with Conditions', residenceRec1.Status__c);
         Test.stopTest();
        
        
        Assert.isNotNull(residenceRec1.Status__c, 'Status__c should not be null');
           }
}