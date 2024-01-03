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
    public Final Static String noPrimaryContact = 'No Primary Contact Record or No email Id on Primary Contact';
    public Final Static String noOrgWideAddr = 'No valid org wide email address found';
    public Final Static String nextYear = String.valueOf(Date.Today().Year() + 1);
    public Final Static List<String> renewalTableStatus = new List<String>{blaCreatedStatus, blaExcludedStatus}; 
    


}