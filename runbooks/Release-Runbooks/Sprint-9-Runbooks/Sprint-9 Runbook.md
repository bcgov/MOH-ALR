# Post refresh Deployment Runbook

|Sandbox|`SP9`|
|-|-|This deployment is done before PRD Spirnt-5 deployment
|Runbook Created|`2024-05-21`|
|Runbook Last Modified|`2024-05-23`|

## Pre-Requisites [5 min ]

1. [x] Deployment User has assigned Permission Sets

   1.EHIS ALR Data Migration PS
   2.EHIS Enable MFA PS
   3.Action Plans PS
   4.Document checklist PS
   5.DocGen Designer PS
   6.ALR All Users PG
   7.ALR Data Analyst Users PG

2. [x] Checkout to `latest QA.284` code  - create new branch out of it "release-UAT-SP9.1"

## Assumptions

1. Total execution time ~ > 3 hrs

## Open Items

## Pre-Deployment Steps (3 mins)

[x] ALR-1567 destructive deployment

- Deleting validation rule - go to Setup-->Object Manager-->Inspection object-->validation rule-->RestrictingFieldsEditForVisitRule--> click on dropdown and delete it

## Deployment Steps (20 mins)

1. [x] Deploy OmniStudio components and its dependencies (5 min)
   > sfdx force:source:deploy --sourcepath "src\main\default\omniDataTransforms,src\main\default\omniIntegrationProcedures,src\main\default\omniUiCard,src\main\default\omniScripts" --wait 30 --targetusername deployment.user@gov.bc.ca.alr

3. [x]  Deploy full repository (~20 min)
   1. [x] Verify folders
      |Folder|Path|
      |-|-|
      |`src`|`src\main\default`|
      |`src-access-mgmt`|`src-access-mgmt\main\default`|
      |`src-ui`|`src-ui\main\default`|
   
   2. [x] Deploy 
      > sfdx force:source:deploy --sourcepath "src\main\default,src-access-mgmt\main\default,src-ui\main\default" --wait 30 --targetusername deployment.user@gov.bc.ca.alr -l RunLocalTests

   3. [x] Re-activate Omnistudio components
      1. App Launcher -> OmniStudio -> Omnistudio **Integration Procedures**
      2. Locate all active custom **Integration Procedures** -> deactivate them -> activate them back.
      3. App Launcher -> OmniStudio -> **Omnistudio FlexCards**
      4. Locate all active custom **FlexCards** -> open each FlexCard -> deactivate -> activate back.
      5. App Launcher -> OmniStudio -> **OmniScripts**
      6. Locate all active custom **OmniScripts** -> open each FlexCard -> deactivate -> activate back

## Post-Deployment Steps (30 mins)

1.[x] ALR-1486 Uncheck the violation checkbox

- Login as System Administrator, click on gear icon and open setup
- Go to Object Manager and open Inspection Assessment Indicator 
- Open Assessment Question Status (Result) field in Fields & Relationships
- Go to Assessment Question Status Pick list Values and Click edit Next to Non-compliant field and uncheck the violation checkbox.

2.[x] ALR-1540 Delete Existing templates below in Org 

- Step 1 :- App launcher-> omni studio -> Document template designer ->delete below 3 templates and import one after other one by one
- Step 2 :- First Import all 3 certificate template Json files and then replace with ppt and activate the template

1.CertificateTemplateMH Json->CertificateBackground_MH.pptx
2.CertificateTemplateSU Json ->CertificateBackground_SU.pptx
3.CertificateTemplateSN->replace with CertificateBackground_MH.pptx 

3.[x] ALR-1544

- Login as System administrator, click on setup and open static resources,find “SumanLeadership“ and “Sue_Benford_Sign“ and Delete it.

4.[x] ALR-1533

- Deactivate the flow in every org with this story deployment:
- Flow Name: GenerateRenewalsForAccounts

5.[x] ALR-1562 Refer Jira for this step

6.[x] ALR-1577 Assign PS in all the higher orgs till production

- Log in as System Administrator
- Assign the following Permission Set to all ALR Active Users (Business+Onshore+offshore) the necessary users 
- Permission Set - Business Milestones and Life Events Access

7.[x] Flow status verification

- Please verify if the latest version of the mentioned flows are activated in all orgs. If not, Please activate the latest version.
- Flows
 1.Get Category List From Assessment Indicator Definition
 2.add Inspection Tasks

 8.[x] ALR-1586 List view deletion
-From app launcher - EHIS Services - Go to Accounts(in home dropdown)->ListView->Residence Ready for Renewals->select settings->Delete

9.[x] ALR-1587 refer jira

10.[x] ALR-1199 Go to Omniscript “RiskAssessment“ → Open active version → Click on dropdown and select “Select Deploy Standard Runtime Compatible LWC “ → Done. 

DevOps checklist:

1. Make sure you activated the templates CertificateTemplateMH , CertificateTemplateSN Json ,CertificateTemplateSU Json
2. Validate the flows in org with Repo make sure active/inactive versions in branch which are deployed by devops should match in org
3.Accounts-ListView->Residence Ready for Renewals is deleted sometimes its not deleting properly