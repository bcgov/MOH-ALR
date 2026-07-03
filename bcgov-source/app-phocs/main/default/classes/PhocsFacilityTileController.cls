public with sharing class PhocsFacilityTileController {
    @AuraEnabled(cacheable=true)
    public static List<Account> getfacilities(){   
        
        User portalUser = [
            SELECT AccountId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        
        if (portalUser.AccountId == null) {
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
            WHERE ParentId = :portalUser.AccountId
            AND Status__c IN ('Open', 'Pending')
            ORDER BY Status__c ASC, Name ASC
        ];
        
    }
    
}