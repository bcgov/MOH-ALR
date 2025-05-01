public class WorkAreaPublicGroupQueueable implements Queueable {

    private List<Work_Area__c> workAreaList;
    private Map<Id, Work_Area__c> oldWorkAreasMap;

    public WorkAreaPublicGroupQueueable(List<Work_Area__c> workAreas) {
        workAreaList = workAreas;
    }

    public WorkAreaPublicGroupQueueable(List<Work_Area__c> workAreas, Map<Id, Work_Area__c> oldWAMap) {
        workAreaList = workAreas;
        oldWorkAreasMap = oldWAMap;
    }

    public void execute(QueueableContext context) {
        if(oldWorkAreasMap == null){
            createPublicGroup();  
        }else{
            updatePublicGroup();
        }      
    }

    public void createPublicGroup(){
        List<Group> newPublicGroupList = new List<Group>();
        List<GroupMember> newGroupMembers = new List<GroupMember>();
        Map<String,Work_Area__c> groupWorkMap = new Map<String,Work_Area__c>();

        set<string> workAreaPGNames = new set<string>();
        set<string> existingworkAreaNames = new set<string>();

        for (Work_Area__c workArea : workAreaList){
            String publicGroupName = 'WA-' + workArea.Name;
            workAreaPGNames.add(publicGroupName);
        }
        for(Group matchingGroup : [SELECT Id, Name FROM Group WHERE Name IN :workAreaPGNames]){
            existingworkAreaNames.add(matchingGroup.Name);
        }

        for (Work_Area__c workArea : workAreaList){           
            String publicGroupName = 'WA-' + workArea.Name;
            if(!existingworkAreaNames.contains(publicGroupName)){
                Group publicGroup = new Group();
                publicGroup.Name = publicGroupName;
                newPublicGroupList.add(publicGroup);
                groupWorkMap.put(publicGroupName, workArea);
            }
        }
        if (!newPublicGroupList.isEmpty()) {
            insert newPublicGroupList;
        }

        for(Group grp : newPublicGroupList){
            Work_Area__c workArea = groupWorkMap.get(grp.Name);   
            if (workArea.Primary_Owner__c != null) {
                newGroupMembers.add(new GroupMember(GroupID = grp.Id, UserOrGroupId = workArea.Primary_Owner__c));
            }
            if (workArea.Backup_Owner__c != null) {
                newGroupMembers.add(new GroupMember(GroupID = grp.Id, UserOrGroupId = workArea.Backup_Owner__c));
            }
            if (workArea.Supervisor__c != null){
                newGroupMembers.add(new GroupMember(GroupID =grp.Id, UserOrGroupId = workArea.Supervisor__c));
            }
        }
        if (!newGroupMembers.isEmpty()) {
            insert newGroupMembers;
        }

        List<Work_Area__c> updateWorkAreas = new List<Work_Area__c>();
        for(Group grp : newPublicGroupList){
            Work_Area__c wkarea = groupWorkMap.get(grp.Name);
            Work_Area__c updateWorkArea = new Work_Area__c();
            updateWorkArea.Id= wkarea.Id;
            updateWorkArea.Public_Group_Id__c =grp.Id;
            updateWorkAreas.add(updateWorkArea);
        }
        if (!updateWorkAreas.isEmpty()) {
           //to avoid MIXED_DML_OPERATION, DML operation on setup object is not permitted after you have updated a non-setup object 
           System.enqueueJob(new WorkAreaUpdateQueueable(updateWorkAreas));
        }
    }

    public void updatePublicGroup(){

        List<Group> updateGroups = new List<Group>();
        List<GroupMember> insertMembers = new List<GroupMember>();
        List<GroupMember> removeMembers = new List<GroupMember>();

        set<Id> publicGroupIds = new set<Id>();
        Map<string, GroupMember> userIdGroupMemberMap = new Map<string, GroupMember>();

        for (Work_Area__c workArea : workAreaList){ 
            publicGroupIds.add(workArea.Public_Group_Id__c);
        }
        
        for(GroupMember groupMmember : [SELECT UserOrGroupId, GroupId, Id 
                                        FROM GroupMember 
                                        WHERE GroupId IN :publicGroupIds]){
            userIdGroupMemberMap.put(groupMmember.UserOrGroupId + '-' + groupMmember.GroupId, groupMmember);                        
        }
        
        for (Work_Area__c workArea : workAreaList){ 
            if(workArea.Public_Group_Id__c != null){
                Work_Area__c oldWorkArea = oldWorkAreasMap.get(workArea.Id);
                if(workArea.Name != oldWorkArea.Name){
                    Group publicGroup = new Group(Id= workArea.Public_Group_Id__c);
                    publicGroup.Name = 'WA-' + workArea.Name;
                    //publicGroup.DeveloperName =  'WA-' + workArea.Name;
                    updateGroups.add(publicGroup);
                }
                if (oldWorkArea.Primary_Owner__c != workArea.Primary_Owner__c) {
                    GroupMember oldGroupMember = userIdGroupMemberMap.get(oldWorkArea.Primary_Owner__c + '-' + workArea.Public_Group_Id__c); 
                    
                    //check if the user is a backup owner or supervisor. if he owns, no need to remove from the sharing group
                    if(oldGroupMember != null && 
                            workArea.Backup_Owner__c != oldWorkArea.Primary_Owner__c && workArea.Supervisor__c != oldWorkArea.Primary_Owner__c){
                        removeMembers.add(oldGroupMember);
                    }

                    GroupMember newGroupMember = new GroupMember(GroupID = workArea.Public_Group_Id__c, UserOrGroupId = workArea.Primary_Owner__c);
                    insertMembers.add(newGroupMember);
                }
                if (oldWorkArea.Backup_Owner__c  != workArea.Backup_Owner__c ) {
                    GroupMember oldGroupMember = userIdGroupMemberMap.get(oldWorkArea.Backup_Owner__c + '-' + workArea.Public_Group_Id__c); 
                    
                    //check if the user is a primary or supervisor. if he owns, no need to remove from the sharing group
                    if(oldGroupMember != null && 
                            workArea.Primary_Owner__c != oldWorkArea.Backup_Owner__c && workArea.Supervisor__c != oldWorkArea.Backup_Owner__c){
                        removeMembers.add(oldGroupMember);
                    }

                    GroupMember newGroupMember = new GroupMember(GroupID = workArea.Public_Group_Id__c, UserOrGroupId = workArea.Backup_Owner__c);
                    insertMembers.add(newGroupMember);
                }
                if (oldWorkArea.Supervisor__c  != workArea.Supervisor__c ) {
                    GroupMember oldGroupMember = userIdGroupMemberMap.get(oldWorkArea.Supervisor__c + '-' + workArea.Public_Group_Id__c); 
                    
                    //check if the user is a primary or backup owner. if he owns, no need to remove from the sharing group
                    if(oldGroupMember != null && 
                             workArea.Primary_Owner__c != oldWorkArea.Supervisor__c && workArea.Backup_Owner__c != oldWorkArea.Supervisor__c){
                        removeMembers.add(oldGroupMember);
                    }

                    GroupMember newGroupMember = new GroupMember(GroupID = workArea.Public_Group_Id__c, UserOrGroupId = workArea.Supervisor__c);
                    insertMembers.add(newGroupMember);
                }
            }
        }
       
        if (!updateGroups.isEmpty()) {
            Database.update(updateGroups,false);
        }
        if (!removeMembers.isEmpty()) {
            Database.Delete(removeMembers, false);
        }
        if (!insertMembers.isEmpty()) {
            Database.Insert(insertMembers, false);
        }
    }

    public static void shareAccountWithUser(Id accountId, Id groupId) {
        AccountShare share = new AccountShare();
        share.AccountId = accountId;
        share.UserOrGroupId = groupId;
        share.AccountAccessLevel = 'Edit';
        share.RowCause = AccountShare.RowCause.Manual;
        insert share;
    }
}