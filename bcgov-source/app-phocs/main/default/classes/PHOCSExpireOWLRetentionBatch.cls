public class PHOCSExpireOWLRetentionBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date fiveYearsAgo = Date.today().addYears(-5);
        return Database.getQueryLocator([
            SELECT Id
            FROM   Account
            WHERE  OWLPublicRetentionActive__c   = true
            AND    Status__c                     = 'Closed'
            AND    OperationEndDate__c           <= :fiveYearsAgo
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        
        for (Account acc : scope) {
          
            acc.OWLPublicRetentionActive__c = false;
        }
        Database.SaveResult[] results = Database.update(scope,false);
        
        for (Integer i=0; i<results.size(); i++){
            if (!results[i].isSuccess()){
                for (Database.Error err : results[i].getErrors()){
                    System.debug ('Record id: ' + scope[i].id);
                    System.debug ('Error: ' + err.getMessage());
                }
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
    
    }
}