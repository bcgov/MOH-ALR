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

    public void execute(SchedulableContext sc) {
        sendFeeEmails(getFeeContactEmails());
    }

    /**
     * Returns the first eligible recipient email for each fee modified today.
     */
    public static Map<RegulatoryTrxnFee, String> getFeeContactEmails() {
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

        Map<RegulatoryTrxnFee, String> feeToEmails = new Map<RegulatoryTrxnFee, String>();
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
            Id accountId = fee.AccountId;
            Id parentAccountId = account.ParentId;
            String email = findEmail(
                contactsByAccount.get(parentAccountId),
                contactsByAccount.get(accountId)
            );

            if (String.isNotBlank(email)) {
                feeToEmails.put(fee, email);
            }else{
                feeToEmails.put(fee, NO_EMAIL_FOUND);
            }
        }        
        return feeToEmails;
    }

    /**
     * Sends one templated email per fee and attaches its latest linked file version.
     */
    public static void sendFeeEmails(Map<RegulatoryTrxnFee, String> feeToEmails) {
        if (feeToEmails == null || feeToEmails.isEmpty()) {
            return;
        }

        Set<String> emailAddresses = new Set<String>();
        Set<Id> feeIds = new Set<Id>();
        List<RegulatoryTrxnFee> feesToUpdate = new List<RegulatoryTrxnFee>();
        for (RegulatoryTrxnFee fee : feeToEmails.keySet()) {
            String emailAddress = feeToEmails.get(fee);
            if (fee != null && String.isNotBlank(emailAddress) && emailAddress != NO_EMAIL_FOUND) {
                emailAddresses.add(emailAddress.toLowerCase());
                feeIds.add(fee.Id);
            } else if (emailAddress == NO_EMAIL_FOUND) {
                feesToUpdate.add(new RegulatoryTrxnFee(
                    Id = fee.Id,
                        EmailStatus__c = 'No Email Found'
                    ));
            }
        }

        if (emailAddresses.isEmpty()) {
            if (!feesToUpdate.isEmpty()) {
                update feesToUpdate;
            }
            return;
        }

        Map<String, Id> contactIdsByEmail = new Map<String, Id>();
        for (Contact contact : [
            SELECT Id, Email
            FROM Contact
            WHERE Email IN :emailAddresses
        ]) {
            contactIdsByEmail.put(contact.Email.toLowerCase(), contact.Id);
        }

        Map<String, EmailTemplate> templatesByName = new Map<String, EmailTemplate>();
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

        Map<Id, Id> latestVersionByFeeId = getLatestFileVersionByFeeId(feeIds);
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        List<RegulatoryTrxnFee> orderedFees = new List<RegulatoryTrxnFee>();

        for (RegulatoryTrxnFee fee : feeToEmails.keySet()) {
            String emailAddress = feeToEmails.get(fee);
            if (String.isBlank(emailAddress) || emailAddress == NO_EMAIL_FOUND) {
                continue;
            }
            Id contactId = contactIdsByEmail.get(emailAddress.toLowerCase());
            EmailTemplate template = templatesByName.get(getTemplateName(fee.EmailStatus__c));
            if (contactId == null || template == null) {
                continue;
            }

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setTargetObjectId(contactId);
            email.setTreatTargetObjectAsRecipient(false);
            email.setToAddresses(new List<String>{emailAddress});
            email.setWhatId(fee.Id);
            email.setSubject(populateMergeFields(template.Subject, fee));
            email.setHtmlBody(populateMergeFields(template.HtmlValue, fee));
            email.setPlainTextBody(populateMergeFields(template.Body, fee));

            Id contentVersionId = latestVersionByFeeId.get(fee.Id);
            if (contentVersionId != null) {
                email.setEntityAttachments(new List<Id>{contentVersionId});
            }
            emails.add(email);
            orderedFees.add(fee);
        }

        if (!emails.isEmpty()) {
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(emails, false);
            for (Integer index = 0; index < results.size(); index++) {
                if (results[index].isSuccess()) {
                    feesToUpdate.add(new RegulatoryTrxnFee(
                        Id = orderedFees[index].Id,
                        EmailStatus__c = 'Sent'
                    ));
                }
            }
        }
        if (!feesToUpdate.isEmpty()) {
            update feesToUpdate;
        }
    }
    
    @TestVisible
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

    private static String getTemplateName(String paymentReminder) {
        if (paymentReminder == 'Invoice Notification Queued') {
            return NEWINVOICE_TEMPLATE;
        }
        if (paymentReminder == 'Payment Reminder Queued') {
            return REMINDER_TEMPLATE;
        }
        if (paymentReminder == 'Late Fee Notification Queued') {
            return RENEWALINVOICE_TEMPLATE;
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

    private static String findEmail(
        List<AccountContactRelation> parentContacts,
        List<AccountContactRelation> accountContacts
    ) {
        List<List<AccountContactRelation>> roleTiers = new List<List<AccountContactRelation>>{
            getContactsWithRole(parentContacts, BILLING_CONTACT_ROLE, false),
            getContactsWithRole(accountContacts, BILLING_CONTACT_ROLE, false),
            getContactsWithRole(parentContacts, OWNER_ROLE, false),
            getContactsWithRole(accountContacts, OWNER_ROLE, false),
            getContactsWithRole(parentContacts, OPERATOR_ROLE, true),
            getContactsWithRole(accountContacts, OPERATOR_ROLE, true)
        };
        for (List<AccountContactRelation> tier : roleTiers) {
            if (!tier.isEmpty()) {
                return tier[0].Contact.Email;
            }
        }

        return null;
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