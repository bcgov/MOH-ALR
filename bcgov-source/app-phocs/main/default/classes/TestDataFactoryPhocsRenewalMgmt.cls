@IsTest
public class TestDataFactoryPhocsRenewalMgmt {
    public static final Integer BULK_SIZE = 10;

    public static void createRenewalManagementData() {
        Profile profile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'EHIS Standard User'
            LIMIT 1
        ];

        String unique = String.valueOf(System.currentTimeMillis());
        User closedByUser = new User(
            Alias = 'ptur',
            Email = 'portal' + unique + '@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Portal',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/New_York',
            Username = 'portal' + unique + '@test.com'
        );
        insert closedByUser;

        Id businessEntityRecordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('Business_Entity')
            .getRecordTypeId();
        Account parentAccount = new Account(
            Name = 'Test Parent Account',
            Type = getValidAccountType(),
            RecordTypeId = businessEntityRecordTypeId
        );
        setIfCreateable(parentAccount, 'Status__c', 'Open');
        insert parentAccount;

        Id facilityRecordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('Facility')
            .getRecordTypeId();
        String premiseRole = getFirstPicklistValue(Account.SObjectType, 'PremiseRole__c');
        List<Account> accounts = new List<Account>();
        for (Integer index = 0; index < BULK_SIZE; index++) {
            Account account = new Account(
                Name = 'Renewal Test Account ' + index,
                ParentId = parentAccount.Id,
                SourceSystemIdentifier = 'XXXXXXXX' + index,
                RecordTypeId = facilityRecordTypeId
            );
            setIfCreateable(account, 'Status__c', 'Open');
            setIfCreateable(account, 'Type', 'Drinking water');
            setIfCreateable(account, 'CategoryL1__c', 'Bulk Water Hauler');
            setIfCreateable(account, 'CategoryL2__c', 'Truck');
            setIfCreateable(account, 'OperatingMonths__c', 'January,February');
            setIfCreateable(account, 'MultiplePremiseFacility__c', true);
            setIfCreateable(account, 'NoofConnections__c', '301-10,000 (WS1a)');
            if (premiseRole != null) {
                setIfCreateable(account, 'PremiseRole__c', premiseRole);
            }
            accounts.add(account);
        }
        insert accounts;

        RegulatoryAuthority foodAuthority = new RegulatoryAuthority(
            Name = 'Community Care & Assisted Living Act'
        );
        insert foodAuthority;
        RegulatoryAuthorizationType foodLicenseType = new RegulatoryAuthorizationType(
            Name = 'Food Premises Operating Permit',
            RegulatoryAuthCategory = 'License',
            IssuingDepartmentId = foodAuthority.Id
        );
        insert foodLicenseType;

        RegulatoryAuthority drinkingWaterAuthority = new RegulatoryAuthority(
            Name = 'Drinking Water Protection Act'
        );
        insert drinkingWaterAuthority;
        RegulatoryAuthorizationType drinkingWaterLicenseType = new RegulatoryAuthorizationType(
            Name = 'Drinking Water Operating Permit',
            RegulatoryAuthCategory = 'License',
            IssuingDepartmentId = drinkingWaterAuthority.Id
        );
        insert drinkingWaterLicenseType;

        Id blaRecordTypeId = Schema.SObjectType.BusinessLicenseApplication
            .getRecordTypeInfosByDeveloperName()
            .get('OperatingPermitApplication')
            .getRecordTypeId();
        List<BusinessLicenseApplication> applications = new List<BusinessLicenseApplication>();
        for (Integer index = 0; index < BULK_SIZE; index++) {
            BusinessLicenseApplication application = new BusinessLicenseApplication(
                AccountId = accounts[index].Id,
                RecordTypeId = blaRecordTypeId
            );
            setIfCreateable(application, 'Status', 'Closed');
            setIfCreateable(application, 'ClosureReason__c', 'Approved');
            setIfCreateable(application, 'ClosedDate__c', System.today());
            setIfCreateable(application, 'ClosedBy__c', closedByUser.Id);
            setIfCreateable(application, 'Category', 'Permit');
            setIfCreateable(application, 'AppliedDate', System.today().addMonths(-1));
            setIfCreateable(application, 'LicenseTypeId', drinkingWaterLicenseType.Id);
            applications.add(application);
        }
        insert applications;

        Id businessLicenseRecordTypeId = Schema.SObjectType.BusinessLicense
            .getRecordTypeInfosByDeveloperName()
            .get('PHOCSPermitLicense')
            .getRecordTypeId();
        List<BusinessLicense> licenses = new List<BusinessLicense>();
        for (Integer index = 0; index < BULK_SIZE; index++) {
            BusinessLicense license = new BusinessLicense(
                AccountId = parentAccount.Id,
                RecordTypeId = businessLicenseRecordTypeId
            );
            setIfCreateable(license, 'Account__c', accounts[index].Id);
            setIfCreateable(license, 'Name', 'TestPermit' + index);
            setIfCreateable(license, 'Status', 'Active');
            setIfCreateable(license, 'RegulatoryAuthorizationTypeId', drinkingWaterLicenseType.Id);
            licenses.add(license);
        }
        insert licenses;

        for (Integer index = 0; index < BULK_SIZE; index++) {
            applications[index].LicensePermitNameId = licenses[index].Id;
        }
        update applications;
    }

    public static List<RegulatoryTrxnFee> createRenewalFees(
        List<Id> accountIds,
        List<Id> applicationIds,
        Id recordTypeId,
        String renewalYear
    ) {
        List<RegulatoryTrxnFee> fees = new List<RegulatoryTrxnFee>();
        for (Integer index = 0; index < accountIds.size(); index++) {
            RegulatoryTrxnFee fee = new RegulatoryTrxnFee(
                AccountId = accountIds[index],
                ParentRecordId = applicationIds[index],
                Status__c = 'Draft',
                FeeType__c = 'Renewal',
                RenewalYear__c = renewalYear,
                RecordTypeId = recordTypeId
            );
            fees.add(fee);
        }
        insert fees;
        return fees;
    }

    public static List<RegulatoryTrxnFeeItem> createRenewalFeeItems(
        List<RegulatoryTrxnFee> fees,
        Id recordTypeId
    ) {
        List<RegulatoryTrxnFeeItem> feeItems = new List<RegulatoryTrxnFeeItem>();
        for (RegulatoryTrxnFee fee : fees) {
            feeItems.add(new RegulatoryTrxnFeeItem(
                RegulatoryTrxnFeeId = fee.Id,
                Status__c = 'Due',
                FeeType__c = 'Annual Operating Permit Fees',
                Name = 'Annual Operating Permit Fees',
                FeeAmount = 100,
                RecordTypeId = recordTypeId
            ));
        }
        insert feeItems;
        return feeItems;
    }

    public static String getValidAccountType() {
        Schema.DescribeFieldResult describe = Account.Type.getDescribe();
        for (Schema.PicklistEntry entry : describe.getPicklistValues()) {
            if (entry.isActive() &&
                (entry.getLabel() == 'Food' ||
                 entry.getLabel() == 'Drinking water' ||
                 entry.getLabel() == 'Recreational water')) {
                return entry.getValue();
            }
        }
        return null;
    }

    public static void setIfCreateable(SObject record, String fieldName, Object value) {
        Map<String, Schema.SObjectField> fields = record.getSObjectType().getDescribe().fields.getMap();
        if (fields.containsKey(fieldName) && fields.get(fieldName).getDescribe().isCreateable()) {
            record.put(fieldName, value);
        }
    }

    public static String getFirstPicklistValue(Schema.SObjectType objectType, String fieldName) {
        Map<String, Schema.SObjectField> fields = objectType.getDescribe().fields.getMap();
        if (!fields.containsKey(fieldName)) {
            return null;
        }
        Schema.DescribeFieldResult describe = fields.get(fieldName).getDescribe();
        if (describe.getType() != Schema.DisplayType.Picklist) {
            return null;
        }
        for (Schema.PicklistEntry entry : describe.getPicklistValues()) {
            if (entry.isActive()) {
                return entry.getValue();
            }
        }
        return null;
    }

    public static Id getRecordTypeId(Schema.SObjectType objectType, String developerName) {
        Map<String, Schema.RecordTypeInfo> recordTypes = objectType.getDescribe().getRecordTypeInfosByDeveloperName();
        return recordTypes.containsKey(developerName)
            ? recordTypes.get(developerName).getRecordTypeId()
            : null;
    }
}
