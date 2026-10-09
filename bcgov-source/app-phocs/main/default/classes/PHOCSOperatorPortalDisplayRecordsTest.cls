@isTest(SeeAllData=false)
private class PHOCSOperatorPortalDisplayRecordsTest {
    @testSetup
    static void setupData() {
        Account facility = new Account(
            Name = 'Test Facility',
            Phone = '2505551234',
            RecordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId()
        );
        insert facility;
        
        RegulatoryTrxnFee fee = new RegulatoryTrxnFee(
            AccountId = facility.Id,
            Status = 'Due',
            RecordTypeId = Schema.SObjectType.RegulatoryTrxnFee
            .getRecordTypeInfosByDeveloperName().get('PHOCSNonDairyTransactionFee').getRecordTypeId()
        );
        insert fee;
        
        insert new RegulatoryTrxnFeeItem(
            RegulatoryTrxnFeeId = fee.Id,
            RecordTypeId = Schema.SObjectType.RegulatoryTrxnFeeItem
            .getRecordTypeInfosByDeveloperName().get('PHOCSNonDairyTransactionFeeItem').getRecordTypeId(),
            Name = 'Test Fee Item',
            FeeAmount = 258,
            Amount__c = 258,
            Status__c = 'Due'
        );
    }
    
    @isTest
    static void testServiceMethods() {
        Account facility = [SELECT Id FROM Account WHERE Name = 'Test Facility' LIMIT 1];
        RegulatoryTrxnFee fee = [SELECT Id FROM RegulatoryTrxnFee LIMIT 1];
        RegulatoryTrxnFeeItem feeItem = [SELECT Id FROM RegulatoryTrxnFeeItem LIMIT 1];
        
        Test.startTest();
        System.assertEquals(null, PHOCSOperatorPortalDisplayRecords.getAccountIdForCommunityUser());
        System.assertNotEquals(null, PHOCSOperatorPortalDisplayRecords.getRecordsList('BLAMyApplicationsList'));
        System.assertNotEquals(null, PHOCSOperatorPortalDisplayRecords.getRelatedList(facility.Id, 'PortalFacilityBLAList'));
        List<Object> feeResults = PHOCSOperatorPortalDisplayRecords.getRecordDetails(
            fee.Id, 'RegulatoryTransactionFeeDetail'
        );
        List<Object> itemResults = PHOCSOperatorPortalDisplayRecords.getRecordDetails(
            feeItem.Id, 'RegulatoryTransactionFeeItemDetail'
        );
        Test.stopTest();
        
        System.assertEquals(1, feeResults.size());
        System.assertEquals(1, itemResults.size());
        System.assertEquals('$258.00', ((Map<String, Object>) itemResults[0]).get('FeeAmountFormatted'));
    }
    
    @isTest
    static void testMissingRecordIds() {
        try {
            PHOCSOperatorPortalDisplayRecords.getRecordDetails(null, 'PortalFacilityDetail');
            System.assert(false, 'Expected an exception for a missing record ID');
        } catch (AuraHandledException expectedException) {
            System.assertNotEquals(null, expectedException);
        }
        
        try {
            PHOCSOperatorPortalDisplayRecords.getRelatedList(null, 'PortalFacilityBLAList');
            System.assert(false, 'Expected an exception for a missing record ID');
        } catch (AuraHandledException expectedException) {
            System.assertNotEquals(null, expectedException);
        }
    }
    
    @isTest
    static void testFacilityAndFeeWrappers() {
        Account facility = new Account(
            Name = 'Wrapper Facility',
            Type = 'Drinking Water',
            CategoryL1__c = 'Community Water System',
            Phone = '2505551234'
        );
        facility.Physical_Address__Street__s = '123 Main Street';
        facility.Physical_Address__City__s = 'Victoria';
        facility.putSObject('FacilityHierarchy__r', new Account(Name = 'Test Hierarchy'));
        
        Map<String, Object> facilityResult = (Map<String, Object>)
            new PHOCSOperatorPortalDisplayRecords.PortalFacilityDetailWrapper().wrap(facility);
        System.assertEquals('(250)-555-1234', facilityResult.get('Phone'));
        System.assertEquals('Wrapper Facility', facilityResult.get('Name'));
        
        RegulatoryTrxnFee fee = [
            SELECT TotalFeeAmount, OutstandingFeeAmount__c, DueDate,Status__c 
            FROM RegulatoryTrxnFee
            LIMIT 1
        ];
        Map<String, Object> feeResult = (Map<String, Object>)
            new PHOCSOperatorPortalDisplayRecords.RegulatoryTransactionFeeDetailWrapper().wrap(fee);
        System.assertEquals('$258.00', feeResult.get('TotalFeeAmountFormatted'));
        
        RegulatoryTrxnFeeItem item = new RegulatoryTrxnFeeItem(FeeAmount = 258);
        Map<String, Object> itemResult = (Map<String, Object>)
            new PHOCSOperatorPortalDisplayRecords.RegulatoryTransactionFeeItemDetailWrapper().wrap(item);
        System.assertEquals('$258.00', itemResult.get('FeeAmountFormatted'));
    }
    
    @isTest
    static void testBusinessLicenseWrappers() {
        Account facility = new Account(Name = 'License Facility');
        RegulatoryAuthorizationType licenseType = new RegulatoryAuthorizationType(Name = 'Test License');
        
        BusinessLicense license = new BusinessLicense(Identifier = 'LIC-001', Status = 'Active');
        license.putSObject('RegulatoryAuthorizationType', licenseType);
        license.putSObject('Account__r', facility);
        Map<String, Object> licenseResult = (Map<String, Object>)
            new PHOCSOperatorPortalDisplayRecords.BusinessLicenseListWrapper().wrap(license);
        System.assertEquals('LIC-001', licenseResult.get('Identifier'));
        
        BusinessLicenseApplication application = new BusinessLicenseApplication(Status = 'Submitted');
        application.putSObject('LicenseType', licenseType);
        application.putSObject('Account', facility);
        
        System.assertNotEquals(null,
                               new PHOCSOperatorPortalDisplayRecords.BusinessLicenseListApplicationListWrapper().wrap(application));
        System.assertNotEquals(null,
                               new PHOCSOperatorPortalDisplayRecords.BusinessLicenseListApplicationDetailWrapper().wrap(application));
        System.assertNotEquals(null,
                               new PHOCSOperatorPortalDisplayRecords.BusinessLicenseApplicationListWrapper().wrap(application));
        System.assertNotEquals(null,
                               new PHOCSOperatorPortalDisplayRecords.PortalFacilityBLAListWrapper().wrap(application));
    }
    
    @IsTest
    static void testWaterSourceStatusComparator() {
        
        Account activeAccount = new Account(
            Name = 'Active Water Source',
            Status__c = 'Active'
        );
        
        Account inactiveAccount = new Account(
            Name = 'Inactive Water Source',
            Status__c = 'Inactive'
        );
        
        Account decommissionedAccount = new Account(
            Name = 'Decommissioned Water Source',
            Status__c = 'Decommissioned'
        );
        
        AccountAccountRelation activeRelation = new AccountAccountRelation(
            RelatedAccount = activeAccount
        );
        
        AccountAccountRelation inactiveRelation = new AccountAccountRelation(
            RelatedAccount = inactiveAccount
        );
        
        AccountAccountRelation decommissionedRelation = new AccountAccountRelation(
            RelatedAccount = decommissionedAccount
        );
        
        PHOCSOperatorPortalDisplayRecords.WaterSourceStatus comparator =
            new PHOCSOperatorPortalDisplayRecords.WaterSourceStatus();
        
        System.assertEquals(-1, comparator.compare(activeRelation, inactiveRelation));
        System.assertEquals(-1, comparator.compare(inactiveRelation, decommissionedRelation));
        System.assertEquals(-2, comparator.compare(activeRelation, decommissionedRelation));
        System.assertEquals(1, comparator.compare(inactiveRelation, activeRelation));
        System.assertEquals(1, comparator.compare(decommissionedRelation, inactiveRelation));
        System.assertEquals(0, comparator.compare(activeRelation, activeRelation));
    }
    
    @IsTest
    static void testPortalFacilityDWSystemListWrapper() {
        
        Asset testAsset = new Asset(
            Name = 'Test DW System',
            Status = 'Active',
            Type__c = 'Hospice'
        );
        
        Map<String, Object> result =
            (Map<String, Object>)
            new PHOCSOperatorPortalDisplayRecords.PortalFacilityDWSystemListWrapper()
            .wrap(testAsset);
        
        System.assertEquals(testAsset.Id, result.get('Id'));
        System.assertEquals(testAsset.Name, result.get('Name'));
        System.assertEquals(testAsset.Status, result.get('Status'));
        System.assertEquals(testAsset.Type__c, result.get('Type'));
    }
    
}