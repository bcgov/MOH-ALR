@isTest
public class WorkAreaPublicGroupQueueableTest {
    
    @IsTest
    public static void testCreatePublicGroup() {
        User usr = [SELECT Id FROM User WHERE Profile.Name='System Administrator' AND IsActive=true LIMIT 1];
        //PHOCSCustomMetadataDAO.setApplicationSettings();

        System.runAs(usr)
        {
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

            List<Work_Area__c> workAreaList = new List<Work_Area__c>();
            workAreaList.add(workArea);

            Test.startTest();
            WorkAreaPublicGroupQueueable workAreaPublicGroupQueueable = new WorkAreaPublicGroupQueueable(workAreaList,null);
            workAreaPublicGroupQueueable.createPublicGroup();
            Test.stopTest();
        }
    }

    @IsTest
    public static void testUpdatePublicGroup() {
        User usr = [SELECT Id FROM User WHERE Profile.Name='System Administrator' AND IsActive=true LIMIT 1];
        User officerUser = [SELECT Id FROM User WHERE Profile.Name= 'EHIS Standard User' AND IsActive=true LIMIT 1];

        System.runAs(usr)
        {
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

            Map<Id, Work_Area__c> oldWAMap = new Map<Id, Work_Area__c>();
            Work_Area__c UpdatedworkArea = new Work_Area__c();
            UpdatedworkArea.Id = workArea.Id;
            UpdatedworkArea.Name = 'Test Work Area Updated';
            workArea.Primary_Owner__c = officerUser.Id;
            workArea.Backup_Owner__c = officerUser.Id;
            workArea.Supervisor__c = officerUser.Id;
            workArea.Public_Group_Id__c = grp.Id;
            oldWAMap.put(workArea.Id, UpdatedworkArea);

            List<Work_Area__c> workAreaList = new List<Work_Area__c>();
            workAreaList.add(workArea);

            Test.startTest();
            WorkAreaPublicGroupQueueable workAreaPublicGroupQueueable = new WorkAreaPublicGroupQueueable(workAreaList, oldWAMap);
            workAreaPublicGroupQueueable.updatePublicGroup();
            Test.stopTest();
        }
    }
}