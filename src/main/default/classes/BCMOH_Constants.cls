public class BCMOH_Constants {
     public static final String IM_INPUT = 'input';
     public static final String IM_OUTPUT = 'output';
     public static final String IM_OPTIONS = 'options';
    public static final String IM_ADDUNITBLOCK = 'AddUnitBlock';
    //ALR-36 - renewals
    public Final Static String renewalName = 'LicenseRenewalCriteria';
    public Final Static String blaRecType = 'Renewal';
    public Final Static String blaCancelledStatus = 'Cancelled';
    public Final Static String renewalYear = String.valueOf(Date.Today().Year());
    public Final Static String blaCreatedStatus = 'Ready for Renewal';
    public Final Static String blaExcludedStatus = 'Excluded';
    public Final Static String feeType = 'Renewal Unit Fee';
    public Final Static String feeStatus = 'Paid';
    //ALR-1000
    public Final Static String blaLateFeeStatus = 'Ready to Send';
    public Final Static String lateFeeTitle = 'Late Fee Invoice';
    public Final Static String lateFeeTemplate = 'LateFeeTemplate';
    public Final Static String templatePurposeDetails = 'LateFee';
    public Final Static String AccStatus = 'Registered Active Pending Renewal';
    //ALR-40
    public Final Static String transFeeRecTypeId = Schema.getGlobalDescribe().get('RegulatoryTrxnFee').getDescribe().getRecordTypeInfosByDeveloperName().get('TransactionFee').getRecordTypeId();
    public Final Static String unitFeeType = 'Unit Fee';
    public Final Static String dueFeeStatus = 'Due';
    public Final Static String pendingInvoiceStatus = 'Pending Invoice';
    public Final Static String waivedStatus = 'Waived';
    public Final Static Date feeDueDate = Date.Today().addDays(30);//ALR-185
    public Final Static DateTime feeDueDateTime = DateTime.Now().addDays(30);//ALR-185
    public Final Static String cancelledStatus = 'Canceled';//ALR-691
    //ALR-560
    public Final Static String templatePurpose = 'Renewal';
    //error handling
    public Final Static String noPrimaryContact = 'No primary contact record or no email id on primary contact';
    public Final Static String noOrgWideAddr = 'No valid org wide email address found';
    public Final Static String noBLRec = 'No business license record found';
    public Final Static String mappingDataMissing = System.Label.TemplateFieldDataMissing;//'Data required for template merge field mapping is missing';
    public Final Static String templateNameMissing = 'No email template found for ';
    public Final Static String activePurposeTemplateMissing = 'No active email template name configured for ';
    //document error
    public Final Static String documentNotFound = 'Document not found for specified template name';
    public Final Static String nextYear = String.valueOf(Date.Today().Year() + 1);
    public Final Static List<String> renewalTableStatus = new List<String>{blaCreatedStatus, blaExcludedStatus};
    public Final Static String parentAssetRecTypeId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Units_Record_Type').getRecordTypeId();
    public Final Static String unitRequestRecTypeId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Unit_Request_Record_Type').getRecordTypeId();
    public Final Static String parentAssetRecType = 'Units_Record_Type';
    public Final Static List<String> allALUnitTypes = new List<String>{'Private', 'Public', 'Per Diem', 'Late Fee'};//ALR-997
    public Final Static String unitName='Unit';
    public Final Static String unitRequestName='UnitRequest';
    public Final Static String errorBlaStatus = 'Errored';
    public Final Static String sentBlaStatus = 'Sent';
    //document request text mapping fields
    public Final Static String templateContentVersionId = 'templateContentVersionId';
    public Final Static String docTitle = 'title';
    public Final Static String keepIntermediate = 'keepIntermediate';
    public Final Static String fullUnitFee = 'Full Unit Fee';//ALR-726
    //ALR-775
    public Final Static String renewalApplicationFormTitle = 'Renewal Application Form';
    public Final Static String renewalInvoiceTitle = 'Renewal Invoice';
    public Final Static String renewalInvoiceTemplate = 'RenewalInvoiceTemplate';
    public Final Static String invoiceIdMerge = '{%%InvoiceId%%}';
    public Final Static String documentNotFetched = 'Documents not fetched for Renewals';
    public Final Static String docDataNotFetched = System.Label.DocumentFieldDataMissing;//'Data required for document generation missing';
    public Final Static String regulatoryTransactionFee = 'Regulatory Transaction Fee';
    public Final Static String LatestContentVersionId = 'LatestContentVersionId';
    public Final Static String accountParent = 'Parent Account';
    public Final Static String accountParentAddr = 'Parent Account Billing Address';
    public Final Static String accountAddr = 'Account Address';
    public Final Static String relatedContacts = 'Related Contacts';
    public Final Static String regulatoryTransactionFeeItem = 'Regulatory Transaction Fee Item';
    public Final Static String unitsPublic = 'Units- Public';
    public Final Static String unitsPrivate = 'Units- Private';
    public Final Static String unitsPerDiem = 'Units- Per Diem';
    public Final Static String blCertId = 'Business License Certificate Id';
    public Final Static String emailSentToId = System.Label.EmailSentToId;
    public Final Static String emailSentTo = System.Label.EmailSentTo;
    public Final Static String sentTime = System.Label.SentTime;
    public Final Static String renewalBlaRecTypeId = Schema.getGlobalDescribe().get('BusinessLicenseApplication').getDescribe().getRecordTypeInfosByDeveloperName().get('Renewal').getRecordTypeId();
    public Final Static String activeStatusBl = 'Active';
    public Final Static String MANAGEUNITCLASSNAME = 'ManageUnitOmniService';
    public Final Static String INSERTMERGERASSETMETHODNAME = 'insertMergedAssets';
    public Final Static String UPDATEPARENTONCHILDASSETMETHODNAME = 'updateParentOnChildAssets';
    public Final Static String lateFee = 'Late Fee'; // ALR-997
    //ALR-820
    public Final Static List<String> renewalTableUpdateStatus = new List<String>{'Excluded', 'Cancelled'};
    // ALR-996
    public Final Static List<String> FeeTypeStatuses = new List<String>{'Late Fee', 'Renewal Unit Fee'};
	public Final Static List<String> LateFeeStatuses = new List<String>{'', 'Ready to Send'};    
        
}