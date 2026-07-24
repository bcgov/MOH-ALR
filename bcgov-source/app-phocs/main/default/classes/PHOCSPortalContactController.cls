public with sharing class PHOCSPortalContactController {
    @AuraEnabled(cacheable=true)
    public static Id getPortalContactDetails() {
        
        User portalUser = [
            SELECT ContactId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        
        return portalUser.ContactId;
    }
}