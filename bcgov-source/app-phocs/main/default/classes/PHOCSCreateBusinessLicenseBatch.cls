/**
 * Batch Class: PHOCSCreateBusinessLicenseBatch
 *
 * Purpose:
 * Creates Business License records for Business License Applications (BLA)
 * that were migrated by a configured Data Migration user and do not already
 * have an associated Business License.
 *
 * Processing Logic:
 * - Retrieves BLAs based on the Created By user and Created Date range
 *   configured in the custom setting.
 * - Processes only BLAs where LicensePermitNameId is blank.
 * - Creates a new Business License using the PHOCSPermitLicense record type.
 * - Populates Account, License Type, Status, Period Start Date, and Name
 *   from the source BLA.
 * - Updates the source BLA with the newly created Business License Id
 *   in the LicensePermitNameId field.
 *
 * Configuration:
 * - Created By User Name and Created Date range are maintained in a
 *   custom setting "PHOCS Business License Batch Setting" and can be changed without modifying code.
 * - Business License Record Type is dynamically retrieved using the
 *   BusinessLicense Record Type Developer Name: PHOCSPermitLicense.
 *-  Summary of the batch run will be stored in the Batch Result property of the Custom Setting
 *
 * Notes:
 * - Designed for bulk processing using Batch Apex.
 * - Supports partial success processing.
 * - Previously processed BLAs are excluded from subsequent runs because
 *   LicensePermitNameId is populated after successful processing.
 * 
 * Command to Execute: 
 * Id batchJobId = Database.executeBatch( new PHOCSCreateBusinessLicenseBatch(),  200);
 * System.debug('Batch Job Id: ' + batchJobId);
 */

public without sharing class PHOCSCreateBusinessLicenseBatch
    implements Database.Batchable<SObject>, Database.Stateful {

    private static final String BUSINESS_LICENSE_RECORD_TYPE = 'PHOCSPermitLicense';
    private static final String ACTIVE_STATUS = 'Active';
    private static final String CLOSED_STATUS = 'Closed';

    private String createdByUserName;
    private Datetime createdDateStart;
    private Datetime createdDateEnd;
        
    private Integer inputBlaRecordsCount = 0;
    private Integer businessLicensesCreatedCount = 0;
    private Integer successCount = 0;
    private Integer errorCount = 0;
  
    public PHOCSCreateBusinessLicenseBatch() {

        PHOCSBusinessLicenseBatchSetting__c batchSetting =  PHOCSBusinessLicenseBatchSetting__c.getOrgDefaults();

        if (batchSetting == null ||
            String.isBlank(batchSetting.CreatedByUserName__c) ||
            batchSetting.CreatedDateStart__c == null ||
            batchSetting.CreatedDateEnd__c == null) {

            throw new PHOCSBusinessLicenseBatchException(
                'PHOCS Business License Batch custom setting is missing ' +
                'or incomplete. Populate Created By Name, Start Date/Time, ' +
                'and End Date/Time.'
            );
        }

        if (batchSetting.CreatedDateStart__c > batchSetting.CreatedDateEnd__c) {

            throw new PHOCSBusinessLicenseBatchException(
                'Created Date Start cannot be later than Created Date End.'
            );
        }

        createdByUserName = batchSetting.CreatedByUserName__c.trim();
        createdDateStart = batchSetting.CreatedDateStart__c;
        createdDateEnd = batchSetting.CreatedDateEnd__c;
    }

    /**
     * Start
     *
     * Retrieves Business License Applications that:   
     * 1. Were created by the configured user.
     * 2. Were created within the configured date/time range.
     */
    public Database.QueryLocator start(Database.BatchableContext batchContext) {

        return Database.getQueryLocator([
            SELECT
                Id,
                AccountId,
                Account.Name,
                LicenseType.Id,
                LicenseType.Name,
                LicensePermitNameId
                
            FROM BusinessLicenseApplication
            WHERE LicensePermitNameId = NULL
              AND Status= :CLOSED_STATUS
              AND AccountId != NULL
              AND LicenseType.Id != NULL
              AND CreatedBy.Username = :createdByUserName
              AND CreatedDate >= :createdDateStart
              AND CreatedDate <= :createdDateEnd 
        ]);
    }

    /**
     * Execute
     *
     * Creates one Business License for each BLA 
     * Updates LicensePermitNameId on the originating BLA.
     */
    public void execute(Database.BatchableContext batchContext, List<BusinessLicenseApplication> scope ) {       
        inputBlaRecordsCount += scope.size();
        if (scope.isEmpty()) {
            return;
        }

        Id businessLicenseRecordTypeId = getBusinessLicenseRecordTypeId();
        Date currentDate = Date.today();
        List<BusinessLicense> businessLicensesToInsert = new List<BusinessLicense>();
        List<BusinessLicenseApplication> sourceBLAs = new List<BusinessLicenseApplication>();
		
        for (BusinessLicenseApplication bla : scope) {
			
            if (bla.AccountId == null || bla.Account == null || bla.LicenseType == null || bla.LicenseType.Id == null) {
                continue;
            }
            String accountName = String.isBlank(bla.Account.Name) ? '' : bla.Account.Name.trim();
            String licenseTypeName = String.isBlank(bla.LicenseType.Name) ? '': bla.LicenseType.Name.trim();
            String businessLicenseName = accountName + ' ' + licenseTypeName;
            BusinessLicense newBusinessLicense =  new BusinessLicense();
            newBusinessLicense.RecordTypeId = businessLicenseRecordTypeId;
            newBusinessLicense.Account__c = bla.AccountId;
            newBusinessLicense.Name = businessLicenseName.trim();
            newBusinessLicense.PeriodStart = currentDate;
            newBusinessLicense.RegulatoryAuthorizationTypeId = bla.LicenseType.Id;
            newBusinessLicense.Status = ACTIVE_STATUS;
            businessLicensesToInsert.add(newBusinessLicense);
            sourceBLAs.add(bla);
        }
		
        if (businessLicensesToInsert.isEmpty()) {
            return;
        }
		//Insert Business License Records
        Database.SaveResult[] insertResults = Database.insert(businessLicensesToInsert, false);
		
		List<BusinessLicenseApplication> blasToUpdate = new List<BusinessLicenseApplication>();

        for (Integer index = 0; index < insertResults.size(); index++) {
            Database.SaveResult insertResult = insertResults[index];
            if (insertResult.isSuccess()){
				businessLicensesCreatedCount ++;
                blasToUpdate.add(new BusinessLicenseApplication(
                        Id = sourceBLAs[index].Id,
                        LicensePermitNameId = insertResult.getId()
                    )
                );
            } 
        }
        if (blasToUpdate.isEmpty()) {
            return;
        }
		//Update Business License Applications
        Database.SaveResult[] updateResults = Database.update(blasToUpdate, false);
        
        for (Integer index = 0; index < updateResults.size();index++) {
			 if (updateResults[index].isSuccess()) {
                    successCount++;
             } else if (!updateResults[index].isSuccess()) {
                errorCount++;             
            }
        }
    }

    public void finish(Database.BatchableContext batchContext) {
       
        String batchResult = 
        '\nBusiness License Batch Execution Summary\n' +
        '========================================\n' +
        'Completed On: ' + String.valueOf(System.now()) + '\n' +
        'Input BLA Records Count: ' + inputBlaRecordsCount + '\n' +
        'BL Records Created Count: ' + businessLicensesCreatedCount + '\n' +
        'BLA Update Success Count: ' + successCount + '\n' +
        'BLA Update Errors Count: ' + errorCount + '\n';

    PHOCSBusinessLicenseBatchSetting__c setting =
        PHOCSBusinessLicenseBatchSetting__c.getOrgDefaults();

    if(setting == null) {
        setting = new PHOCSBusinessLicenseBatchSetting__c();
    }

    setting.BatchResult__c = batchResult;

    upsert setting;
    }

    private static Id getBusinessLicenseRecordTypeId() {

        Map<String, Schema.RecordTypeInfo> recordTypesByDeveloperName =
            Schema.SObjectType.BusinessLicense
                .getRecordTypeInfosByDeveloperName();

        Schema.RecordTypeInfo recordTypeInfo =
            recordTypesByDeveloperName.get(
                BUSINESS_LICENSE_RECORD_TYPE
            );

        if (recordTypeInfo == null) {
            throw new PHOCSBusinessLicenseBatchException(
                'Record Type with Developer Name "' +
                BUSINESS_LICENSE_RECORD_TYPE +
                '" was not found on BusinessLicense.'
            );
        }

        if (!recordTypeInfo.isActive()) {
            throw new PHOCSBusinessLicenseBatchException(
                'BusinessLicense Record Type "' +
                BUSINESS_LICENSE_RECORD_TYPE +
                '" is inactive.'
            );
        }

        return recordTypeInfo.getRecordTypeId();
    }

    public class PHOCSBusinessLicenseBatchException
        extends Exception {
    }
}