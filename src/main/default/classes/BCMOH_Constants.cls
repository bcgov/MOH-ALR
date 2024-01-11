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
    //ALR-40
    public Final Static String transFeeRecTypeId = Schema.getGlobalDescribe().get('RegulatoryTrxnFee').getDescribe().getRecordTypeInfosByDeveloperName().get('TransactionFee').getRecordTypeId();
    public Final Static String unitFeeType = 'Unit Fee';
    public Final Static String dueFeeStatus = 'Due';
    public Final Static String pendingInvoiceStatus = 'Pending Invoice';
    public Final Static Date feeDueDate = Date.Today().addDays(30);//ALR-185
    public Final Static DateTime feeDueDateTime = DateTime.Now().addDays(30);//ALR-185
    public Final Static String cancelledStatus = 'Canceled';//ALR-691
    //ALR-560
    public Final Static String templatePurpose = 'Renewal';
    //error handling
    public Final Static String noPrimaryContact = 'No primary contact record or no email id on primary contact';
    public Final Static String noOrgWideAddr = 'No valid org wide email address found';
    public Final Static String noBLRec = 'No business license record found';
    public Final Static String mappingDataMissing = 'Data required for template merge field mapping is missing';
    public Final Static String templateNameMissing = 'No email template found for ';
    public Final Static String activePurposeTemplateMissing = 'No active email template name configured for ';
    //document error
    public Final Static String documentNotFound = 'Document not found for specified template name';
    public Final Static String nextYear = String.valueOf(Date.Today().Year() + 1);
    public Final Static List<String> renewalTableStatus = new List<String>{blaCreatedStatus, blaExcludedStatus};
    public Final Static String parentAssetRecTypeId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Units_Record_Type').getRecordTypeId();
    public Final Static String parentAssetRecType = 'Units_Record_Type';
    public Final Static List<String> allALUnitTypes = new List<String>{'Private', 'Public', 'Per Diem'};
    public Final Static String unitName='Unit';
    public Final Static String errorBlaStatus = 'Errored';
    public Final Static String sentBlaStatus = 'Sent';
    //document request text mapping fields
    public Final Static String templateContentVersionId = 'templateContentVersionId';
    public Final Static String docTitle = 'title';
    public Final Static String keepIntermediate = 'keepIntermediate';
    
    
}