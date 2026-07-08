public with sharing class PhocsFacilityTileController {
    @AuraEnabled(cacheable=true)
    public static List<Account> getfacilities(){   
        
        
        return [
            SELECT Id,
                   Name,Status__c,
                   Physical_Address__Street__s,
                	Physical_Address__City__s,
                	Physical_Address__StateCode__s,
                	Physical_Address__PostalCode__s,
                	Physical_Address__CountryCode__s
            FROM Account
            WHERE CreatedById = :UserInfo.getUserId()
            AND Status__c IN ('Open', 'Pending')
            ORDER BY Status__c ASC, Name ASC
        ];
        
    }
    
}