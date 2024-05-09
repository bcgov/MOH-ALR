/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Class is to declare Constant variables
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]  
                           ALR-36              ACN-ALR        License renewal initiation
                           ALR-1000            ACN-ALR        Send Late Fees Notifications
                           ALR-40              ACN-ALR        Fee calculation for newly added unit(s)       
                           ALR-775             ACN-ALR        Name of the Template is Incorrect   
                           ALR-726             ACN-ALR        Issues on Business License Application and Regulatory Fee   
                           ALR-820             ACN-ALR        Changing 'Application Status’ field       
                           ALR-996             ACN-ALR        Late Fee Initiation - Interface 
                           ALR-997             ACN-ALR        Generate Renewal Late Fee Transaction      
***********************************************************************************************/
public class BCMOH_Constants {
    public static final String IM_INPUT = 'input';
    public static final String IM_OUTPUT = 'output';
    public static final String IM_OPTIONS = 'options';
    public static final String IM_Inspection = 'InspectionId';
    public static final String IM_ADDUNITBLOCK = 'AddUnitBlock';
    //ALR-36 - renewals
    public Final static String renewalName = 'LicenseRenewalCriteria';
    public Final static String blaRecType = 'Renewal';
    public Final static String blaCancelledStatus = 'Cancelled';
    public Final static String renewalYear = String.valueOf(Date.Today().Year());
    public Final static String blaCreatedStatus = 'Ready for Renewal';
    public Final static String blaExcludedStatus = 'Excluded';
    public Final static String feeType = 'Renewal Unit Fee';
    public Final static String feeStatus = 'Paid';
    //ALR-1000
    public Final static String blaLateFeeStatus = 'Ready to Send';
    public Final static String lateFeeTitle = 'Late Fee Invoice';
    public Final static String lateFeeTemplate = 'LateFeeTemplate';
    public Final static String templatePurposeDetails = 'LateFee';
    public Final static String AccStatus = 'Registered Active Pending Renewal';

    //ALR-40
    public Final static String transFeeRecTypeId = Schema.getGlobalDescribe().get('RegulatoryTrxnFee').getDescribe().getRecordTypeInfosByDeveloperName().get('TransactionFee').getRecordTypeId();
    public Final static String unitFeeType = 'Unit Fee';
    public Final static String dueFeeStatus = 'Due';
    public Final static String pendingInvoiceStatus = 'Pending Invoice';
    public Final static String waivedStatus = 'Waived';
    public Final static Date feeDueDate = Date.Today().addDays(30);//ALR-185
    public Final static DateTime feeDueDateTime = DateTime.Now().addDays(30);//ALR-185
    public Final static String cancelledStatus = 'Canceled';//ALR-691
    //ALR-560
    public Final static String templatePurpose = 'Renewal';
    //error handling
    public Final static String noPrimaryContact = 'No primary contact record or no email id on primary contact';
    public Final static String noOrgWideAddr = 'No valid org wide email address found';
    public Final static String noBLRec = 'No business license record found';
    public Final static String mappingDataMissing = System.Label.TemplateFieldDataMissing;//'Data required for template merge field mapping is missing';
    public Final static String templateNameMissing = 'No email template found for ';
    public Final static String activePurposeTemplateMissing = 'No active email template name configured for ';
    //document error
    public Final static String documentNotFound = 'Document not found for specified template name';
    public Final static String nextYear = String.valueOf(Date.Today().Year() + 1);
    public Final static List<String> renewalTableStatus = new List<String>{blaCreatedStatus, blaExcludedStatus};
    public Final static String parentAssetRecTypeId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Units_Record_Type').getRecordTypeId();
    public Final static String unitRequestRecTypeId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Unit_Request_Record_Type').getRecordTypeId();
    public Final static String parentAssetRecType = 'Units_Record_Type';
    public Final static List<String> allALUnitTypes = new List<String>{'Private', 'Public', 'Per Diem', 'Late Fee'};//ALR-997
    public Final static String unitName='Unit';
    public Final static String unitRequestName='UnitRequest';
    public Final static String errorBlaStatus = 'Errored';
    public Final static String sentBlaStatus = 'Sent';
    //document request text mapping fields
    public Final static String templateContentVersionId = 'templateContentVersionId';
    public Final static String docTitle = 'title';
    public Final static String keepIntermediate = 'keepIntermediate';
    public Final static String fullUnitFee = 'Full Unit Fee';//ALR-726
    //ALR-775
    public Final static String renewalApplicationFormTitle = 'Renewal Application Form';
    public Final static String renewalInvoiceTitle = 'Renewal Invoice';
    public Final static String renewalInvoiceTemplate = 'RenewalInvoiceTemplate';
    public Final static String invoiceIdMerge = '{%%InvoiceId%%}';
    public Final static String documentNotFetched = 'Documents not fetched for Renewals';
    public Final static String docDataNotFetched = System.Label.DocumentFieldDataMissing;//'Data required for document generation missing';
    public Final static String regulatoryTransactionFee = 'Regulatory Transaction Fee';
    public Final static String LatestContentVersionId = 'LatestContentVersionId';
    public Final static String accountParent = 'Parent Account';
    public Final static String accountParentAddr = 'Parent Account Billing Address';
    public Final static String accountAddr = 'Account Address';
    public Final static String relatedContacts = 'Related Contacts';
    public Final static String regulatoryTransactionFeeItem = 'Regulatory Transaction Fee Item';
    public Final static String unitsPublic = 'Units-Public';
    public Final static String unitsPrivate = 'Units-Private';
    public Final static String unitsPerDiem = 'Units-Per Diem';
    public Final static String blCertId = 'Business License Certificate Id';
    public Final static String emailSentToId = System.Label.EmailSentToId;
    public Final static String emailSentTo = System.Label.EmailSentTo;
    public Final static String sentTime = System.Label.SentTime;
    public Final static String renewalBlaRecTypeId = Schema.getGlobalDescribe().get('BusinessLicenseApplication').getDescribe().getRecordTypeInfosByDeveloperName().get('Renewal').getRecordTypeId();
    public Final static String activeStatusBl = 'Active';
    public Final static String MANAGEUNITCLASSNAME = 'ManageUnitOmniService';
    public Final static String INSERTMERGERASSETMETHODNAME = 'insertMergedAssets';
    public Final static String UPDATEPARENTONCHILDASSETMETHODNAME = 'updateParentOnChildAssets';
    public Final static String lateFee = 'Late Fee'; // ALR-997
    //ALR-820
    public Final static List<String> renewalTableUpdateStatus = new List<String>{'Excluded', 'Cancelled'};
    // ALR-996
    public Final static List<String> FeeTypeStatuses = new List<String>{'Late Fee', 'Renewal Unit Fee'};
	public Final static List<String> LateFeeStatuses = new List<String>{'', 'Ready to Send'};  
    public final static String EXCEPMESSAGE = 'This is exception for testing and code coverage';
    public final static String ItemEntityName = 'AssessmentTask.AssessmentTaskDefinitionId';
	public final static String TaskType = 'InspectionChecklist';
    public final static String resultt = 'Non-compliant';
	public final static String nulltest = 'null';
}