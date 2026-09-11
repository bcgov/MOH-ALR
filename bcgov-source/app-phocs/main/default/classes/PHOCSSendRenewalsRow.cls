public class PHOCSSendRenewalsRow {
        @AuraEnabled public Id Id;        
        @AuraEnabled public String parentAccountName;
        @AuraEnabled public String parentAccountUrl;        
        @AuraEnabled public String accountName;
        @AuraEnabled public String accountUrl;
        @AuraEnabled public String postalCode;        
        @AuraEnabled public String blaId;
        @AuraEnabled public String blaName;        
        @AuraEnabled public String blaUrl;
        @AuraEnabled public String feeId;
        @AuraEnabled public String feeUrl;
        @AuraEnabled public String feeName;
        @AuraEnabled public Decimal feeAmount;
        @AuraEnabled public Boolean multiplePremise;
        @AuraEnabled public String premiseRole;
    }