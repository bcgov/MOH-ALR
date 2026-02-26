Sandbox|`Post refresh runbook till SP-18 " UAT ORG "|
|-|-|
|Runbook Created|`2026-02-26`|
|Runbook Last Modified|`2026-02-26`|

2.[x] Checkout to `release-phocs-uat-sp18.1.3`code

3.[x]  Deploy full repository (~20 min)


> sf project deploy start --source-dir bcgov-source/app-phocs/main/default/flexipages/PHOCSDairyEnvironmentalSwabTesting.flexipage-meta.xml --source-dir bcgov-source/app-phocs/main/default/flexipages/PHOCSDairyFacilityRecordPage.flexipage-meta.xml --source-dir bcgov-source/core/main/default/objects/BusinessLicenseApplication/fields/WorkerEducationYear__c.field-meta.xml --source-dir bcgov-source/app-alr/main/default/permissionsets/EHIS_Leadership_User_PS.permissionset-meta.xml --source-dir bcgov-source/app-alr/main/default/flexipages/Public_Complaint_Record_Page.flexipage-meta.xml --target-org deployment.user@phocs.uat.com