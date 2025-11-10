trigger ContentDocumentLinkTrigger on ContentDocumentLink (before Insert, after insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        ContentDocumentLinkTriggerHandler.updatePhocsDocumentsVisibility(Trigger.New);
    }
    if (Trigger.isAfter && Trigger.isInsert) {
        ContentDocumentLinkTriggerHandler.updateDocumentChecklistItemAfterUploadFile(Trigger.New);
    }
}