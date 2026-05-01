public class PHOCSExpireOWLRetentionScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new PHOCSExpireOWLRetentionBatch(), 200);
    }
}