|Sandbox|`Post refresh runbook till SP-16 " UAT ORG "for March 2026 release UAT`|
|-|-|
|Runbook Created|`2025-12-12`|
|Runbook Last Modified|`2025-12-12`|

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

2. [ ] Checkout to `latest`code 

## Assumptions

1. Total execution time ~ > 3hrs 

## Open Items

## Pre-Deployment Steps (20 mins)

[ ] 1. EHIS-2530
- Include changes in salesforcebackupadmininstratorbackup.ps copy from BCMOHAD-28583-Release-1.14.0.8 branch in the current deployment branch for UAT

[ ] 3. Delete ReasonForAdvisory__c Single Picklist (old field) for case object

[ ] 4.EHIS-2592 follow jira for the components
- Please do the destructive changes deployment. I have attached the zip file

[ ] 5.Destructive deployment -

1. Action Plan Template path  - "src\main\default\actionPlanTemplates\Application_Document_Checklist_Updated_Vers_7ed25cd9_b55f_11ee_baf3_8b08e788e277.apt-meta.xml"

> sf project deploy start -o deployment.user@phocs.uat.com --manifest "destructive/destructive-post-refresh/package.xml" --post-destructive-changes "destructive/destructive-post-refresh/destructiveChanges.xml" --wait 10


## Deployment Steps (20 mins)

1. [hold on ] EHIS-1707 - Deploy Decision Matrix (5 min)
 
> sf project deploy start --source-dir src-bre\main\default\PhocsdecisionMatrixDefinition --wait 30 --target-org deployment.user@phocs.uat.com

> sf project deploy start --source-dir src-bre\main\default\decisionMatrixDefinition\Action_Plan_Template_Decision_Matrix.decisionMatrixDefinition-meta.xml --wait 30 --target-org deployment.user@phocs.uat.com

2. [ ] Deploy ActionPlanTemplates

> sf project deploy start --source-dir bcgov-source/app-phocs/main/default/actionPlanTemplates --wait 30 --target-org deployment.user@phocs.uat.com

> sf project deploy start --source-dir ActionPlanTemplates-Phocs/main/default --wait 30 --target-org deployment.user@phocs.uat.com

3. [ ] Deploy Omni studio components 

> sf project deploy start --source-dir bcgov-source\app-alr\main\default\omniDataTransforms --source-dir bcgov-source\app-alr\main\default\omniUiCard --source-dir bcgov-source\app-alr\main\default\omniIntegrationProcedures --source-dir bcgov-source\app-alr\main\default\omniScripts --source-dir bcgov-source/app-phocs/main/default/omniDataTransforms --source-dir bcgov-source\app-phocs\main\default\omniIntegrationProcedures --source-dir bcgov-source\app-phocs\main\default\omniUiCard --source-dir bcgov-source/app-phocs/main/default/omniScripts --source-dir bcgov-source/core/main/default/omniDataTransforms --source-dir bcgov-source/core/main/default/omniScripts --target-org deployment.user@phocs.uat.com

4.[ ]  Deploy full repository (~20 min)
    1. [ ] Verify folders
      |Folder|Path|
      |-|-|
      |'bcgov-source/core/main/default,bcgov-source/app-phocs/main/default`|

> sf project deploy start --source-dir bcgov-source/core/main/default --source-dir bcgov-source/app-phocs/main/default --target-org deployment.user@phocs.uat.com --test-level RunLocalTests

> move Accountaccount sharing rules that moved to temp to Phocs sharing rules folder and deploy to UAT

## Post-Deployment Steps (30 mins)

[ ]  Update Sharing on PHOCS Action Plan Template

   1. App Launcher -> Action Plan Templates -> **navigate** to `all Phocs action plan templates` record

   [ ] - As part of post deployment steps, after the deployment of “Action plan templates“, the status of this template is ‘Read only’, it's not visible to the users while adding a template on Action plan creation.
   -So please do the following steps to activate the template, 
   -Note: Login as Phocs system admin user should have only phocs Permissions assigned
   -Step 1: Clone the existing Templates
   -Step 2: After cloning the Original Action Plan Template
   Before Publishing the template in the items section of Document checklist items 
   -Step 3: **Add** Sharing 

      |Item Type|Item Name|Access Level|
      |-|-|-|
      |Public Group|` EHISUsersPG`|Read/Write|
      |Public Group|`PHOCS Reporting User PG`|Read Only|

   3. Click **Save**

6.[ ] EHIS-2565 - PR-1796 download lastest file from qa and upload in UAT
- Import PHOCSReceiptTemplate in the target org .  (ST,QA,UAT & PROD) Save Template details and Activate 
- compare all templates in qa and uat nd upload

8.[?] EHIS-2194
- Post PD Step to perform - create a contact
 2. Create an account with BE RT
 3. Assign role to contact owner 
 4. switch to classic and open contact and enable for experience user ,now it will direct to create user - create a user with customer community operator
 4. go to potal - click on workspace - administration - memebers - add potal profile and ps 
- Profile - Custom Community Operator.
- Permission set - PHOCS Operator User CRE PS.

- [?] EHIS-2535 verify in UAT

- [?] EHIS-2735

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

> DataLoading

[?] EHIS-2432 Follow Jira to Load the data into LabTestMasterList__c object. 

Assign the corresponding recordtype and load the data.
1. Query below and map the fields along with recordtypeId for radon, dye, food, water  in excel and load the data and verify the data with below query
select Id , TestCategory__c, SampleTestType__c, ParameterType__c, PhysicalQuantity__c, RecordType.name , UnitOfMeasure__c, Name , CreatedBy.Name from LabTestMasterList__c 

[?] EHIS-2810

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

[?] EHIS-2865

- Upload Action plan template
  MOH-ALR\ActionPlanTemplates-Phocs\main\default\ BCCDC_Dairy_Checklist_13e2c7f5_c56a_11f0_8a33_9524194c70a3.apt-meta
- Share the action plan template to 
- PHOCS Business Admin & Officer PG - Public Group - Read/Write
- PHOCS Reporting User PG -Public Group - Read
- Update Decision Metrics

Upload Decision Matrix
- Click App Launcher, search “Business Rules Engine”
- Select Lookup Tables tab, find “PHOCS Document Checklists Decision Matrix” record
- Select the latest version in Related list
- Click “Upload PHOCS Document Checklists V1_2025-11-26 14_05_31 CSV File” to upload attached file 

[x] EHIS-2894

- Object: BusinessLicenseApplication
- List view API name: MyApplicationsPHOCS
- Note: 
  1. the above list view may or may not exist in lower environment. If it exists, please do destructive deployment to delete it.
  2. The above list view does NOT exist on DEV main branch.
  3. There is another list view with same label name (API: PHOCSMyApplications). Please keep it as-is and do NOT delete it.

[?] EHIS-2889 Follow Jira to perform the step
- Follow the Instructions Provided in the attachment “EHIS-2617.xlsx” to Insert data to Products object.

[ ] EHIS-2943 follow jira for steps
[ ] EHIS-2974 follow jira for steps
[ ] EHIS-2969 follow jira for steps

> Verification Steps 

[ ] EHIS-2258 
- Go to Quick find →All Sites → click on Builder for phocsservices → click on Blue menu tab present in top left corner (refer screenshot_--->Click on Administration -- > click on emai section --> provide David user meail in Sender Email Address.








		
