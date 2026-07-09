@isTest(SeeAllData=true)
public class PHOCSGroupMemberTriggerHandlerTest {
    @isTest
    static void assignsPermissionSetWhenUserIsAddedToGroup() {
        PermissionSet permissionSetRecord = getPermissionSet('PHOCSFHAChildResidentialCareInv');
        User testUser = createTestUser('assignsPermissionSet');
        Group publicGroup = getPublicGroup('PHOCSFHAChildResidentialCareInv');

        Test.startTest();
        GroupMember groupMember = new GroupMember(GroupId = publicGroup.Id, UserOrGroupId = testUser.Id);
        insert groupMember;
        PHOCSGroupMemberTriggerHandler.assignPermissionSets(new List<GroupMember>{ groupMember });
        Test.stopTest();

        System.assertEquals(1, [
            SELECT COUNT()
            FROM PermissionSetAssignment
            WHERE AssigneeId = :testUser.Id
            AND PermissionSetId = :permissionSetRecord.Id
        ]);
    }

    @isTest
    static void doesNotCreateDuplicateAssignmentWhenUserAlreadyHasPermissionSet() {
        PermissionSet permissionSetRecord = getPermissionSet('PHOCSFHAChildResidentialCareInv');
        User testUser = createTestUser('duplicateAssignment');
        Group publicGroup = getPublicGroup('PHOCSFHAChildResidentialCareInv');
        insert new PermissionSetAssignment(
            AssigneeId = testUser.Id,
            PermissionSetId = permissionSetRecord.Id
        );

        Test.startTest();
        GroupMember groupMember = new GroupMember(GroupId = publicGroup.Id, UserOrGroupId = testUser.Id);
        insert groupMember;
        PHOCSGroupMemberTriggerHandler.assignPermissionSets(new List<GroupMember>{ groupMember });
        Test.stopTest();

        System.assertEquals(1, [
            SELECT COUNT()
            FROM PermissionSetAssignment
            WHERE AssigneeId = :testUser.Id
            AND PermissionSetId = :permissionSetRecord.Id
        ]);
    }

    @isTest
    static void assignsPermissionSetsForMultipleMappedGroupsInBulk() {
        PermissionSet fhaPermissionSet = getPermissionSet('PHOCSFHAChildResidentialCareInv');
        PermissionSet nhaPermissionSet = getPermissionSet('PHOCSNHAChildResidentialCareInv');
        User fhaUser = createTestUser('bulkFhaUser');
        User nhaUser = createTestUser('bulkNhaUser');
        Group fhaGroup = getPublicGroup('PHOCSFHAChildResidentialCareInv');
        Group nhaGroup = getPublicGroup('PHOCSNHAChildResidentialCareInv');

        Test.startTest();
        List<GroupMember> groupMembers = new List<GroupMember>{
            new GroupMember(GroupId = fhaGroup.Id, UserOrGroupId = fhaUser.Id),
            new GroupMember(GroupId = nhaGroup.Id, UserOrGroupId = nhaUser.Id)
        };
        insert groupMembers;
        PHOCSGroupMemberTriggerHandler.assignPermissionSets(groupMembers);
        Test.stopTest();

        System.assertEquals(1, [
            SELECT COUNT()
            FROM PermissionSetAssignment
            WHERE AssigneeId = :fhaUser.Id
            AND PermissionSetId = :fhaPermissionSet.Id
        ]);
        System.assertEquals(1, [
            SELECT COUNT()
            FROM PermissionSetAssignment
            WHERE AssigneeId = :nhaUser.Id
            AND PermissionSetId = :nhaPermissionSet.Id
        ]);
    }

    @isTest
    static void removesPermissionSetWhenUserIsRemovedFromGroup() {
        PermissionSet permissionSetRecord = getPermissionSet('PHOCSNHAChildResidentialCareInv');
        User testUser = createTestUser('removesPermissionSet');
        Group publicGroup = getPublicGroup('PHOCSNHAChildResidentialCareInv');
        GroupMember groupMember = new GroupMember(GroupId = publicGroup.Id, UserOrGroupId = testUser.Id);
        insert groupMember;
        PHOCSGroupMemberTriggerHandler.assignPermissionSets(new List<GroupMember>{ groupMember });

        Test.startTest();
        delete groupMember;
        PHOCSGroupMemberTriggerHandler.removePermissionSets(new List<GroupMember>{ groupMember });
        Test.stopTest();

        System.assertEquals(0, [
            SELECT COUNT()
            FROM PermissionSetAssignment
            WHERE AssigneeId = :testUser.Id
            AND PermissionSetId = :permissionSetRecord.Id
        ]);
    }

    @isTest
    static void ignoresUnmappedGroups() {
        User testUser = createTestUser('ignoresUnmappedGroups');
        Group publicGroup = createPublicGroup('Unmapped Test Group');

        Test.startTest();
        GroupMember groupMember = new GroupMember(GroupId = publicGroup.Id, UserOrGroupId = testUser.Id);
        insert groupMember;
        PHOCSGroupMemberTriggerHandler.assignPermissionSets(new List<GroupMember>{ groupMember });
        Test.stopTest();

        System.assertEquals(0, [
            SELECT COUNT()
            FROM PermissionSetAssignment
            WHERE AssigneeId = :testUser.Id
            AND PermissionSetId IN :getHealthAuthorityPermissionSetIds()
        ]);
    }

    private static PermissionSet getPermissionSet(String permissionSetName) {
        return [
            SELECT Id
            FROM PermissionSet
            WHERE Name = :permissionSetName
            LIMIT 1
        ];
    }

    private static Set<Id> getHealthAuthorityPermissionSetIds() {
        Set<String> permissionSetNames = new Set<String>{
            'PHOCSFHAChildResidentialCareInv',
            'PHOCSIHAChildResidentialCareInv',
            'PHOCSNHAChildResidentialCareInv',
            'PHOCSVCHChildResidentialCareInv',
            'PHOCSVIHAChildResidentialCareInv'
        };
        return new Map<Id, PermissionSet>([
            SELECT Id
            FROM PermissionSet
            WHERE Name IN :permissionSetNames
        ]).keySet();
    }

    private static Group getPublicGroup(String groupName) {
        List<Group> publicGroups = [
            SELECT Id
            FROM Group
            WHERE Name = :groupName
            LIMIT 1
        ];
        if (!publicGroups.isEmpty()) {
            return publicGroups[0];
        }
        return createMappedPublicGroup(groupName);
    }

    private static Group createMappedPublicGroup(String groupName) {
        Group publicGroup = new Group(Name = groupName);
        insert publicGroup;
        return publicGroup;
    }

    private static Group createPublicGroup(String groupName) {
        Group publicGroup = new Group(Name = groupName + ' ' + System.currentTimeMillis());
        insert publicGroup;
        return publicGroup;
    }

    private static User createTestUser(String uniqueName) {
        Profile sysAdminProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator'
            LIMIT 1
        ];

        User testUser = new User(
            Alias = uniqueName.substring(0, 8),
            Email = uniqueName + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = uniqueName,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = sysAdminProfile.Id,
            TimeZoneSidKey = 'America/Vancouver',
            Username = uniqueName + '.' + System.currentTimeMillis() + '@example.com'
        );
        insert testUser;
        return testUser;
    }
}
