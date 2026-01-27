public class PHOCSInspectionsHelper {
    @AuraEnabled
    public static Visit getInspection(String visitId){
        return [SELECT Id, Name, RecordTypeId, Status, AccountId FROM Visit where Id =: visitId];
    }
}