# Release Deployment Runbook

|Sandbox|`uat`
|Runbook Created|`2025-09-19`|
|Runbook Last Modified|`2025-09-19`|

## Pre-Requisites [5 min ]

1. [x] Deployment User has assigned Permission Sets , Public Groups , PSG below

   1.EHIS Data Migration PS
   2.EHIS Enable MFA PS
   3.Action Plans PS
   4.Document checklist PS
   5.DocGen Designer PS 
   6.DocGen Designer
   7.Docgen Designer Standard User
   8.Business Milestones and Life Events Access PS
   9.Groupmembership PS
  10.OmniStudio User
  11.OmniStudio Admin

- Public Groups
    - ALR All Users PG
    - ALR Data Analyst Users PG
    - ALR Admin Users PG
    - EHIS Officer Users PG
    - EHIS Water Admin Users PG
    - PHOCS Business Admin & Officer PG

- Permission Set Groups
    - EHIS ALR Admin PSG
    - EHIS ALR Data Analyst PSG
    - EHIS ALR Data Migration PSG
    - EHIS System Administrator PSG
    - EHIS Officer PSG
    - EHIS Business Admin PSG
    - PHOCS System Administrator PSG

2. [x] Checkout to dev and create a new branch out of it `phocs-uat-protophase-1.1`code 
 
## Assumptions

1. Total execution time ~ > 30 mins

## Open Items

## Pre-Deployment Steps (3 mins)

[ ] None

## Deployment Steps (20 mins)

1. [x]  Deploy full repository (~20 min)
   1. [x] Verify folders
      |Folder|Path|
      |-|-|
      |'bcgov-source`|

   2. [x] Deploy Omni studio components

   - sf project deploy start --source-dir bcgov-source/app-phocs/main/default/omniDataTransforms/TransformBusinessLicenseDetails_1.rpt-meta.xml --source-dir bcgov-source/app-phocs/main/default/omniDataTransforms/TransformBLOperatingPermit_1.rpt-meta.xml --source-dir bcgov-source/app-phocs/main/default/omniDataTransforms/TransformBLPoolConstructionPermit_1.rpt-meta.xml --source-dir bcgov-source/app-phocs/main/default/omniDataTransforms/GetBusinessLicenseDetails_1.rpt-meta.xml --target-org deployment.user@phocs.uat.com

   
   4. [x] Deploy full folder

   > sf project deploy start --source-dir bcgov-source/app-phocs/main/default/flexipages/PHOCSFoodTestRequisitionRecordPage.flexipage-meta.xml --source-dir bcgov-source/app-phocs/main/default/customMetadata/Docgen_Mapping.PHOCS_Water_Lab_Test_Requisition.md-meta.xml --source-dir bcgov-source/app-phocs/main/default/permissionsets/EHISCreateEditFacilities.permissionset-meta.xml --source-dir bcgov-source/core/main/default/objects/PublicComplaint/compactLayouts/PHOCSPublicComplaintCompactLayout.compactLayout-meta.xml --target-org deployment.user@phocs.uat.com

   > sf project deploy start --source-dir bcgov-source/core/main/default/objects/Account/fields/FacilityCHSAText__c.field-meta.xml --source-dir bcgov-source/core/main/default/objects/Account/listViews/Child_Care_Facilities.listView-meta.xml --source-dir bcgov-source/core/main/default/objects/Account/listViews/Drinking_Water_Systems.listView-meta.xml --source-dir bcgov-source/core/main/default/objects/Account/listViews/Food_Facilities.listView-meta.xml --source-dir bcgov-source/core/main/default/objects/Account/listViews/Hospital_Act_Facilities.listView-meta.xml --source-dir bcgov-source/core/main/default/objects/Account/listViews/Industrial_Camps_Facilities.listView-meta.xml --source-dir bcgov-source/core/main/default/objects/Account/listViews/Personal_Services_Facilities.listView-meta.xml --source-dir bcgov-source/core/main/default/objects/Account/listViews/Recreational_Water_Facilities.listView-meta.xml --source-dir bcgov-source/core/main/default/objects/Account/listViews/Residential_Care_Facilities.listView-meta.xml --source-dir bcgov-source/core/main/default/objects/Account/listViews/Sewerage_Facilities.listView-meta.xml --source-dir bcgov-source/core/main/default/objects/Account/listViews/Tobacco_and_Vapour_Facilities.listView-meta.xml --source-dir bcgov-source/core/main/default/objects/Account/Account.object-meta.xml --target-org deployment.user@phocs.uat.com

## Post-Deployment Steps (30 mins)

- downloaded templates from QA and uploaded in UAT for recent bugs
>pool construction
>Drinking water construction permit

DevOps checklist:

1.Ensure below steps
- make sure templates uploaded are activated
- phocs.uat default domains are updated in uat under custom metadata