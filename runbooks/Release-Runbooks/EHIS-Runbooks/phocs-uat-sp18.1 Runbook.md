Sandbox|`Post refresh runbook till SP-18 " UAT ORG "|
|-|-|
|Runbook Created|`2026-02-17`|
|Runbook Last Modified|`2026-02-17`|

2. [x] Checkout to `release-phocs-uat-sp18.1.1`code

3.[x]  Deploy full repository (~20 min)

> sf project deploy start --source-dir bcgov-source/app-phocs/main/default/objects/LabTestRequired__c/fields/Test__c.field-meta.xml --source-dir bcgov-source/app-phocs/main/default/flexipages/PHOCSContactDairyRecordPage.flexipage-meta.xml --source-dir bcgov-source/app-phocs/main/default/permissionsets/EHIS_CRE_Contact_PS.permissionset-meta.xml --source-dir bcgov-source/app-phocs/main/default/permissionsets/EHIS_Manage_System_Admin_User_PS.permissionset-meta.xml --source-dir bcgov-source/app-phocs/main/default/permissionsets/PHOCSREADReportingUser.permissionset-meta.xml --source-dir bcgov-source/core/main/default/objects/Contact/fields/PHOCSTotalLicenseYearsFor__c.field-meta.xml --source-dir bcgov-source/core/main/default/objects/Contact/fields/PHOCSTotalrestrictedlicensedurationFor__c.field-meta.xml --source-dir bcgov-source/app-phocs/main/default/flows/PHOCS_Delete_Business_License_Flow.flow-meta.xml --source-dir bcgov-source/app-phocs/main/default/flows/PHOCS_Update_contact_License_Fields.flow-meta.xml --target-org deployment.user@phocs.uat.com

> sf project deploy start --source-dir bcgov-source/app-phocs/main/default/classes/CustomTokenInspectionData.cls --source-dir bcgov-source/app-phocs/main/default/classes/CustomTokenInspectionDataTest.cls --source-dir bcgov-source/app-phocs/main/default/classes/CustomTokenInspectionDataTest.cls-meta.xml --target-org deployment.user@phocs.uat.com 

PD step 
1. Uploaded Dairy Inspection report document V5 in document template designer