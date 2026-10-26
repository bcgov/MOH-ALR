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
        
        Map<RegulatoryTrxnFee, List<String>> feeToEmails = new Map<RegulatoryTrxnFee, List<String>>();
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
                contactsByAccount.get(fee.AccountId)
            );
            
            if (!emails.isEmpty()) {
                feeToEmails.put(fee, emails);
            } else {
                feeToEmails.put(fee, new List<String>{ NO_EMAIL_FOUND });
            }
        }        
        return feeToEmails;
    }
    
    /**
* Sends one templated email per fee and attaches its latest linked file version.
*/
    public static void sendFeeEmails(Map<RegulatoryTrxnFee, List<String>> feeToEmails) {
        if (feeToEmails == null || feeToEmails.isEmpty()) {
            return;
        }
        
        Set<String> emailAddresses = new Set<String>();
        Set<Id> feeIds = new Set<Id>();
        List<RegulatoryTrxnFee> feesToUpdate = new List<RegulatoryTrxnFee>();
        
        for (RegulatoryTrxnFee fee : feeToEmails.keySet()) {
            if (fee == null) {
                continue;
            }
            
            List<String> recipientEmails = feeToEmails.get(fee);
            
            if (recipientEmails == null || recipientEmails.isEmpty()) {
                continue;
            }
            
            if (recipientEmails.size() == 1 &&
                recipientEmails[0] == NO_EMAIL_FOUND) {
                    feesToUpdate.add(new RegulatoryTrxnFee(
                        Id = fee.Id,
                        EmailStatus__c = 'No Email Found'
                    ));
                    continue;
                }
            
            for (String address : recipientEmails) {
                if (String.isNotBlank(address) &&
                    address != NO_EMAIL_FOUND) {
                        emailAddresses.add(address.trim().toLowerCase());
                        feeIds.add(fee.Id);
                    }
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
            if (String.isNotBlank(contact.Email)) {
                contactIdsByEmail.put(
                    contact.Email.trim().toLowerCase(),
                    contact.Id
                );
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
        List<RegulatoryTrxnFee> orderedFees =
            new List<RegulatoryTrxnFee>();
        
        for (RegulatoryTrxnFee fee : feeToEmails.keySet()) {
            if (fee == null) {
                continue;
            }
            
            List<String> recipientEmails = feeToEmails.get(fee);
            
            if (recipientEmails == null || recipientEmails.isEmpty() ||
                (recipientEmails.size() == 1 &&
                 recipientEmails[0] == NO_EMAIL_FOUND)) {
                     continue;
                 }
            
            List<String> validRecipients = new List<String>();
            Id targetContactId;
            
            for (String address : recipientEmails) {
                if (String.isBlank(address) || address == NO_EMAIL_FOUND) {
                    continue;
                }
                
                String normalizedAddress = address.trim().toLowerCase();
                Id contactId = contactIdsByEmail.get(normalizedAddress);
                
                if (contactId != null) {
                    validRecipients.add(address.trim());
                    
                    if (targetContactId == null) {
                        targetContactId = contactId;
                    }
                }
            }
            
            if (validRecipients.isEmpty() || targetContactId == null) {
                continue;
            }
            
            EmailTemplate template = templatesByName.get(
                getTemplateName(fee.EmailStatus__c, fee.FeeType__c)
            );
            
            if (template == null) {
                continue;
            }
            
            Messaging.SingleEmailMessage email =
                new Messaging.SingleEmailMessage();
            
            email.setTargetObjectId(targetContactId);
            email.setTreatTargetObjectAsRecipient(false);
            email.setToAddresses(validRecipients);
            email.setWhatId(fee.Id);
            email.setSubject(populateMergeFields(template.Subject, fee));
            email.setHtmlBody(populateMergeFields(template.HtmlValue, fee));
            email.setPlainTextBody(populateMergeFields(template.Body, fee));
            
            if (oweaList != null && !oweaList.isEmpty()) {
                email.setOrgWideEmailAddressId(oweaList[0].Id);
            }
            
            Id contentVersionId = latestVersionByFeeId.get(fee.Id);
            
            if (contentVersionId != null) {
                email.setEntityAttachments(new List<Id>{contentVersionId});
            }
            
            emails.add(email);
            orderedFees.add(fee);
        }
        
        if (!emails.isEmpty()) {
            List<Messaging.SendEmailResult> results =
                Messaging.sendEmail(emails, false);
            
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

        String formattedValue = '';

        if (fieldValue != null) {
            if (fieldName == 'TotalFeeAmount') {
                // Format Amount Due with a dollar symbol.
                formattedValue = '$' + String.valueOf(fieldValue);
            } else if (fieldName == 'DueDate' && fieldValue instanceof Datetime) {
                // Remove the time component from a Datetime field.
                formattedValue = ((Datetime) fieldValue).formatGmt('yyyy-MM-dd');
            } else {
                formattedValue = String.valueOf(fieldValue);
            }
        }

        populatedContent += formattedValue;
        previousEnd = tokenMatcher.end();
    }

    return populatedContent + templateContent.substring(previousEnd);
}
    
    private static String getTemplateName(String paymentReminder, String feetype) {
        if (paymentReminder == 'Invoice Notification Queued'){
            if(feetype=='Renewal') return RENEWALINVOICE_TEMPLATE;            
            else return NEWINVOICE_TEMPLATE;
        }
        if (paymentReminder == 'Payment Reminder Queued' ||paymentReminder == 'Late Fee Notification Queued') {
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
        // 1. Parent Account - Billing Contacts
        List<String> emails = collectEmailsByRole(
            parentContacts,
            BILLING_CONTACT_ROLE,
            false
        );
        if (!emails.isEmpty()) {
            return emails;
        }
        
        // 2. Child Account - Billing Contacts
        emails = collectEmailsByRole(
            accountContacts,
            BILLING_CONTACT_ROLE,
            false
        );
        if (!emails.isEmpty()) {
            return emails;
        }
        
        // 3. Parent Account - Owners
        emails = collectEmailsByRole(
            parentContacts,
            OWNER_ROLE,
            false
        );
        if (!emails.isEmpty()) {
            return emails;
        }
        
        // 4. Child Account - Owners
        emails = collectEmailsByRole(
            accountContacts,
            OWNER_ROLE,
            false
        );
        if (!emails.isEmpty()) {
            return emails;
        }
        
        // 5. Parent Account - Eligible Operators
        emails = collectEmailsByRole(
            parentContacts,
            OPERATOR_ROLE,
            true
        );
        if (!emails.isEmpty()) {
            return emails;
        }
        
        // 6. Child Account - Eligible Operators
        return collectEmailsByRole(
            accountContacts,
            OPERATOR_ROLE,
            true
        );
    }
    private static List<String> collectEmailsByRole(
        List<AccountContactRelation> contacts,
        String role,
        Boolean excludeSecondaryAndTertiaryOperators
    ) {
        Set<String> uniqueEmails = new Set<String>();
        
        if (contacts == null || contacts.isEmpty()) {
            return new List<String>();
        }
        
        for (AccountContactRelation relation : contacts) {
            if (relation.Contact == null ||
                String.isBlank(relation.Contact.Email) ||
                String.isBlank(relation.Roles)) {
                    continue;
                }
            
            Set<String> roles = new Set<String>();
            
            for (String relationRole : relation.Roles.split(';')) {
                roles.add(relationRole.trim());
            }
            
            if (!roles.contains(role)) {
                continue;
            }
            
            if (
                excludeSecondaryAndTertiaryOperators &&
                (
                    roles.contains(SECONDARY_OPERATOR_ROLE) ||
                    roles.contains(TERTIARY_OPERATOR_ROLE)
                )
            ) {
                continue;
            }
            
            uniqueEmails.add(relation.Contact.Email.trim());
        }
        
        List<String> result = new List<String>();
        result.addAll(uniqueEmails);
        result.sort();
        
        return result;
    }
    private static void addMatchingEmails(
        Set<String> emails,
        List<AccountContactRelation> contacts,
        String role,
        Boolean excludeSecondaryAndTertiaryOperators
    ) {
        if (contacts == null) {
            return;
        }
        
        for (AccountContactRelation relation : contacts) {
            if (relation.Contact == null ||
                String.isBlank(relation.Contact.Email) ||
                String.isBlank(relation.Roles)) {
                    continue;
                }
            
            Set<String> roles = new Set<String>();
            
            for (String relationRole : relation.Roles.split(';')) {
                roles.add(relationRole.trim());
            }
            
            if (!roles.contains(role)) {
                continue;
            }
            
            if (
                excludeSecondaryAndTertiaryOperators &&
                (
                    roles.contains(SECONDARY_OPERATOR_ROLE) ||
                    roles.contains(TERTIARY_OPERATOR_ROLE)
                )
            ) {
                continue;
            }
            
            emails.add(relation.Contact.Email.trim());
        }
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