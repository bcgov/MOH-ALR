public without sharing class PHOCSGroupMemberTriggerHandler {
    private static final Map<String, String> GROUP_TO_PERMISSION_SET = new Map<String, String>{
        'PHOCSFHAChildResidentialCareInv' => 'PHOCSFHAChildResidentialCareInv',
        'PHOCSIHAChildResidentialCareInv' => 'PHOCSIHAChildResidentialCareInv',
        'PHOCSNHAChildResidentialCareInv' => 'PHOCSNHAChildResidentialCareInv',
        'PHOCSVCHChildResidentialCareInv' => 'PHOCSVCHChildResidentialCareInv',
        'PHOCSVIHAChildResidentialCareInv' => 'PHOCSVIHAChildResidentialCareInv'
    };
    public static Map<String, Id> permissionSetNameToId { get; private set; }
    public static Map<Id, Id> groupIdToPermissionSetId { get; private set; }

    public static void assignPermissionSets(List<GroupMember> newMembers) {
        syncPermissionSets(newMembers, true);
    }

    public static void removePermissionSets(List<GroupMember> oldMembers) {
        syncPermissionSets(oldMembers, false);
    }

    private static void syncPermissionSets(List<GroupMember> members, Boolean shouldAssign) {
        permissionSetNameToId = getPermissionSetNameToId();
        Map<Id, Set<Id>> groupIdToUserIds = getGroupIdToUserIds(members);
        groupIdToPermissionSetId = getGroupIdToPermissionSetId(
            groupIdToUserIds.keySet(),
            permissionSetNameToId
        );

        if (groupIdToUserIds.isEmpty() || permissionSetNameToId.isEmpty() || groupIdToPermissionSetId.isEmpty()) {
            return;
        }

        if (shouldAssign) {
            insertMissingAssignments(groupIdToUserIds);
        } else {
            deleteAssignments(groupIdToUserIds);
        }
    }

    private static Map<Id, Set<Id>> getGroupIdToUserIds(List<GroupMember> members) {
        Map<Id, Set<Id>> groupIdToUserIds = new Map<Id, Set<Id>>();

        for (GroupMember member : members) {
            if (member.GroupId == null || member.UserOrGroupId == null || !isUserId(member.UserOrGroupId)) {
                continue;
            }

            if (!groupIdToUserIds.containsKey(member.GroupId)) {
                groupIdToUserIds.put(member.GroupId, new Set<Id>());
            }
            groupIdToUserIds.get(member.GroupId).add(member.UserOrGroupId);
        }

        return groupIdToUserIds;
    }

    private static Boolean isUserId(Id userOrGroupId) {
        return String.valueOf(userOrGroupId).startsWith('005');
    }

    private static Map<String, Id> getPermissionSetNameToId() {
        Map<String, Id> permissionSetNameToId = new Map<String, Id>();

        for (PermissionSet permissionSetRecord : [
            SELECT Id, Name
            FROM PermissionSet
            WHERE Name IN :GROUP_TO_PERMISSION_SET.values()
        ]) {
            permissionSetNameToId.put(permissionSetRecord.Name, permissionSetRecord.Id);
        }

        return permissionSetNameToId;
    }

    private static Map<Id, Id> getGroupIdToPermissionSetId(Set<Id> groupIds, Map<String, Id> permissionSetNameToId) {
        Map<Id, Id> groupIdToPermissionSetId = new Map<Id, Id>();

        for (Group publicGroup : [
            SELECT Id, Name
            FROM Group
            WHERE Id IN :groupIds
            AND Name IN :GROUP_TO_PERMISSION_SET.keySet()
        ]) {
            Id permissionSetId = permissionSetNameToId.get(GROUP_TO_PERMISSION_SET.get(publicGroup.Name));
            if (permissionSetId != null) {
                groupIdToPermissionSetId.put(publicGroup.Id, permissionSetId);
            }
        }

        return groupIdToPermissionSetId;
    }

    private static void insertMissingAssignments(Map<Id, Set<Id>> groupIdToUserIds) {
        Set<Id> userIds = new Set<Id>();
        for (Set<Id> groupUserIds : groupIdToUserIds.values()) {
            userIds.addAll(groupUserIds);
        }

        Map<Id, Set<Id>> existingAssignmentsMap = new Map<Id, Set<Id>>();
        for (PermissionSetAssignment assignment : [
            SELECT AssigneeId, PermissionSetId
            FROM PermissionSetAssignment
            WHERE PermissionSetId IN :groupIdToPermissionSetId.values()
            AND AssigneeId IN :userIds
        ]) {
            if (!existingAssignmentsMap.containsKey(assignment.PermissionSetId)) {
                existingAssignmentsMap.put(assignment.PermissionSetId, new Set<Id>());
            }
            existingAssignmentsMap.get(assignment.PermissionSetId).add(assignment.AssigneeId);
        }

        List<PermissionSetAssignment> assignmentsToInsert = new List<PermissionSetAssignment>();
        for (Id groupId : groupIdToUserIds.keySet()) {
            Id permissionSetId = groupIdToPermissionSetId.get(groupId);
            if (permissionSetId == null) {
                continue;
            }
            if (!existingAssignmentsMap.containsKey(permissionSetId)) {
                existingAssignmentsMap.put(permissionSetId, new Set<Id>());
            }

            for (Id userId : groupIdToUserIds.get(groupId)) {
                if (!existingAssignmentsMap.get(permissionSetId).contains(userId)) {
                    assignmentsToInsert.add(new PermissionSetAssignment(
                        AssigneeId = userId,
                        PermissionSetId = permissionSetId
                    ));
                    existingAssignmentsMap.get(permissionSetId).add(userId);
                }
            }
        }

        if (!assignmentsToInsert.isEmpty()) {
            insert assignmentsToInsert;
        }
    }

    private static void deleteAssignments(Map<Id, Set<Id>> groupIdToUserIds) {
        Set<Id> userIds = new Set<Id>();
        Set<Id> permissionSetIds = new Set<Id>();
        for (Id groupId : groupIdToPermissionSetId.keySet()) {
            if (!groupIdToUserIds.containsKey(groupId)) {
                continue;
            }
            userIds.addAll(groupIdToUserIds.get(groupId));
            permissionSetIds.add(groupIdToPermissionSetId.get(groupId));
        }

        List<PermissionSetAssignment> assignmentsToDelete = [
            SELECT Id
            FROM PermissionSetAssignment
            WHERE AssigneeId IN :userIds
            AND PermissionSetId IN :permissionSetIds
        ];

        if (!assignmentsToDelete.isEmpty()) {
            delete assignmentsToDelete;
        }
    }

}
