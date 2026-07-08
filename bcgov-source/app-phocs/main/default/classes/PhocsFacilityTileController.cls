public with sharing class PhocsFacilityTileController {
    @AuraEnabled(cacheable=true)
    public static List<Account> getfacilities(){   
        User currentUser = [
            SELECT ContactId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        
        if (currentUser.ContactId == null) {
            return new List<Account>();
        }
        
        Contact portalContact = [
            SELECT AccountId
            FROM Contact
            WHERE Id = :currentUser.ContactId
            LIMIT 1
        ];
        
        if (portalContact.AccountId == null) {
            return new List<Account>();
        }
        
        return [
            SELECT Id,
            Name,Status__c,
            Physical_Address__Street__s,
            Physical_Address__City__s,
            Physical_Address__StateCode__s,
            Physical_Address__PostalCode__s,
            Physical_Address__CountryCode__s
            FROM Account
            WHERE ParentId = :portalContact.AccountId
            AND Status__c IN ('Open', 'Pending')
            ORDER BY Status__c ASC, Name ASC
        ];
        
    }
    
    
}