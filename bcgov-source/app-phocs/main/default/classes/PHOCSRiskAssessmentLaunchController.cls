/**********************************************************************************************
* @Author:      Accenture
* @Date:        06 Aug 2026
* @Description: Resolves the Risk Assessment OmniScript Type/SubType for an Account, driven by
*               PHOCSRiskAssessmentScoring__mdt records where AssessmentType__c = 'LaunchURL'.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
06 Aug -  PHOCS-269         -  Accenture   -  OmniScript launch button support
***********************************************************************************************/
public with sharing class PHOCSRiskAssessmentLaunchController {

    private static final String ASSESSMENT_TYPE_LAUNCH_URL = 'LaunchURL';
    private static final String LANGUAGE = 'English';

    public class OmniScriptConfiguration {
        @AuraEnabled public String type;
        @AuraEnabled public String subtype;
        @AuraEnabled public String language;
    }

/**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Returns the OmniScript Type/SubType configured for the Facility Type on the
* given Account, resolved via PHOCSRiskAssessmentScoring__mdt. Language is fixed to English.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @AuraEnabled(cacheable=true)
    public static OmniScriptConfiguration getOmniScriptConfiguration(Id accountId) {
        if (accountId == null) {
            throwError('Account Id is required.');
        }

        List<Account> accounts = [SELECT Id, Type FROM Account WHERE Id = :accountId LIMIT 1];
        if (accounts.isEmpty()) {
            throwError('Account not found.');
        }

        String facilityType = accounts[0].Type;
        if (String.isBlank(facilityType)) {
            throwError('Facility Type is required.');
        }

        List<PHOCSRiskAssessmentScoring__mdt> configurations = [
            SELECT OmniScriptType__c, OmniScriptSubType__c
            FROM PHOCSRiskAssessmentScoring__mdt
            WHERE ProgramArea__c = :facilityType
            AND AssessmentType__c = :ASSESSMENT_TYPE_LAUNCH_URL
            LIMIT 1
        ];
        if (configurations.isEmpty()) {
            throwError('No Risk Assessment Tool is configured for Facility Type: ' + facilityType);
        }

        PHOCSRiskAssessmentScoring__mdt configRecord = configurations[0];
        if (String.isBlank(configRecord.OmniScriptType__c)) {
            throwError('The LaunchURL metadata for Facility Type ' + facilityType + ' is missing a Type.');
        }

        OmniScriptConfiguration config = new OmniScriptConfiguration();
        config.type = configRecord.OmniScriptType__c;
        config.subtype = configRecord.OmniScriptSubType__c;
        config.language = LANGUAGE;
        return config;
    }

/**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Throws an AuraHandledException.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static void throwError(String message) {
        AuraHandledException ex = new AuraHandledException(message);
        ex.setMessage(message);
        throw ex;
    }
}