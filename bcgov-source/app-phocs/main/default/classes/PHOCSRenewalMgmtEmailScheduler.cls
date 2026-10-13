public with sharing class PHOCSRenewalMgmtEmailScheduler implements Schedulable {
    private static final Set<String> EMAIL_STATUS_VALUES = new Set<String>{
        'Invoice Notification Queued',
        'Payment Reminder Queued',
        'Late Fee Notification Queued'
    };

    private static final String BILLING_CONTACT_ROLE = 'Billing Contact';
    private static final String OWNER_ROLE = 'Owner';
    private static final String OPERATOR_ROLE = 'Operator';
    private static final String SECONDARY_OPERATOR_ROLE = 'Secondary Operator';
    private static final String TERTIARY_OPERATOR_ROLE = 'Tertiary Operator';

    private static final String NEWINVOICE_TEMPLATE = 'PHOCS New Invoice Available';
    private static final String REMINDER_TEMPLATE = 'PHOCS Payment Reminder Email';
    private static final String RENEWALINVOICE_TEMPLATE = 'PHOCS Renewal New Invoice Available';
    private static final String NO_EMAIL_FOUND ='No Email Found';

    public static Map<String, EmailTemplate> testTemplates;
    // Find the verified PHOCS Org-Wide Email Address
    public static List<OrgWideEmailAddress> oweaList = [
        SELECT Id, Address, DisplayName
        FROM OrgWideEmailAddress
        WHERE Address = :'ehis.project@gov.bc.ca'
        LIMIT 1
    ];

    public void execute(SchedulableContext sc) {
        sendFeeEmails(getFeeContactEmails());
    }

    /**
     * Returns the first eligible recipient email for each fee modified today.
     */
    public static Map<RegulatoryTrxnFee, List<String>> getFeeContactEmails() {
    List<RegulatoryTrxnFee> fees = [
        SELECT Id, Name, AccountId, AccountName__c, DueDate, FeeType__c,
               GlobalPayPaymentLinkId__c, GlobalPayPaymentLink__c,
               GlobalPayPaymentStatus__c, HealthAuthority__c,
               InvoiceTemplateName__c, InvoiceTemplate__c,
               OutstandingFeeAmount__c, ParentRecordId, PaymentDate__c,
               EmailStatus__c, PHOCSCustomerID__c,
               PHOCSMonerisTicketNumber__c, ReceiptTemplateName__c,
               ReceiptTemplate__c, ReferenceNumber__c, RenewalYear__c,
               Status, Status__c, TotalFeeAmount, TotalFeePaid__c
        FROM RegulatoryTrxnFee
        WHERE EmailStatus__c IN :EMAIL_STATUS_VALUES
    ];

    Map<RegulatoryTrxnFee, List<String>> feeToEmails =
        new Map<RegulatoryTrxnFee, List<String>>();

    if (fees.isEmpty()) {
        return feeToEmails;
    }

    Set<Id> accountIds = new Set<Id>();

    for (RegulatoryTrxnFee fee : fees) {
        if (fee.ParentRecordId != null && fee.AccountId != null) {
            accountIds.add(fee.AccountId);
        }
    }

    Map<Id, Account> accountsById = new Map<Id, Account>([
        SELECT Id, ParentId
        FROM Account
        WHERE Id IN :accountIds
    ]);

    for (Account account : accountsById.values()) {
        if (account.ParentId != null) {
            accountIds.add(account.ParentId);
        }
    }

    Map<Id, List<AccountContactRelation>> contactsByAccount =
        getActiveContactsByAccount(accountIds);

    for (RegulatoryTrxnFee fee : fees) {
        Account account = accountsById.get(fee.AccountId);

        if (fee.ParentRecordId == null || account == null) {
            continue;
        }

        List<String> emails = findEmail(
            contactsByAccount.get(account.ParentId),
            contactsByAccount.get(account.Id)
        );

        if (emails.isEmpty()) {
            feeToEmails.put(fee, new List<String>{NO_EMAIL_FOUND});
        } else {
            feeToEmails.put(fee, emails);
        }
    }

    return feeToEmails;
}

    /**
     * Sends one templated email per fee and attaches its latest linked file version.
     */
    public static void sendFeeEmails(
    Map<RegulatoryTrxnFee, List<String>> feeToEmails
) {
    if (feeToEmails == null || feeToEmails.isEmpty()) {
        return;
    }

    Set<String> emailAddresses = new Set<String>();
    Set<Id> feeIds = new Set<Id>();
    Map<Id, List<String>> emailsByFeeId = new Map<Id, List<String>>();
    Map<Id, RegulatoryTrxnFee> feesById = new Map<Id, RegulatoryTrxnFee>();

    List<RegulatoryTrxnFee> feesToUpdate = new List<RegulatoryTrxnFee>();

    for (RegulatoryTrxnFee fee : feeToEmails.keySet()) {
        if (fee == null) {
            continue;
        }

        List<String> recipients = feeToEmails.get(fee);
        List<String> validRecipients = new List<String>();

        if (recipients != null) {
            for (String recipient : recipients) {
                if (String.isNotBlank(recipient) &&
                    recipient != NO_EMAIL_FOUND) {
                    validRecipients.add(recipient);
                    emailAddresses.add(recipient.toLowerCase());
                }
            }
        }

        if (validRecipients.isEmpty()) {
            if (recipients != null && recipients.contains(NO_EMAIL_FOUND)) {
                feesToUpdate.add(new RegulatoryTrxnFee(
                    Id = fee.Id,
                    EmailStatus__c = 'No Email Found'
                ));
            }
            continue;
        }

        feeIds.add(fee.Id);
        emailsByFeeId.put(fee.Id, validRecipients);
        feesById.put(fee.Id, fee);
    }

    if (!feesToUpdate.isEmpty()) {
        update feesToUpdate;
    }

    if (emailsByFeeId.isEmpty()) {
        return;
    }

    if (oweaList.isEmpty()) {
        System.debug(LoggingLevel.ERROR,
            'No verified Org-Wide Email Address found.');
        return;
    }

    Map<String, Id> contactIdsByEmail = new Map<String, Id>();

    for (Contact contact : [
        SELECT Id, Email
        FROM Contact
        WHERE Email IN :emailAddresses
    ]) {
        if (String.isNotBlank(contact.Email)) {
            String normalizedEmail = contact.Email.toLowerCase();

            if (!contactIdsByEmail.containsKey(normalizedEmail)) {
                contactIdsByEmail.put(normalizedEmail, contact.Id);
            }
        }
    }

    Map<String, EmailTemplate> templatesByName =
        new Map<String, EmailTemplate>();

    Set<String> templateNames = new Set<String>{
        NEWINVOICE_TEMPLATE,
        REMINDER_TEMPLATE,
        RENEWALINVOICE_TEMPLATE
    };

    for (EmailTemplate template : [
        SELECT Id, Name, Subject, HtmlValue, Body
        FROM EmailTemplate
        WHERE Name IN :templateNames
    ]) {
        templatesByName.put(template.Name, template);
    }

    if (testTemplates != null) {
        templatesByName.putAll(testTemplates);
    }

    Map<Id, Id> latestVersionByFeeId =
        getLatestFileVersionByFeeId(feeIds);

    List<Messaging.SingleEmailMessage> emails =
        new List<Messaging.SingleEmailMessage>();

    List<Id> emailFeeIds = new List<Id>();

    for (Id feeId : emailsByFeeId.keySet()) {
        RegulatoryTrxnFee fee = feesById.get(feeId);

        EmailTemplate template = templatesByName.get(
            getTemplateName(fee.EmailStatus__c, fee.FeeType__c)
        );

        if (template == null) {
            System.debug(LoggingLevel.ERROR,
                'No email template found for fee ' + feeId);
            continue;
        }

        for (String emailAddress : emailsByFeeId.get(feeId)) {
            Id contactId = contactIdsByEmail.get(
                emailAddress.toLowerCase()
            );

            if (contactId == null) {
                System.debug(LoggingLevel.ERROR,
                    'No Contact found for email ' + emailAddress);
                continue;
            }

            Messaging.SingleEmailMessage email =
                new Messaging.SingleEmailMessage();

            email.setTargetObjectId(contactId);
            email.setTreatTargetObjectAsRecipient(false);
            email.setToAddresses(new List<String>{emailAddress});
            email.setWhatId(fee.Id);
            email.setSubject(populateMergeFields(template.Subject, fee));
            email.setHtmlBody(populateMergeFields(template.HtmlValue, fee));
            email.setPlainTextBody(populateMergeFields(template.Body, fee));
            email.setOrgWideEmailAddressId(oweaList[0].Id);

            Id contentVersionId = latestVersionByFeeId.get(fee.Id);

            if (contentVersionId != null) {
                email.setEntityAttachments(
                    new List<Id>{contentVersionId}
                );
            }

            emails.add(email);
            emailFeeIds.add(fee.Id);
        }
    }

    Set<Id> successfullySentFeeIds = new Set<Id>();

    if (!emails.isEmpty()) {
        // Send in chunks to respect the Messaging.sendEmail limit.
        Integer batchSize = 100;
        for (Integer startIndex = 0;
             startIndex < emails.size();
             startIndex += batchSize) {

            List<Messaging.SingleEmailMessage> emailBatch =
                new List<Messaging.SingleEmailMessage>();

            List<Id> feeIdBatch = new List<Id>();

            for (Integer i = startIndex;
                 i < Math.min(startIndex + batchSize, emails.size());
                 i++) {
                emailBatch.add(emails[i]);
                feeIdBatch.add(emailFeeIds[i]);
            }

            List<Messaging.SendEmailResult> results =
                Messaging.sendEmail(emailBatch, false);

            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    successfullySentFeeIds.add(feeIdBatch[i]);
                } else {
                    for (Messaging.SendEmailError err :
                         results[i].getErrors()) {
                        System.debug(LoggingLevel.ERROR,
                            'Email failed for fee ' + feeIdBatch[i] +
                            ': ' + err.getMessage());
                    }
                }
            }
        }
    }

    for (Id feeId : successfullySentFeeIds) {
        feesToUpdate.add(new RegulatoryTrxnFee(
            Id = feeId,
            EmailStatus__c = 'Sent'
        ));
    }

    if (!feesToUpdate.isEmpty()) {
        update feesToUpdate;
    }
}
    
    private static String populateMergeFields(
        String templateContent,
        RegulatoryTrxnFee fee
    ) {
        if (String.isBlank(templateContent)) {
            return templateContent;
        }

        Pattern tokenPattern = Pattern.compile(
            '\\{\\{\\{RegulatoryTrxnFee\\.([A-Za-z0-9_]+)\\}\\}\\}'
        );
        Matcher tokenMatcher = tokenPattern.matcher(templateContent);
        Map<String, Schema.SObjectField> feeFields =
            Schema.SObjectType.RegulatoryTrxnFee.fields.getMap();
        String populatedContent = '';
        Integer previousEnd = 0;

        while (tokenMatcher.find()) {
            populatedContent += templateContent.substring(
                previousEnd,
                tokenMatcher.start()
            );

            String fieldName = tokenMatcher.group(1);
            Object fieldValue = null;
            if (feeFields.containsKey(fieldName)) {
                fieldValue = fee.get(fieldName);
            }
            populatedContent += fieldValue == null ? '' : String.valueOf(fieldValue);
            previousEnd = tokenMatcher.end();
        }

        return populatedContent + templateContent.substring(previousEnd);
    }

    private static String getTemplateName(String paymentReminder, String feetype) {
        if (paymentReminder == 'Invoice Notification Queued' ||paymentReminder == 'Late Fee Notification Queued'){
            if(feetype=='Renewal') return RENEWALINVOICE_TEMPLATE;            
            else return NEWINVOICE_TEMPLATE;
        }
        if (paymentReminder == 'Payment Reminder Queued') {
            return REMINDER_TEMPLATE;
        }        
        return null;
    }

    private static Map<Id, Id> getLatestFileVersionByFeeId(Set<Id> feeIds) {
        Map<Id, Set<Id>> documentIdsByFeeId = new Map<Id, Set<Id>>();
        for (ContentDocumentLink link : [
            SELECT LinkedEntityId, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :feeIds
        ]) {
            if (!documentIdsByFeeId.containsKey(link.LinkedEntityId)) {
                documentIdsByFeeId.put(link.LinkedEntityId, new Set<Id>());
            }
            documentIdsByFeeId.get(link.LinkedEntityId).add(link.ContentDocumentId);
        }

        Set<Id> documentIds = new Set<Id>();
        for (Set<Id> feeDocumentIds : documentIdsByFeeId.values()) {
            documentIds.addAll(feeDocumentIds);
        }

        Map<Id, Id> latestVersionByDocumentId = new Map<Id, Id>();
        Map<Id, Datetime> latestVersionDateByDocumentId = new Map<Id, Datetime>();
        for (ContentVersion version : [
            SELECT Id, ContentDocumentId, CreatedDate
            FROM ContentVersion
            WHERE ContentDocumentId IN :documentIds
            ORDER BY CreatedDate DESC
        ]) {
            if (!latestVersionByDocumentId.containsKey(version.ContentDocumentId)) {
                latestVersionByDocumentId.put(version.ContentDocumentId, version.Id);
                latestVersionDateByDocumentId.put(version.ContentDocumentId, version.CreatedDate);
            }
        }

        Map<Id, Id> latestVersionByFeeId = new Map<Id, Id>();
        Map<Id, Datetime> latestVersionDateByFeeId = new Map<Id, Datetime>();
        for (Id feeId : documentIdsByFeeId.keySet()) {
            for (Id documentId : documentIdsByFeeId.get(feeId)) {
                if (latestVersionByDocumentId.containsKey(documentId) &&
                    (!latestVersionDateByFeeId.containsKey(feeId) ||
                     latestVersionDateByDocumentId.get(documentId) > latestVersionDateByFeeId.get(feeId))) {
                    latestVersionByFeeId.put(feeId, latestVersionByDocumentId.get(documentId));
                    latestVersionDateByFeeId.put(feeId, latestVersionDateByDocumentId.get(documentId));
                }
            }
        }
        return latestVersionByFeeId;
    }

    private static Map<Id, List<AccountContactRelation>> getActiveContactsByAccount(
        Set<Id> accountIds
    ) {
        Map<Id, List<AccountContactRelation>> contactsByAccount =
            new Map<Id, List<AccountContactRelation>>();

        if (accountIds.isEmpty()) {
            return contactsByAccount;
        }

        for (AccountContactRelation relation : [
            SELECT AccountId, ContactId, Contact.Email, Roles
            FROM AccountContactRelation
            WHERE AccountId IN :accountIds
            AND IsActive = true
            AND Contact.Email != null
            AND Roles != null
            ORDER BY AccountId, ContactId
        ]) {
            if (!contactsByAccount.containsKey(relation.AccountId)) {
                contactsByAccount.put(relation.AccountId, new List<AccountContactRelation>());
            }
            contactsByAccount.get(relation.AccountId).add(relation);
        }

        return contactsByAccount;
    }

    private static List<String> findEmail(
    List<AccountContactRelation> parentContacts,
    List<AccountContactRelation> accountContacts
) {
    List<String> emails = new List<String>();
    Set<String> uniqueEmails = new Set<String>();

    List<List<AccountContactRelation>> roleTiers =
        new List<List<AccountContactRelation>>{
            getContactsWithRole(parentContacts, BILLING_CONTACT_ROLE, false),
            getContactsWithRole(accountContacts, BILLING_CONTACT_ROLE, false),
            getContactsWithRole(parentContacts, OWNER_ROLE, false),
            getContactsWithRole(accountContacts, OWNER_ROLE, false),
            getContactsWithRole(parentContacts, OPERATOR_ROLE, true),
            getContactsWithRole(accountContacts, OPERATOR_ROLE, true)
        };

    for (List<AccountContactRelation> tier : roleTiers) {
        for (AccountContactRelation relation : tier) {
            String email = relation.Contact.Email;

            if (String.isNotBlank(email) &&
                !uniqueEmails.contains(email.trim().toLowerCase())) {
                uniqueEmails.add(email.trim().toLowerCase());
                emails.add(email.trim());
            }
        }
    }

    return emails;
}

    private static List<AccountContactRelation> getContactsWithRole(
        List<AccountContactRelation> contacts,
        String role,
        Boolean excludeSecondaryAndTertiaryOperators
    ) {
        List<AccountContactRelation> matchingContacts = new List<AccountContactRelation>();
        if (contacts == null) {
            return matchingContacts;
        }

        for (AccountContactRelation relation : contacts) {
            Set<String> roles = new Set<String>();
            for (String relationRole : relation.Roles.split(';')) {
                roles.add(relationRole.trim());
            }

            if (!roles.contains(role)) {
                continue;
            }
            if (
                excludeSecondaryAndTertiaryOperators &&
                (roles.contains(SECONDARY_OPERATOR_ROLE) ||
                 roles.contains(TERTIARY_OPERATOR_ROLE))
            ) {
                continue;
            }
            matchingContacts.add(relation);
        }

        return matchingContacts;
    }

}