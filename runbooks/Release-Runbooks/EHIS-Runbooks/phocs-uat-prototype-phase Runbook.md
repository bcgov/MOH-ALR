# Release Deployment Runbook

|Sandbox|`uat`
|Runbook Created|`2025-09-15`|
|Runbook Last Modified|`2025-09-15`|

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

2. [x] Checkout to `phocs-uat-protophase`code 
 
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

   - sf project deploy start --source-dir bcgov-source\app-phocs\main\default\omniDataTransforms --source-dir bcgov-source\app-phocs\main\default\omniScripts --source-dir bcgov-source\app-phocs\main\default\omniUiCard --source-dir bcgov-source\core\main\default\omniDataTransforms --source-dir bcgov-source\core\main\default\omniScripts --target-org deployment.user@phocs.

   3. [x] Deploy env specific folder

   > sf project deploy start --source-dir src-env-specific --target-org deployment.user@phocs.uat.com
   
   4. [x] Deploy full folder
   - sf project deploy start --source-dir bcgov-source --target-org deployment.user@phocs.uat.com --test-level RunLocalTests

## Post-Deployment Steps (30 mins)

- [x] EHIS-2527

> In “My Domain” under authentication service add “PHOCS IDIR” and “Health BC”.
> Set the default domain according to the environment:
  - Go to custom metadata - user registration mappings-open labels as per PD step and update below under default domain - for UAT update : phocs.uat

- [x] EHIS-2530
> salesforcebackupadmininstratorbackup.ps copy from BCMOHAD-28583-Release-1.14.0.8 branch

- [x] EHIS-2337
>Update the Header Color to rgb(0, 51, 102)
>Steps : 

- Go to Quick find--> All Sites → Phocsservices → Click on Builder → Click on Page Dropdown → Select Page “Home” → click on header of home page → on right hand side the configuration box will appear “Stacked Header” → click on color and put rgb(0, 51, 102) in color. 

- Repeat the same for Facilities Page → Click on Page Dropdown → select page “Facilities” → then click on header and change the color to rgb(0, 51, 102)

- Publish the site by clicking on Publish button on right hand side.
this PD step needs to perform in UAT and PRD for every deployment

- downloaded templates from QA and uploaded in UAT for recent bugs
>residential care
>pool construction
>Drinking water construction permit
>drinking water operating permit
>PHOCS Food safety Requisition Template

DevOps checklist:

1.Ensure below steps
- make sure templates uploaded are activated
- phocs.uat default domains are updated in uat under custom metadata