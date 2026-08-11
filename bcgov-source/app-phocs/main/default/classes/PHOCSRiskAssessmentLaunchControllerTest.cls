/**********************************************************************************************
* @Author:      Accenture
* @Date:        09 Aug 2026
* @Description: Test class for PHOCSRiskAssessmentLaunchController.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
                06 Aug -  PHOCS-269         -  Accenture   -  test class for OmniScript launch controller
                09 Aug -  PHOCS-269         -  Accenture   -  updated for getOmniScriptConfiguration()
***********************************************************************************************/
@isTest
public class PHOCSRiskAssessmentLaunchControllerTest {

/**
* @author: Accenture
* @date: 09 Aug 2026
* @description: Creates Accounts used to exercise the null/not-found/blank-type/no-match paths
* of getOmniScriptConfiguration(). The happy-path test resolves its own Account dynamically
* since CMDT records cannot be inserted via DML in a test context.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @testSetup
    static void setupTestData() {
        Account accWithNoMatchingType = new Account(Name = 'PHOCS Test Account - Launch NoMatch', Type = 'PHOCSTest_NonExistent_Type_XYZ');
        Account accWithNoType = new Account(Name = 'PHOCS Test Account - Launch NoType');
        insert new List<Account>{ accWithNoMatchingType, accWithNoType };
    }

/**
* @author: Accenture
* @date: 09 Aug 2026
* @description: Covers getOmniScriptConfiguration() when accountId is null.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetOmniScriptConfiguration_NullAccountId_ThrowsException() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            PHOCSRiskAssessmentLaunchController.getOmniScriptConfiguration(null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.areEqual('Account Id is required.', e.getMessage(), 'Exception message should flag the missing accountId');
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Expected an exception for a null accountId');
    }

/**
* @author: Accenture
* @date: 09 Aug 2026
* @description: Covers getOmniScriptConfiguration() when the accountId does not correspond to
* an existing Account record.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetOmniScriptConfiguration_AccountNotFound_ThrowsException() {
        Account tempAccount = new Account(Name = 'PHOCS Test Account - Temp For Deletion');
        insert tempAccount;
        Id deletedAccountId = tempAccount.Id;
        delete tempAccount;

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            PHOCSRiskAssessmentLaunchController.getOmniScriptConfiguration(deletedAccountId);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.areEqual('Account not found.', e.getMessage(), 'Exception message should flag that the account was not found');
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Expected an exception when the accountId does not match an existing Account');
    }

/**
* @author: Accenture
* @date: 09 Aug 2026
* @description: Covers getOmniScriptConfiguration() when the account has no Type value set.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetOmniScriptConfiguration_BlankAccountType_ThrowsException() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'PHOCS Test Account - Launch NoType' LIMIT 1];
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            PHOCSRiskAssessmentLaunchController.getOmniScriptConfiguration(acc.Id);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.areEqual('Facility Type is required.', e.getMessage(), 'Exception message should flag the missing Type');
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Expected an exception when the account Type is blank');
    }

/**
* @author: Accenture
* @date: 09 Aug 2026
* @description: Covers getOmniScriptConfiguration() when the account's Type has no matching
* LaunchURL metadata record.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetOmniScriptConfiguration_NoMatchingMetadata_ThrowsException() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'PHOCS Test Account - Launch NoMatch' LIMIT 1];
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            PHOCSRiskAssessmentLaunchController.getOmniScriptConfiguration(acc.Id);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.isTrue(e.getMessage().startsWith('No Risk Assessment Tool is configured for Facility Type'), 'Exception message should flag the missing LaunchURL metadata');
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Expected an exception when no LaunchURL metadata matches the account Type');
    }

/**
* @author: Accenture
* @date: 09 Aug 2026
* @description: Covers getOmniScriptConfiguration() end to end, validated dynamically against
* whatever LaunchURL metadata with a populated OmniScriptType__c already exists in the org.
* Custom metadata records cannot be inserted via DML in a test context, so this test is skipped
* if none is deployed yet.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetOmniScriptConfiguration_WithMatchingMetadata_ReturnsConfiguredTypeAndSubtype() {
        List<PHOCSRiskAssessmentScoring__mdt> launchRecords = [SELECT ProgramArea__c, OmniScriptType__c, OmniScriptSubType__c FROM PHOCSRiskAssessmentScoring__mdt
                                                               WHERE AssessmentType__c = 'LaunchURL' AND OmniScriptType__c != null LIMIT 1];
        if (launchRecords.isEmpty()) {
            return;
        }
        String programArea = launchRecords[0].ProgramArea__c;
        String expectedType = launchRecords[0].OmniScriptType__c;
        String expectedSubtype = launchRecords[0].OmniScriptSubType__c;

        Account acc = new Account(Name = 'PHOCS Test Account - Launch Match', Type = programArea);
        insert acc;

        Test.startTest();
        PHOCSRiskAssessmentLaunchController.OmniScriptConfiguration config = PHOCSRiskAssessmentLaunchController.getOmniScriptConfiguration(acc.Id);
        Test.stopTest();

        Assert.areEqual(expectedType, config.type, 'Returned type should match the configured LaunchURL metadata for this program area');
        Assert.areEqual(expectedSubtype, config.subtype, 'Returned subtype should match the configured LaunchURL metadata for this program area');
        Assert.areEqual('English', config.language, 'Language should always be fixed to English');
    }
}