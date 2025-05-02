@isTest
public class WorkAreaUpdateQueueableTest {

    @TestSetup
    static void makeData(){

        User usr = [SELECT Id FROM User WHERE Profile.Name='System Administrator' AND IsActive=true LIMIT 1];

        Group grp = new Group();
        grp.Name = 'Test Group';
        insert grp;
        
        Work_Area__c workArea = new Work_Area__c();
        workArea.Name = 'Test Work Area';
        workArea.Primary_Owner__c = usr.Id;
        workArea.Backup_Owner__c = usr.Id;
        workArea.Supervisor__c = usr.Id;
        workArea.Public_Group_Id__c = grp.Id;
        insert workArea;
    }
    
    @IsTest
    public static void testQueueable(){   

        User usr = [SELECT Id FROM User WHERE Profile.Name='System Administrator' AND IsActive=true LIMIT 1];
        System.runAs(usr){
            List<Work_Area__c> workAreaList = [Select Id From Work_Area__c];

            Test.startTest();
            WorkAreaUpdateQueueable workAreaUpdateQueueable = new WorkAreaUpdateQueueable(workAreaList);
            workAreaUpdateQueueable.updateWorkArea();
            Test.stopTest();

            workAreaList = [Select Id From Work_Area__c];
            System.assertNotEquals(0, workAreaList.size());
        }
    }
}