public class PHOCSLateFeeManagementRow {
    @AuraEnabled public Id Id;
    @AuraEnabled public String parentAccountName;
    @AuraEnabled public String parentAccountUrl;
    @AuraEnabled public String accountName;
    @AuraEnabled public String accountUrl;
    @AuraEnabled public String postalCode;
    @AuraEnabled public String blaId;
    @AuraEnabled public String blaUrl;
    @AuraEnabled public String feeId;
    @AuraEnabled public String feeUrl;
    @AuraEnabled public String feeName;
    @AuraEnabled public Decimal feeAmount;
    @AuraEnabled public Date dueDate;
    @AuraEnabled public String operatingMonths;
    @AuraEnabled public Boolean multiplePremise;
    @AuraEnabled public String premiseRole;
}