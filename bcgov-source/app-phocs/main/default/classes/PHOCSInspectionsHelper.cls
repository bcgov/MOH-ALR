public class PHOCSInspectionsHelper {
    @AuraEnabled
    public static Visit getInspection(String visitId){
        return [SELECT Id, Name, RecordTypeId, Status FROM Visit where Id =: visitId];
    }
}