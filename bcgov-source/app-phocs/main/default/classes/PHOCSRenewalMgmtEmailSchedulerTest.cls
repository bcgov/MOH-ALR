@IsTest
private class PHOCSRenewalMgmtEmailSchedulerTest {
    private static final String BILLING_EMAIL = 'renewal.billing@test.example';

    @TestSetup
    static void setupData() {
        TestDataFactoryPhocsRenewalMgmt.createRenewalManagementData();

        List<Account> accounts = [
            SELECT Id, Name, ParentId, SourceSystemIdentifier
            FROM Account
            WHERE SourceSystemIdentifier LIKE 'XXXXXXXX%'
            ORDER BY SourceSystemIdentifier
        ];
        Set<Id> accountIds = new Map<Id, Account>(accounts).keySet();
        Map<Id, BusinessLicenseApplication> applicationsByAccount = new Map<Id, BusinessLicenseApplication>();
        for (BusinessLicenseApplication application : [
            SELECT Id, AccountId
            FROM BusinessLicenseApplication
            WHERE AccountId IN :accountIds
        ]) {
            applicationsByAccount.put(application.AccountId, application);
        }

        List<Id> feeAccountIds = new List<Id>();
        List<Id> applicationIds = new List<Id>();
        for (Account account : accounts) {
            feeAccountIds.add(account.Id);
            applicationIds.add(applicationsByAccount.get(account.Id).Id);
        }
        Id feeRecordTypeId = TestDataFactoryPhocsRenewalMgmt.getRecordTypeId(
            RegulatoryTrxnFee.SObjectType,
            'PHOCSNonDairyTransactionFee'
        );
        List<RegulatoryTrxnFee> fees = TestDataFactoryPhocsRenewalMgmt.createRenewalFees(
            feeAccountIds,
            applicationIds,
            feeRecordTypeId,
            String.valueOf(System.today().year())
        );

        fees[0].EmailStatus__c = 'Invoice Notification Queued';
        fees[1].EmailStatus__c = 'Payment Reminder Queued';
        fees[2].EmailStatus__c = 'Late Fee Notification Queued';
        update fees;

        Account parentAccount = [
            SELECT Id
            FROM Account
            WHERE Id = :accounts[0].ParentId
        ];
        Contact billingContact = new Contact(
            FirstName = 'Renewal',
            LastName = 'Billing',
            Email = BILLING_EMAIL,
            AccountId = parentAccount.Id
        );
        insert billingContact;
        AccountContactRelation parentRelation = [
            SELECT Id, Roles
            FROM AccountContactRelation
            WHERE AccountId = :parentAccount.Id AND ContactId = :billingContact.Id
            LIMIT 1
        ];
        parentRelation.Roles = 'Billing Contact';
        parentRelation.IsActive = true;
        update parentRelation;
    }

  /*  @IsTest
static void testGetFeeContactEmailsPrefersParentBillingContact() {
    List<Account> accounts = getRenewalAccounts();

    Contact secondParentBilling = new Contact(
        FirstName = 'Second',
        LastName = 'Parent Billing',
        Email = 'parent.billing2@test.example',
        AccountId = accounts[0].ParentId
    );
    insert secondParentBilling;

    setContactRoles(
        secondParentBilling.Id,
        accounts[0].ParentId,
        'Billing Contact'
    );

    Contact childBillingContact = new Contact(
        FirstName = 'Child',
        LastName = 'Billing',
        Email = 'child.billing@test.example',
        AccountId = accounts[0].Id
    );
    insert childBillingContact;

    setContactRoles(
        childBillingContact.Id,
        accounts[0].Id,
        'Operator'
    );

    Test.startTest();
    Map<RegulatoryTrxnFee, List<String>> feeEmails =
        PHOCSRenewalMgmtEmailScheduler.getFeeContactEmails();
    Test.stopTest();

    System.assertEquals(10, feeEmails.size());

    for (RegulatoryTrxnFee fee : feeEmails.keySet()) {
        if (fee.AccountId == accounts[0].Id) {
            System.assertEquals(
                new Set<String>{
                    BILLING_EMAIL,
                    'parent.billing2@test.example'
                },
                new Set<String>(feeEmails.get(fee))
            );

            System.assert(
                !feeEmails.get(fee).contains('child.billing@test.example'),
                'Child Billing Contact must not be included when Parent Billing Contacts exist.'
            );
        }
    }
}*/

    @IsTest
    static void testChildBillingContactPrecedesParentOwner() {
        List<Account> accounts = getRenewalAccounts();
        Account parentAccount = [SELECT ParentId FROM Account WHERE Id = :accounts[0].Id];
        Contact parentContact = [SELECT Id FROM Contact WHERE Email = :BILLING_EMAIL LIMIT 1];
        setContactRoles(parentContact.Id, parentAccount.ParentId, 'Owner');

        Contact childContact = new Contact(
            FirstName = 'Child',
            LastName = 'Priority',
            Email = 'child.priority@test.example',
            AccountId = accounts[0].Id
        );
        insert childContact;
        setContactRoles(childContact.Id, accounts[0].Id, 'Billing Contact');

        Map<RegulatoryTrxnFee, List<String>> feeEmails = PHOCSRenewalMgmtEmailScheduler.getFeeContactEmails();
        for (RegulatoryTrxnFee fee : feeEmails.keySet()) {
            if (fee.AccountId == accounts[0].Id) {
                System.assertEquals('child.priority@test.example', feeEmails.get(fee)[0]);
            } else {
                System.assertEquals(BILLING_EMAIL, feeEmails.get(fee)[0]);
            }
        }
    }
    @IsTest
static void testChildBillingContactFallbackWhenNoParentBillingContact() {
    List<Account> accounts = getRenewalAccounts();
    Account parentAccount = [
        SELECT ParentId
        FROM Account
        WHERE Id = :accounts[0].Id
    ];

    Contact parentContact = [
        SELECT Id
        FROM Contact
        WHERE Email = :BILLING_EMAIL
        LIMIT 1
    ];

    setContactRoles(parentContact.Id, parentAccount.ParentId, 'Applicant');

    Contact childBilling = new Contact(
        FirstName = 'Child',
        LastName = 'Billing',
        Email = 'child.billing.fallback@test.example',
        AccountId = accounts[0].Id
    );
    insert childBilling;

    setContactRoles(
        childBilling.Id,
        accounts[0].Id,
        'Billing Contact'
    );

    Map<RegulatoryTrxnFee, List<String>> feeEmails =
        PHOCSRenewalMgmtEmailScheduler.getFeeContactEmails();

    for (RegulatoryTrxnFee fee : feeEmails.keySet()) {
        if (fee.AccountId == accounts[0].Id) {
            System.assertEquals(
                new List<String>{ 'child.billing.fallback@test.example' },
                feeEmails.get(fee)
            );
        }
    }
}

    @IsTest
    static void testAccountOwnerFallbackWhenNoParentContactMatches() {
        List<Account> accounts = getRenewalAccounts();
        Account parentAccount = [SELECT ParentId FROM Account WHERE Id = :accounts[0].Id];
        Contact parentContact = [SELECT Id FROM Contact WHERE Email = :BILLING_EMAIL LIMIT 1];
        setContactRoles(parentContact.Id, parentAccount.ParentId, null);

        Contact accountOwner = new Contact(
            FirstName = 'Account',
            LastName = 'Owner',
            Email = 'account.owner@test.example',
            AccountId = accounts[0].Id
        );
        insert accountOwner;
        setContactRoles(accountOwner.Id, accounts[0].Id, 'Owner');

        Map<RegulatoryTrxnFee, List<String>> feeEmails =
            PHOCSRenewalMgmtEmailScheduler.getFeeContactEmails();
        for (RegulatoryTrxnFee fee : feeEmails.keySet()) {
            System.assertEquals(
                fee.AccountId == accounts[0].Id
                    ? 'account.owner@test.example'
                    : 'No Email Found',
                feeEmails.get(fee)[0]
            );
        }
    }

   /* @IsTest
    static void testParentOperatorFallbackAfterOwnerTiers() {
        List<Account> accounts = getRenewalAccounts();
        Account parentAccount = [SELECT ParentId FROM Account WHERE Id = :accounts[0].Id];
        Contact parentContact = [SELECT Id FROM Contact WHERE Email = :BILLING_EMAIL LIMIT 1];
        setContactRoles(parentContact.Id, parentAccount.ParentId, 'Operator');

        Map<RegulatoryTrxnFee, List<String>> feeEmails =
            PHOCSRenewalMgmtEmailScheduler.getFeeContactEmails();
        System.assert(feeEmails.size() > 0);
        for (List<String> emailAddress : feeEmails.values()) {
            System.assertEquals(BILLING_EMAIL, emailAddress[0]);
        }
    } */

    @IsTest
    static void testOperatorFallbackExcludesSecondaryAndTertiaryOperators() {
        List<Account> accounts = getRenewalAccounts();
        Account parentAccount = [SELECT ParentId FROM Account WHERE Id = :accounts[0].Id];
        Contact parentContact = [SELECT Id FROM Contact WHERE Email = :BILLING_EMAIL LIMIT 1];
        setContactRoles(
            parentContact.Id,
            parentAccount.ParentId,
            'Operator;Secondary Operator'
        );

        Contact secondaryOperator = new Contact(
            FirstName = 'Secondary',
            LastName = 'Operator',
            Email = 'secondary.operator@test.example',
            AccountId = accounts[0].Id
        );
        Contact tertiaryOperator = new Contact(
            FirstName = 'Tertiary',
            LastName = 'Operator',
            Email = 'tertiary.operator@test.example',
            AccountId = accounts[1].Id
        );
        Contact primaryOperator = new Contact(
            FirstName = 'Primary',
            LastName = 'Operator',
            Email = 'primary.operator@test.example',
            AccountId = accounts[2].Id
        );
        insert new List<Contact>{secondaryOperator, tertiaryOperator, primaryOperator};
        setContactRoles(
            secondaryOperator.Id,
            accounts[0].Id,
            'Operator;Secondary Operator'
        );
        setContactRoles(
            tertiaryOperator.Id,
            accounts[1].Id,
            'Operator;Tertiary Operator'
        );
        setContactRoles(primaryOperator.Id, accounts[2].Id, 'Operator');

        Map<RegulatoryTrxnFee, List<String>> feeEmails =
            PHOCSRenewalMgmtEmailScheduler.getFeeContactEmails();
        for (RegulatoryTrxnFee fee : feeEmails.keySet()) {
            String expectedEmail = fee.AccountId == accounts[2].Id
                ? 'primary.operator@test.example'
                : 'No Email Found';
            System.assertEquals(expectedEmail, feeEmails.get(fee)[0]);
        }
    }
    @IsTest
    static void testExecuteSendsAllQueuedTemplatesAndAttachesLatestFile() {
        List<RegulatoryTrxnFee> fees = getRenewalFees();
        PHOCSRenewalMgmtEmailScheduler.testTemplates = buildTemplates();

        ContentVersion firstVersion = new ContentVersion(
            Title = 'Renewal invoice',
            PathOnClient = 'renewal-invoice.pdf',
            VersionData = Blob.valueOf('first version'),
            FirstPublishLocationId = fees[0].Id
        );
        insert firstVersion;
        ContentDocumentLink documentLink = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :fees[0].Id
            LIMIT 1
        ];
        insert new ContentVersion(
            Title = 'Renewal invoice updated',
            PathOnClient = 'renewal-invoice.pdf',
            VersionData = Blob.valueOf('latest version'),
            ContentDocumentId = documentLink.ContentDocumentId
        );

        Test.startTest();
        new PHOCSRenewalMgmtEmailScheduler().execute(null);
        Test.stopTest();

        Map<Id, RegulatoryTrxnFee> refreshedFees = new Map<Id, RegulatoryTrxnFee>([
            SELECT Id, EmailStatus__c
            FROM RegulatoryTrxnFee
            WHERE Id IN :fees
        ]);
        System.assertEquals('Sent', refreshedFees.get(fees[0].Id).EmailStatus__c);
        System.assertEquals('Sent', refreshedFees.get(fees[1].Id).EmailStatus__c);
        System.assertEquals('Sent', refreshedFees.get(fees[2].Id).EmailStatus__c);
       // System.assert(Limits.getEmailInvocations() > 0);
    }

/*    @IsTest
    static void testMergeFieldsUseRegulatoryTransactionFeeValues() {
        RegulatoryTrxnFee fee = [
            SELECT Id, Name, RenewalYear__c, PHOCSCustomerID__c
            FROM RegulatoryTrxnFee
            WHERE FeeType__c = 'Renewal'
            LIMIT 1
        ];
        String templateContent =
            'Fee {{{RegulatoryTrxnFee.Name}}}, year {{{RegulatoryTrxnFee.RenewalYear__c}}}, ' +
            'customer {{{RegulatoryTrxnFee.PHOCSCustomerID__c}}}, ' +
            'unknown {{{RegulatoryTrxnFee.NotAField__c}}}';

        String populatedContent =
            PHOCSRenewalMgmtEmailScheduler.populateMergeFields(templateContent, fee);

        System.assertEquals(
            'Fee ' + fee.Name + ', year ' + fee.RenewalYear__c + ', customer , unknown ',
            populatedContent
        );
        System.assertEquals(
            null,
            PHOCSRenewalMgmtEmailScheduler.populateMergeFields(null, fee)
        );
        System.assertEquals(
            '',
            PHOCSRenewalMgmtEmailScheduler.populateMergeFields('', fee)
        );
    }*/

    @IsTest
    static void testGetFeeContactEmailsReturnsEmptyWhenNoFeesAreQueued() {
        List<RegulatoryTrxnFee> fees = getRenewalFees();
        for (RegulatoryTrxnFee fee : fees) {
            fee.EmailStatus__c = 'Sent';
        }
        update fees;

        Test.startTest();
        Map<RegulatoryTrxnFee, List<String>> feeEmails =
            PHOCSRenewalMgmtEmailScheduler.getFeeContactEmails();
        Test.stopTest();

        System.assertEquals(0, feeEmails.size());
    }

    @IsTest
    static void testSendSkipsRecipientWithoutMatchingContact() {
        List<RegulatoryTrxnFee> fees = getRenewalFees();
        RegulatoryTrxnFee fee = fees[0];
        PHOCSRenewalMgmtEmailScheduler.testTemplates = buildTemplates();

        Test.startTest();
        PHOCSRenewalMgmtEmailScheduler.sendFeeEmails(
            new Map<RegulatoryTrxnFee, List<String>>{
                fee => new List<String>{
                    'missing.contact@test.example'
                    } 
            }
        );
        Test.stopTest();

        System.assertEquals(0, Limits.getEmailInvocations());
    }
/*
    @IsTest
    static void testNoEmailAndEmptyInputs() {
        List<RegulatoryTrxnFee> fees = getRenewalFees();
        Account parentAccount = [SELECT ParentId FROM Account WHERE Id = :fees[0].AccountId];
        Contact parentContact = [SELECT Id FROM Contact WHERE Email = :BILLING_EMAIL LIMIT 1];
        setContactRoles(parentContact.Id, parentAccount.ParentId, 'Applicant');

        Test.startTest();
        Map<RegulatoryTrxnFee, List<String>> feeEmails = PHOCSRenewalMgmtEmailScheduler.getFeeContactEmails();
        PHOCSRenewalMgmtEmailScheduler.sendFeeEmails(feeEmails);
        PHOCSRenewalMgmtEmailScheduler.sendFeeEmails(null);
        PHOCSRenewalMgmtEmailScheduler.sendFeeEmails(new Map<RegulatoryTrxnFee, List<String>>());
        Test.stopTest();

        System.assertEquals(10, feeEmails.size());
        for (List<String> emailAddress : feeEmails.values()) {
            System.assertEquals('No Email Found', emailAddress[0]);
        }
        Set<Id> queuedFeeIds = new Map<Id, RegulatoryTrxnFee>(fees).keySet();
        for (RegulatoryTrxnFee fee : [
            SELECT EmailStatus__c
            FROM RegulatoryTrxnFee
            WHERE Id IN :queuedFeeIds
        ]) {
            System.assertEquals('No Email Found', fee.EmailStatus__c);
        }
    } */

    private static List<Account> getRenewalAccounts() {
        return [
            SELECT Id, ParentId, SourceSystemIdentifier
            FROM Account
            WHERE SourceSystemIdentifier LIKE 'XXXXXXXX%'
            ORDER BY SourceSystemIdentifier
        ];
    }

    private static List<RegulatoryTrxnFee> getRenewalFees() {
        return [
            SELECT Id, AccountId, ParentRecordId, EmailStatus__c, Name
            FROM RegulatoryTrxnFee
            WHERE FeeType__c = 'Renewal'
            ORDER BY AccountId
        ];
    }

    private static void setContactRoles(Id contactId, Id accountId, String roles) {
        AccountContactRelation relation = [
            SELECT Id, Roles
            FROM AccountContactRelation
            WHERE ContactId = :contactId AND AccountId = :accountId
            LIMIT 1
        ];
        relation.Roles = roles;
        update relation;
    }

    private static Map<String, EmailTemplate> buildTemplates() {
        return new Map<String, EmailTemplate>{
            'PHOCS New Invoice Available' => new EmailTemplate(
                Name = 'PHOCS New Invoice Available',
                Subject = 'Invoice {{{RegulatoryTrxnFee.Name}}}',
                HtmlValue = '<p>{{{RegulatoryTrxnFee.RenewalYear__c}}}</p>',
                Body = 'Invoice {{{RegulatoryTrxnFee.Name}}}'
            ),
            'PHOCS Payment Reminder Email' => new EmailTemplate(
                Name = 'PHOCS Payment Reminder Email',
                Subject = 'Reminder {{{RegulatoryTrxnFee.Name}}}',
                HtmlValue = '<p>Reminder</p>',
                Body = 'Reminder'
            ),
            'PHOCS Renewal New Invoice Available' => new EmailTemplate(
                Name = 'PHOCS Renewal New Invoice Available',
                Subject = 'Renewal {{{RegulatoryTrxnFee.Name}}}',
                HtmlValue = '<p>Renewal</p>',
                Body = 'Renewal'
            )
        };
    }
    //added by Yuvashree
@IsTest
static void testSkipFeeWithoutParentRecord() {
    RegulatoryTrxnFee skippedFee = getRenewalFees()[0];
    skippedFee.ParentRecordId = null;
    update skippedFee;
    Test.startTest();
    Map<RegulatoryTrxnFee,List<String>> result = PHOCSRenewalMgmtEmailScheduler.getFeeContactEmails();
    Test.stopTest();
    for(RegulatoryTrxnFee fee : result.keySet()){
        System.assertNotEquals(skippedFee.Id,fee.Id);
    }
}
    @IsTest
static void testNoEmailFoundStatusUpdate() {
    RegulatoryTrxnFee fee = getRenewalFees()[0];
    Test.startTest();
    PHOCSRenewalMgmtEmailScheduler.sendFeeEmails( 
        new Map<RegulatoryTrxnFee,List<String>>{
            fee => new List<String>{'No Email Found'}
        }
    );
    Test.stopTest();
    fee = [SELECT EmailStatus__c  FROM RegulatoryTrxnFee WHERE Id = :fee.Id];
    System.assertEquals('No Email Found',fee.EmailStatus__c);
}
}