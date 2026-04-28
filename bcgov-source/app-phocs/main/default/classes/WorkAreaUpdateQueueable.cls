public class WorkAreaUpdateQueueable implements Queueable {

    private List<Work_Area__c> workAreaList;

    public WorkAreaUpdateQueueable(List<Work_Area__c> workAreas) {
        workAreaList = workAreas;
    }

    public void execute(QueueableContext context) {
        updateWorkArea();        
    }

    public void updateWorkArea(){
        update workAreaList;
    }
}