/**
 * @description : To manually share Portal user business entity's related account for Drinking Water Operating Permit as Sharing set only allowed to share logged in user contact's account.
 * @author PHOCS Team
 * @version 1.0
 * @date 2026-01-20
 * 
 */
global without sharing class PHOCSPortalRecordShare implements Callable {
    
    private static final String SHARE_ALL_DESCENDANT_ACCOUNTS = 'shareAllDescendantAccounts';
    
    global Object call(String action, Map<String,Object> args){
        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');
        
        if(action == SHARE_ALL_DESCENDANT_ACCOUNTS){
            return shareAllDescendantAccounts(input, output, options);
        }

        throw new CalloutException('Unknown action: ' + action);     
    }
    Private Object shareAllDescendantAccounts(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        Map<String, Object> result = new Map<String, Object>();
            system.debug('dddd'+options.get('accessLevel')+options.get('parentAccountId')+options.get('userOrGroupId'));
        	ID loggedInUserId;
		
        try {
            // ---- Validation ----
           /* if (options.get('parentAccountId') == null) {
                throw new AuraHandledException('Parent Account Id is required.');
            }*/
			
            if (options.get('userOrGroupId') == null) {
                throw new AuraHandledException('User or Group Id is required.');
            }else{
                loggedInUserId = (id) options.get('userOrGroupId') ;
            }

            if (options.get('accessLevel') != 'Read' && options.get('accessLevel') != 'Edit') {
                throw new AuraHandledException('AccessLevel must be Read or Edit.');
            }

            //Id rootParentId = (Id) options.get('parentAccountId');
            Id rootParentId ;
			if(options.get('userOrGroupId') != null){
                	user u = [select id,contact.accountid   from user where id =:loggedInUserId];
            		rootParentId = u.contact.accountid ;
        	}
            // Collect all descendant account ids
            Set<Id> allChildIds = new Set<Id>();
            collectChildAccounts(rootParentId, allChildIds);

            if (allChildIds.isEmpty()) {
                result.put('status', 'SUCCESS');
                result.put('message', 'No child accounts found.');
                result.put('sharedCount', 0);
                return result;
            }

            // Create shares
            List<AccountShare> shares = new List<AccountShare>();

            for (Id accId : allChildIds) {
                AccountShare share = new AccountShare();
                share.AccountId = accId;
                share.UserOrGroupId = (Id) options.get('userOrGroupId');
                share.AccountAccessLevel = (String) options.get('accessLevel');
                share.OpportunityAccessLevel = 'None';
                share.CaseAccessLevel = 'None';
                share.RowCause = Schema.AccountShare.RowCause.Manual;

                shares.add(share);
            }

            Database.SaveResult[] srList = Database.insert(shares, false);

            Integer successCount = 0;
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    successCount++;
                }
            }

            result.put('status', 'SUCCESS');
            result.put('message', 'All descendant accounts shared successfully.');
            result.put('sharedCount', successCount);

        } catch (Exception e) {
            result.put('status', 'ERROR');
            result.put('message', e.getMessage());
        }

        return result;
    }

    /**
     * Recursive helper to collect all descendant accounts
     */
    private static void collectChildAccounts(Id parentId, Set<Id> resultSet) {
        List<Account> children = [
            SELECT Id
            FROM Account
            WHERE ParentId = :parentId and recordtype.developername in ('Facility','DrinkingWaterSourceIntake')
        ];

        for (Account acc : children) {
            if (!resultSet.contains(acc.Id)) {
                resultSet.add(acc.Id);
                collectChildAccounts(acc.Id, resultSet);
            }
        }
    }
}