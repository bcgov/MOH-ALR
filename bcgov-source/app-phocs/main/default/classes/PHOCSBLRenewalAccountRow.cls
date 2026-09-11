public class PHOCSBLRenewalAccountRow {
        @AuraEnabled public Id Id;
        @AuraEnabled public String accountName;
        @AuraEnabled public String accountUrl;        
        @AuraEnabled public Id parentAccountId;
        @AuraEnabled public String parentAccountUrl;
        @AuraEnabled public String parentAccountName;        
        @AuraEnabled public String postalCode;
        @AuraEnabled public String categoryL1;
        @AuraEnabled public String categoryL2;
        @AuraEnabled public String operatingMonths;
        @AuraEnabled public Boolean multiplePremise;
        @AuraEnabled public String premiseRole;
    }