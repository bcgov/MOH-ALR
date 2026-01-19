|Sandbox|`Post refresh runbook till SP-17 " UAT ORG "|
|-|-|
|Runbook Created|`2026-01-19`|
|Runbook Last Modified|`2026-01-19`|

## Pre-Requisites [5 min ]

1. [x] Deployment User has assigned Permission Sets

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
  12.Industries Visit

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

2. [x] Checkout to `release-phocs-uat-sp17`code 

## Assumptions

1. Total execution time ~ > 3hrs 

## Open Items

## Pre-Deployment Steps (20 mins)

[x] 1. Delete Fields from Account object and from facility record page
ExclusiveChangeRoomplantworkers__c
AnimalsOnSite__c
ExclusiveWashroomplantworkers__c

[x] Delete custom metadata field from PHOCSActionPlanTemplateDecisionMap
InspectionAccountType__c
- deployed InspectionFacilityType__c, InspectionCategory__c fields as a predeployment step before deploying apexclass
field dependency on apexclass - deploy apex class change from branch to target org

[x] EHIS-3105
Go to phocs app services - open action plan templates - click on setup - edit object - go to record type - create ALR action plan template 
1. Label ALR Action Plan Template
   API Name - ALRActionPlanTemplate
   Active=True
   Description - Capture templates for ALR Action Plans

## Deployment Steps (20 mins)

1. [ ] Deploy ActionPlanTemplates

> sf project deploy start --source-dir ActionPlanTemplates-Phocs\main\default\BCCDC_Dairy_Checklist_13e2c7f5_c56a_11f0_8a33_9524194c70a3.apt-meta.xml --wait 30 --target-org deployment.user@phocs.uat.com

2. [x] Deploy Omni studio components 

> Deploy Omni data transforms
PHOCSRegulatoryTrxnFeeDataMapper_1	
PHOCSRegulatoryTrxnFeeExtract_1	
PHOCSRegulatoryTrxnFeeReceiptDM_1
PHOCSRegulatoryTrxnFeeReceiptExtract_1
getDSWRelatedStorageFacilities_1
DRdocgengetRegulatoryTrxnFeeDetails_1

> Deploy Omniscripts
DocumentGeneration_PHOCSDocumentGeneration_English_3
LicensingAndPermitting_storagefacilities_English_3

4.[x]  Deploy full repository (~20 min)

> sf project deploy start --source-dir bcgov-source --target-org deployment.user@phocs.uat.com --test-level RunLocalTests -g

## Post-Deployment Steps (30 mins)

[x] EHIS-2865 Update Sharing on PHOCS Action Plan Template

   1. App Launcher -> Action Plan Templates -> **navigate** to `BCCDC Dairy checklists` record

   [x] - As part of post deployment steps, after the deployment of “Action plan templates“, the status of this template is ‘Read only’, it's not visible to the users while adding a template on Action plan creation.
   -So please do the following steps to activate the template, 
   -Note: Login as Phocs system admin user should have only phocs Permissions assigned
   -Step 1: Clone the existing Templates
   -Step 2: After cloning the Original Action Plan Template
   Before Publishing the template in the items section of Document checklist items 
   -Step 3: **Add** Sharing 

      |Item Type|Item Name|Access Level|
      |-|-|-|
      |Public Group|` EHISUsersPG`|Read/Write|
      |Public Group|`PHOCS Reporting User PG` |Read Only|
      |Public Group|`PHOCS Operator User PG` |Read Only|

   3. Click **Save**

- [x] Upload Action plan template
  MOH-ALR\ActionPlanTemplates-Phocs\main\default\ BCCDC_Dairy_Checklist_13e2c7f5_c56a_11f0_8a33_9524194c70a3.apt-meta
- Share the action plan template to 
- PHOCS Business Admin & Officer PG - Public Group - Read/Write
- PHOCS Reporting User PG -Public Group - Read
- Update Decision Metrics

[x] Upload Decision Matrix
- Click App Launcher, search “Business Rules Engine”
- Select Lookup Tables tab, find “PHOCS Document Checklists Decision Matrix” record
- Select the latest version in Related list
- Click “Upload PHOCS Document Checklists V1_2025-11-26 14_05_31 CSV File” to upload attached file 

8.[x] EHIS-2703
- Post PD Step to perform - create a contact
 2. Create an account with BE RT
 3. Assign role to contact owner 
 4. switch to classic and open contact and enable for experience user ,now it will direct to create user - create a user with customer community operator
 4. go to potal - click on workspace - administration - memebers - add potal profile and ps 
- Profile - Custom Community Operator.
- Permission set - PHOCS Operator User CRE PS.

- [x] EHIS-2735

  PDT's for PHOCS site publish
  Step-1: Open the target salesforce instance.
  Step-2: Click on the gear icon and select setup.
  Step-3: Search for 'All Sites' and then select builder for phocsservices.
  Step-4: Select the "Publish" on Home Page - on right top Corner.
  Step-5: Again Click on "publish" button on pop-up window.
  Step-6: Click on "Got It" button and wait till you get confirmation email about site published.
  Step-7: Repeat the above steps from 3 to 6 for phocsportal as well.

  PDT's for PHOCS site publish
  Step-1: Open the target salesforce instance.
  Step-2: Click on the gear icon and select setup.
  Step-3: Search for 'All Sites' and then select builder for phocsservices.
  Step-4: Select the "Settings" Icon on Home Page - on left top Corner.
  Step-5: Again Click on "phocsservices Profile" hyperlink under the Guest User Profile.Step-6: Click on "Assigned Users" button and wait and select the "Site Guest User, phocsservices".
  Step-7: Assign the "PHOCS Services Guest User PSG" Permission Set Group to the user.

[x] EHIS-2565 - PR-1796 download lastest file from qa and upload in UAT
- compared all templates in qa and uat found differences for these templates and uploaded below
- Construction Permit for Water Supply System
- Pool Construction Permit
- Drinking Water System Operating Permit
- Food Premise Operating Permit
- PHOCSChildcareLicenseTemplate
- Residential Care License Template
- Sewerage Holding Tank construction permit
- Sewerage System
- Temporary Food Premise Operating Permit

> DataLoading

[x] EHIS-2810

- Create Regulatory Authority and Regulatory Authorization record in all sandboxes

1. go to app launcher , search for regulatory authority - select phocs regulatory authority RT - create record with name “BCCDC”
2. Regulatory Authorization Type record create using the “PHOCS Regulatory Authorization Type” record type:
Name -Regulatory Authorization Category
Issuing Department (Regulatory Authority)-BCCDC Dairy Plant License
License-BCCDC

3.A new Regulatory Authorization Type record is created using the “PHOCS Regulatory Authorization Type” record type:
Name - Regulatory Authorization Category
Issuing Department (Regulatory Authority)-BCCDC Dairy Worker Licence
License-BCCDC

[x] EHIS-2894

- Object: BusinessLicenseApplication
- List view API name: MyApplicationsPHOCS
- Note: 
  1. the above list view may or may not exist in lower environment. If it exists, please do destructive deployment to delete it.
  2. The above list view does NOT exist on DEV main branch.
  3. There is another list view with same label name (API: PHOCSMyApplications). Please keep it as-is and do NOT delete it.

[X] EHIS-2631 Create work area records
- Work Area Name: BCCDC Dairy Work Area 1
  Health Authority: blank
  Primary Owner: blank
  Supervisor: blank
  Backup Owner: blank
  Work Area Name: BCCDC Dairy Work Area 2
  Health Authority: blank
  Primary Owner: blank
  Supervisor: blank
  Backup Owner: blank

[x] EHIS-2889 Follow Jira to perform the step
- Follow the Instructions Provided in the attachment “EHIS-2617.xlsx” to Insert data to Products object.

[x] EHIS-2943 follow jira for steps
[x] EHIS-2974 follow jira for steps
[x] EHIS-2969 follow jira for steps

> Verification Steps 

[x] EHIS-2258 
- Go to Quick find →All Sites → click on Builder for phocsservices → click on Blue menu tab present in top left corner (refer screenshot_--->Click on Administration -- > click on emai section --> provide David user meail in Sender Email Address.

- [ ] EHIS-2535 verify in UAT