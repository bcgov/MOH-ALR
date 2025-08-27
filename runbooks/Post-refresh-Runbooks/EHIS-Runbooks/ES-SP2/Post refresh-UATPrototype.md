|Sandbox|`Post refresh runbook till SP-9 " UAT ORG " before prototype`|
|-|-|
|Runbook Created|`2025-08-26`|
|Runbook Last Modified|`2025-08-26`|

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

2. [x] Checkout to `phocs-sprint10`code 

## Assumptions

1. Total execution time ~ > 3hrs 

## Open Items

## Pre-Deployment Steps (20 mins)

[x] 1. EHIS-1668 , 2306
- Create new record type with name PHOCS Action Plan Template Record Type under Action plan template object

- Go to setup - object manager - Action Plan Template - record type 
  1. Name - PHOCS Action Plan Template
  2. Label - PHOCSActionPlanTemplate
  3. Description - Capture templates for PHOCS Action Plans

[x] 2. EHIS-2258 From setup -  search for Digital experiences - settings
- Enable Experience Workspaces
- Enable ExperienceBundle Metadata API

[x] 3.Delete below components
- Delete compact layout - Account.Water_Source_Intake_Layout , Account.Water_System_Layout , Asset.EHIS_Water_Storage_Compact_Layout , Asset.Water_Distribution
- Delete Flexipage -> EHIS_Water_Source_Intake_Record_Page , EHIS_Water_System_Record_Page , Asset.EHIS_Water_Storage_Record_Page1 , Asset.Water_Distribution_Record_Page
- Delete recordtype -> Account.Water_Source_Intake ,Account.Water_System,
                    AccountAccountRelation.EHIS_Facility_AAR
                    PartyRoleRelation.EHIS_PRR ,Asset.Water_Distribution ,Asset.Water_Storage , AAR.EHIS Water Source Intake AAR	
- Delete Layout-Asset-EHIS Water Distribution , EHIS Water Storage , Account.Watersourceintake, Account Watersystem

[x] 4.Destructive deployment -

1. Action Plan Template path  - "src\main\default\actionPlanTemplates\Application_Document_Checklist_Updated_Vers_7ed25cd9_b55f_11ee_baf3_8b08e788e277.apt-meta.xml"

> sf project deploy start -o deployment.user@phocs.uat.com --manifest "destructive/destructive-post-refresh/package.xml" --post-destructive-changes "destructive/destructive-post-refresh/destructiveChanges.xml" --wait 10

[x] 5.Delete DecisionMatrixversions , DecisionMatrixDefinitions
   -Query and delete
      > select Id , DeveloperName from DecisionMatrixDefinitionVersion 
      > select Id , DeveloperName from DecisionMatrixDefinition 
or delete manually ALR - DecisionMatrixDefinitions

> while deleting decision matrix definitions it will through error
delete the flow
> InspectionAssessmentTaskCreation and deploy it back during deployment

[x] 6.Create Action plan templates from Jira ALR-1268

- Load action plan templates through Work bench 
- Now perform ALR-1268 LINK Assessment task definition to Action plan template Item

[x] 7. Remove inactive users from water admin and water officer PSG
       move account account sharing rule to temp folder and deploy after full deployment

[x] 8. EHIS-2070

## Deployment Steps (20 mins)

1. [x] EHIS-1707 - Deploy Decision Matrix (5 min)
 
> sf project deploy start --source-dir src-bre\main\default\PhocsdecisionMatrixDefinition --wait 30 --target-org deployment.user@phocs.uat.com

> sf project deploy start --source-dir src-bre\main\default\decisionMatrixDefinition\Action_Plan_Template_Decision_Matrix.decisionMatrixDefinition-meta.xml --wait 30 --target-org deployment.user@phocs.uat.com

2. [x] Deploy ActionPlanTemplates

> sf project deploy start --source-dir bcgov-source/app-phocs/main/default/actionPlanTemplates --wait 30 --target-org deployment.user@phocs.uat.com

> sf project deploy start --source-dir ActionPlanTemplates-Phocs/main/default --wait 30 --target-org deployment.user@phocs.uat.com

3. [x] Deploy Omni studio components 

> sf project deploy start --source-dir bcgov-source/app-phocs/main/default/omniDataTransforms --source-dir bcgov-source/core/main/default/omniDataTransforms --target-org deployment.user@phocs.uat.com

> sf project deploy start --source-dir bcgov-source\app-alr\main\default\omniDataTransforms --wait 30 --target-org deployment.user@phocs.uat.com

>sf project deploy start --source-dir bcgov-source\app-alr\main\default\omniUiCard --target-org deployment.user@phocs.uat.com

>sf project deploy start --source-dir bcgov-source/app-phocs/main/default/omniScripts --source-dir bcgov-source/core/main/default/omniScripts --target-org deployment.user@phocs.uat.com

4.[x]  Deploy full repository (~20 min)
    1. [ ] Verify folders
      |Folder|Path|
      |-|-|
      |'bcgov-source/core/main/default,bcgov-source/app-phocs/main/default`|

> sf project deploy start --source-dir bcgov-source/core/main/default --source-dir bcgov-source/app-phocs/main/default --target-org deployment.user@phocs.uat.com --test-level RunLocalTests

> move Accountaccount sharing rules that moved to temp to Phocs sharing rules folder and deploy to UAT

## Post-Deployment Steps (30 mins)

[x] EHIS-1701 , EHIS-2116 Update Sharing on PHOCS Action Plan Template

   1. App Launcher -> Action Plan Templates -> **navigate** to `all Phocs action plan templates` record

   [x] - As part of post deployment steps, after the deployment of “Action plan templates“, the status of this template is ‘Read only’, it's not visible to the users while adding a template on Action plan creation.
   -So please do the following steps to activate the template, 
   -Note: Login as Phocs system admin user should have only Permissions assigned
   -Step 1: Clone the existing Templates
   -Step 2: After cloning the Original Action Plan Template
   Before Publishing the template in the items section of Document checklist items 
   -Step 3: **Add** Sharing 

      |Item Type|Item Name|Access Level|
      |-|-|-|
      |Public Group|` EHISUsersPG`|Read/Write|
      |Public Group|`PHOCS Reporting User PG`|Read Only|

   3. Click **Save**

2. [x] EHIS-2070 - Sharing list view with Phocs users

3. [x] EHIS-1622 , 1725 , 2221
   - Click App Launcher, search “Business Rules Engine”
   - Select Lookup Tables tab, find “PHOCS Document Checklists Decision Matrix” record
   - Select Lookup Tables tab, find “PHOCS Inspection Action Plan Template Decision Matrix”
   - Select Lookup Table tab, find "PHOCS Document Checklist Exemption " 
   - Select the latest version in Related list ,Click “Upload CSV File” to upload attached file 

4. [x] EHIS-2079

- Login with admin user and add below buttons in home tab
- similarly perform same step for Officer user and all reporting persona users 
  Fraser, interior, vancover, northern , vancover coastal
- Home
  Accounts
  Contacts
  Business License Applications
  Business License
  Public Complaint
  Cases
  Reports
  Dashboards
  Interaction Summaries

5.[x] EHIS-2089
- navigate to visited party object - go to list view - phocs visited party - open list view with fields contacts, visits - and delete this list view - redeploy the listview from branch
  
6.[x] EHIS-2098 , 2111 ,2292,2293,2125,2124,1968 - total 18 templates
- Import PHOCSInvoiceTemplate and PHOCSReceiptTemplate in the target org .  (ST,QA,UAT & PROD) Save Template details and Activate 
- Import PHOCSWaterBacteriologyRequisition.json ,PHOCS Water Bacteriology Requisition Template_V0.1.docx
- Import PHOCSFoodSafetyRequisition.json,PHOCS Food safety Requisition Template_V1.docx,

7.[x] EHIA-2134
- Setup, in the Quick Find box, enter Document Generation, and then select Custom Fonts Configuration.
- To transfer your fonts from Static Resources to the centralized Docgen Custom Fonts Library, click Migrate.
- From Setup, in the Quick Find box, enter Document Generation, and then select Custom Fonts Configuration.
- To synchronize all font updates, additions, or deletions and to ensure they’re available for document generation, click Sync.

8.[x] EHIS-2194
- Add following five Public Groups need to be added into “PHOCS Reporting User PG” 
- EHIS FHA Reporting User
- EHIS IHA Reporting User
- EHIS NHA Reporting User
- EHIS VCH Reporting User
- EHIS VCIS Reporting User

- [ ] EHIS-2104

> DataLoading

[x] EHIS-1621: Create 7 Inspection Type records

- Retrieve RecordTypeId of PHOCSInspectionType in the Salesforce instance
- Copy RecordTypeId into CSV file, Column B
- Upload the CSV file   into Data Loader (Insert) and do the 
- field mapping: 
  - Name: Name
  - RecordType: RecordTypeId

[x] EHIS-1708 , 2212

- Insert Regulatory Authority Records
- go to salesforce Inspector or dataloader.io
- salesforce inspector - data import - select object regulatory authority - Insert excel - download the results or copy the RA Id’s
-  Copy  Regulatory Authority Id and map in Regulatoty Authorization type excel as per regulatory authorization code map it in issuing department (paste RA id’s as per regulatory authorization code  )column 
- go to salesforce Inspector or Home , salesforce inspector - data import - select object regulatory authorization type - Insert excel - download the results or copy the RA Id’s

[x] EHIS-1713

[x] EHIS-1861
- Give Viewer access to EHIS PHOCS Users PG Group .   Switch to Classic - > Goto libraries → Select  DocgenDocumentTemplateLibrary   → Select Add memebers to give access.
- Upload  All PHOCS Doc Gen templates from phocs-DocgenTemplates Folder . 
- After uploading go to Document template designer - > Select imported doc gen template → replace latest word file → save template details → Activate 

[x] EHIS-2432


[x] EHIS-1967 create 5 test users


> Verification Steps 

[x] EHIS-1613
- Go To EHIS Standard User Profile -> object setting --> Account Account Relation -->  provide access to record type - Facility Linkage and make it default.

[x] EHIS-1786
- Login as System Admin ,Navigate to Inspection, All list view,Select All, delete one duplicate

[x] EHIS-1815
- Navigate to app launcher - search for regulatory authorization type object - select the list view with last modified date - go to list view filter - select the list view and delete

[x] EHIS-2258 
- Go to Quick find →All Sites → click on Builder for phocsservices → click on Blue menu tab present in top left corner (refer screenshot_--->Click on Administration -- > click on emai section --> provide David user meail in Sender Email Address.








		
