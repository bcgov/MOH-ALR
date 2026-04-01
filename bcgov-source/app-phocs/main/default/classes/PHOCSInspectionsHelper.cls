public class PHOCSInspectionsHelper {
    @AuraEnabled
    public static Visit getInspection(String visitId){
        try{
            List<Visit> inspections = [SELECT Id, Name, RecordTypeId, Status, AccountId, InstructionDescription FROM Visit where Id =: visitId];
            if(!inspections.isEmpty() || inspections.size() > 0){
                return inspections[0];
            }
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
        return null;
    }
}