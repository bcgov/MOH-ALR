trigger ContentDocumentLinkTrigger on ContentDocumentLink (after insert, after delete) {
    if (Trigger.isAfter && Trigger.isInsert) {
        ContentDocumentLinkTriggerHandler.updateDocumentChecklistItemAfterUploadFile(Trigger.New);
    }

}