/**********************************************************************************************
* @Author:      Accenture 
* @Date:        02 Jul 2026
* @Description: The purpose of this class is to cover Code coverage of LabTestRequisitionTriggerHandler.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                02 Jul -  PHOCS-4682        -  Accenture   -  Update the Lab Requisition Number.
***********************************************************************************************/
@isTest
public class LabTestRequisitionTriggerHandlerTest {
    
    //Test Data Setup
     @testSetup
    private static void createTestData() {
        Id rtPHOCSFacilityRecordType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId();
        
        Account facility = new Account(Name = 'Test Facility', RecordTypeId = rtPHOCSFacilityRecordType);
        insert facility;           
    }
    
    
/**
* @author: Deepak
* @date: 02 Jul 2026
* @description: The purpose of this method is to cover Testcoverage of populateLabTestRequisitionNumber.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/      
    @isTest
    public static void createRegulatoryCodeViolationsTest(){
        createTestData();
        Account facility = [SELECT Id, AccountNumberRTPrefixed__c FROM Account WHERE Name = 'Test Facility' LIMIT 1];

        LabTestRequisition__c reqObj = new LabTestRequisition__c(FacilityName__c = facility.Id);

        Test.startTest();
        insert reqObj;
        Test.stopTest();
        
        List<LabTestRequisition__c> reqRec = [SELECT Name, LabTestRequisitionNumber__c, FacilityName__r.AccountNumberRTPrefixed__c FROM LabTestRequisition__c WHERE Id = :reqObj.Id LIMIT 1];
        String expected = 'PHOCS-' +  reqRec[0].FacilityName__r.AccountNumberRTPrefixed__c + '-' + reqRec[0].Name.replace('LTR-', '');

        Assert.areEqual(expected, reqRec[0].LabTestRequisitionNumber__c, 'The Both Strings should be identical');
        Assert.areNotEqual(null, reqRec[0].LabTestRequisitionNumber__c, 'The requisition number cannot be blank');
    }
    
/**
* @author: Deepak
* @date: 02 Jul 2026
* @description: The purpose of this method is to cover Negative Testcoverage of populateLabTestRequisitionNumber.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/      
    @isTest
    public static void negativeCatchBlock() {
        LabTestRequisitionTriggerHandler.throwExceptionForTest = true;
        
        Test.startTest();
        try {
            LabTestRequisitionTriggerHandler.populateLabTestRequisitionNumber(new List<LabTestRequisition__c>());
            System.assert(false, 'Exception expected');
        } catch (Exception e) {
            Assert.areEqual('Test Exception', e.getMessage());
        }
        Test.stopTest();
    }
}