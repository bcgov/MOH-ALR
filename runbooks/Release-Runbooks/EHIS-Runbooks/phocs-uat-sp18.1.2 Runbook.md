
Sandbox|`Post refresh runbook till SP-18 " UAT ORG "|
|-|-|
|Runbook Created|`2026-02-23`|
|Runbook Last Modified|`2026-02-23`|

2. [x] Checkout to `release-phocs-uat-sp18.1.2`code

3.[x]  Deploy full repository (~20 min)

> sf project deploy start --source-dir bcgov-source/app-phocs/main/default/omniDataTransforms/ExtractPHOCSContact_1.rpt-meta.xml --target-org deployment.user@phocs.uat.com

> sf project deploy start --source-dir bcgov-source/app-phocs/main/default/omniScripts/LicensingAndPermitting_PersonalServiceEstablishmentHealthApproval_English_1.os-meta.xml --target-org deployment.user@phocs.uat.com

> sf project deploy start --source-dir bcgov-source/app-phocs/main/default/lwc/inspectionQuestionsParentv2/inspectionQuestionsParentv2.js --source-dir bcgov-source/core/main/default/objects/Account/fields/LicenseDetail__c.field-meta.xml --source-dir bcgov-source/core/main/default/objects/Account/fields/Status__c.field-meta.xml --source-dir bcgov-source/core/main/default/objects/Account/recordTypes/Residence.recordType-meta.xml --source-dir bcgov-source/app-phocs/main/default/objects/ViolationEnforcementAction/recordTypes/PHOCSViolationEnforcementAction.recordType-meta.xml --source-dir bcgov-source/app-phocs/main/default/flexipages/PHOCSDairyFacilityRecordPage.flexipage-meta.xml --source-dir bcgov-source/core/main/default/objects/AssessmentIndicatorDefinition/fields/RelatedRegulatoryCodes__c.field-meta.xml --source-dir bcgov-source/core/main/default/objects/AssessmentIndicatorDefinition/AssessmentIndicatorDefinition.object-meta.xml --source-dir bcgov-source/app-phocs/main/default/permissionsets/EHIS_Manage_System_Admin_User_PS.permissionset-meta.xml --source-dir bcgov-source/app-phocs/main/default/permissionsets/EHISReadAssessmentIndicatorDefinition.permissionset-meta.xml --source-dir bcgov-source/app-phocs/main/default/permissionsets/PHOCSREADReportingUser.permissionset-meta.xml --target-org deployment.user@phocs.uat.com

> sf project deploy start --source-dir bcgov-source/app-phocs/main/default/lwc/inspectionQuestionsParentv2/inspectionQuestionsParentv2.js --source-dir bcgov-source/app-phocs/main/default/lwc/inspectionQuestionsParentv2/inspectionQuestionsParentv2.html --source-dir bcgov-source/app-phocs/main/default/classes/RegCodeAssessmentIndTriggerHandler.cls --source-dir bcgov-source/app-phocs/main/default/classes/RegCodeAssessmentIndTriggerHandler.cls-meta.xml --source-dir bcgov-source/app-phocs/main/default/classes/RegCodeAssmentIndTriggerHandlerTest.cls --source-dir bcgov-source/app-phocs/main/default/classes/RegCodeAssmentIndTriggerHandlerTest.cls-meta.xml --source-dir bcgov-source/app-phocs/main/default/triggers/RegulatoryCodeAssessmentIndTrigger.trigger --source-dir bcgov-source/app-phocs/main/default/triggers/RegulatoryCodeAssessmentIndTrigger.trigger-meta.xml --target-org deployment.user@phocs.uat.com


PD step 
1. Uploaded Dairy Inspection report document V8 in document template designer