## Post refresh Deployment Runbook

|Sandbox|`Post refresh runbook for EHISdev " SP-2"|
|-|-|
|Runbook Created|`2024-7-01`|
|Runbook Last Modified|`2024-7-01`|

## Pre-Requisites [5 min ]

1. [x] Deployment User has assigned Permission Sets

   1.EHIS Data Migration PS
   2.EHIS Enable MFA PS
   3.Action Plans PS
   4.Document checklist PS
   5.DocGen Designer PS
   6.ALR All Users PG
   7.ALR Data Analyst Users PG
   8.Business Milestones and Life Events Access PS

2. [x] Checkout to `dev` code 

## Assumptions

1. Total execution time ~ > 3 hrs

## Open Items

## Pre-Deployment Steps (1-2 hrs)

1.[x] EHIS - 1153 , 1263

- [x] Setup -> Email -> Deliverability -> Update **Access Level** dropdown to `All Email` -> click **Save**
- [x] Setup → User Interface → Enable “Use custom address fields“. → Save.

2.[x] ALR -1646 Add OWD email address and display name

- Setup -> Organization-Wide Addresses- Change Display Name from Test to ALR Support Email
   > Provide the below details:
   1. Display Name:Change Display Name to ALR Support Email
   2. Email Address: hlth.assistedlivingregistry.test@hlthpss.gov.bc.ca
   3. Select - Allow All Profiles to Use this From Address ->Save

3.[x] ALR-818 creating Auth Provider and also search for Identity verification and check enable MFA option

4.[x] Fix the OmniStudio package omnistudio:DML currently not allowed error (1 min)

- Switch to Classic Mode. Click on the + sign from the Tab Panel. Search Documents.
- Go to Documents.
- In the Document folders section, click the dropdown list and select Vlocity Document Uploads
- Click New Document.
- Name and Unique Name = VlocityLogoDocumentUploads.
- Attach the sample file [any image file will do] and click Save

5.[x] EHIS-1291 

- Go to Setup → Permission Set Group → Open below mentioned PSGs → Select permission set → Remove Permission Set → Done.
    1 . Delete "EHIS_CRE_Group_Membership_PS" permission set from the "EHIS_Water_Business_Admin_PSG" 
    2. "EHIS_Read_Group_Membership_PS" permission set from "EHIS_Water_Public_Health_Engineer_PSG,EHIS_Water_Officer_PSG"

6. [x] ALR-1688
   1. Go to app launcher
   2. Select Salesforce Inspector->Data Export->Execute the below Query.
      Select  FolderId from EmailTemplate where Name ='Renewal Late Fee Notification Letter'
   3. Copy the FolderId of Name “Renewal Late Fee Notification Letter” from the export.
   4. Replace the folderId Column in Email Template-upcoming Renewal.csv for 1 column to the copied Id from data export->Save the file
   5. Select Salesforce Inspector->Data Import.-Select the below:
      Action->Insert
   6. Object->Email Template , Copy and paste the content in Data Space and Import."

7. [x] ALR-1710
"1.Go to SetUp->Search Deployment Settings->Enable “Allow deployments of components when corresponding Apex jobs are pending or in progress.
Caution: Enabling this option may cause Apex jobs to fail.” in Deployment Option
->Save" 

8.[x] Destructive deployment -

1. Delete Physical_address__c from all the orgs.
2. Delete EHIS_CRE_Group_Membership_PS ,EHIS_Read_Group_Membership_PS
3. Action Plan Template

> sfdx force:source:deploy --manifest "destructive\destructive-post-refresh\package.xml" --postdestructivechanges "destructive\destructive-post-refresh\destructiveChanges.xml" -w 30 --targetusername gandloju.vishwantha@accenture.com.ehis.dev

9.[x] Data Loading ALR-1180, ALR-1123

1.Regulatory Authority
2.Regulatory Authorization Type
3.Regulatory Code
4.Assessment Indicator Definition
5.Regulatory Code Assessment Indicator
6.Assessment Task Definition
7.Assessment Task Indicator Definition
8.Inspection Type

- 2. [x] ALR-1123 After creating data for above objects verify ALR-1123, if not linked excecute it manually  

- 3. [x] Create Action plan templates from Jira ALR-1268

- Load action plan templates through Work bench 
- Now perform ALR-1268 LINK Assessment task definition to Action plan template Item

10.[x] Delete DecisionMatrix versions , DecisionMatrix Definitions
   -Query and delete
      > select Id , DeveloperName from DecisionMatrixDefinitionVersion 
      > select Id , DeveloperName from DecisionMatrixDefinition 

> while deleting decision matrix definitions it will through error
delete the flow
> InspectionAssessmentTaskCreation and deploy it back during deployment

## Deployment Steps (20 mins)

1. [x] Deploy Decision Matrix (5 min)
   - Deploy decisionMatrixDefinition folder
   > sfdx force:source:deploy --sourcepath "src-bre\main\default\decisionMatrixDefinition" --wait 30 --targetusername gandloju.vishwantha@accenture.com.ehis.dev

> [ALR-1250] App launcher → Business Rules Engine → Lookup Table Navigation Tab
   > Open one by one below matrix:
      - Action Plan Template Decision Matrix
      - Risk Score Decision Matrix
      - Assigned Score Decision Matrix
      - Total Compliance Score Decision Matrix
   > Open - Open the Matrix version - edit - uncheck the Active checkbox - >  Upload the csv for the required decision matrix -> activate the template again 

2.[x] Deploy OmniStudio components and its dependencies (5 min)
   > sfdx force:source:deploy --sourcepath "ehis-source\core\main\default\omniScripts,ehis-source\core\main\default\omniDataTransforms,src\main\default\omniDataTransforms,src\main\default\omniIntegrationProcedures,src\main\default\omniUiCard,src\main\default\omniScripts" --wait 30 --targetusername gandloju.vishwantha@accenture.com.ehis.dev

3.[x]  Deploy full repository (~20 min)

> [x] Verify folders
      |Folder|Path|
      |-|-|
      |`src`|`src\main\default`|
      |`src-access-mgmt`|`src-access-mgmt\main\default`|
      |`src-ui`|`src-ui\main\default`|
      |'Ehis-source'|


> [x] Deploy

- sfdx force:source:deploy --sourcepath "ehis-source\app-programworkareaassignment\main\default,ehis-source\app-segmentationterritories\main\default,ehis-source\core\main\default,ehis-source\ehis-access-mgmt\main\default,ehis-source\ehis-ui\main\default,src\main\default,src-access-mgmt\main\default,src-ui\main\default" --wait 30 --targetusername gandloju.vishwantha@accenture.com.ehis.dev -l RunLocalTests

> [x] Deploy custom metadata env specific folder - This step is not required to DevOps org

- sfdx force:source:deploy --sourcepath 
"src-env-specific\devops\main\default\customMetadata" --wait 30 --targetusername gandloju.vishwantha@accenture.com.alr.dev

>[x] Re-activate Omnistudio components
      1. App Launcher -> OmniStudio -> Omnistudio **Integration Procedures**
      2. Locate all active custom **Integration Procedures** -> deactivate them -> activate them back.
      3. App Launcher -> Omniflexcards -> **Omnistudio FlexCards**
      4. Locate all active custom **FlexCards** -> open each FlexCard -> deactivate -> activate back.
      5. App Launcher -> OmniStudio -> **OmniScripts**
      6. Locate all active custom **OmniScripts** -> open each omni script -> deactivate -> activate back

4.[x] ALR-1199 Go to Omniscript “RiskAssessment“ → Open active version → Click on dropdown and select “Select Deploy Standard Runtime Compatible LWC “ → Done.

## Post-Deployment Steps (30 mins)

1.[x] ALR-792 Residence ID will be starting at 000XX
    1. Go to Object Manager and select the Account object
    2. Click Fields & Relationships, select the UniqueAccountNumber__c field, then click Edit
    3. Click Change Field Type. Select 'Text' for the Data Type, then click Next - > Click Save on the next screen.
    4. Repeat Step 2–4. For step 3, select 'Auto-Number' for the Data Type.
    5. Set the Start Number as 10000

2. [x] 1. Import Templates: ALR-1540,1014,932,899,1018,1085,1178
      - App Launcher -> OMNISTUDIO - Document Template Designer
      - Select import on right top and First Import all Json files 

         - App launcher-> OMNISTUDIO -> Document template designer ->Import Jsonfile->deactivate-> replace file->select ppt (from below ppt)->save ->activate-> Save template 
         |`CertificateTemplateSU`|
         |`CertificateTemplateMH`|
         |`CertificateTemplateSN`|

         - App launcher->OMNISTUDIO -> Document template designer ->Import Jsonfile ->deactivate-> replace file->select Word doc->save ->activate->Save template.
         |`InvoiceTemplate`|
         |'RenewalReceiptTemplate'|
         |'UnitReceiptTemplate'|
         |'ApplicationFeeTemplate'|
         |'RenewalInvoiceTemplate'|
         |'RenewalInvoice_Templates'|
         |`ReceiptTemplate`|
         |`RenewalApplicationForm`|
         |'GenerateInspectionPlan'|
         |'LateFeeTemplate'|
         |LateFee_Template|
         |'InspectionReport'|

3.[x] Update Sharing on Action Plan Template `Application Document Checklist template` record (1 min) ALR-793 ,853, 948

   1. App Launcher -> Action Plan Templates -> **navigate** to `Application Document Checklist template updated version` record

   [x] ALR-793 - As part of post deployment steps, after the creation of “Application Document Checklist template“, the status of this template is ‘Read only’, it's not visible to the users while adding a template on Action plan creation.
   -So please do the following steps to activate the template, 
   -Note: Login as Data Analyst
   -Step 1: Clone the existing Template and edit the Name as  “Application Document Checklist Template" 
   -Step 2: After cloning the Original Action Plan Template
   Before Publishing the template in the items section of Document checklist items
   Click on reorder button present on the right side of the page and manually rearrange the items in the sorted order(01,02,03,04,05,….) and then publish it 
   -Step 3: **Add** Sharing 

      |Item Type|Item Name|Access Level|
      |-|-|-|
      |Public Group|`ALR Leadership Users PG`|Read/Write|
      |Public Group|`ALR Registrar Users PG`|Read/Write|
      |Public Group|`ALR Admin Users PG`|Read/Write|
      |Public Group|`ALR Data Analyst Users PG`|Read/Write|
      |Public Group|`ALR Investigator Users PG`|Read Only|

   3. Click **Save**

4. [x] EHIS-1282

- "Login as EHIS Admin User and create 2 records mentioned below:

a.  Steps: Go to Apps → Search Party Role Relationship → New → Mentioned below,Party Role Relationship Id = “Downstream-Upstream-AAR” (will be appear once it is created)

- Role Name = “Downstream”
- Relationship Object Name = “Account Account Relationship”
- Related Inverse Record = “Upstream-Downstream-AAR” (First create without adding this, then once second record created, edit and add the second record)
- Related Role Name = “Upstream”
- Create Inverse Role Automatically = Fasle (does not work for PSS)

b. Party Role Relationship Id = “Upstream-Downstream-AAR” (will be appear once it is created)

- Role Name = “Upstream”
- Relationship Object Name = “Account Account Relationship”
- Related Inverse Record = “Downstream-Upstream-AAR” (First create without adding this, then once above record created, edit and add the above record)
- Related Role Name = “Downstream”
- Create Inverse Role Automatically = Fasle (does not work for PSS)"

5 .[x] ALR-1681

- "STEP 1: Go to app launcher
- STEP 2: Select Salesforce Inspector->Data Export->Execute the below Query.
Select Id, Name, DeveloperName from EmailTemplate where name='Renewal Late Fee Notification Letter'
- STEP 3 : Copy the ID of Name “Renewal Late Fee Notification Letter” from the export.
- STEP 4 : Replace the ID Column in New Email Template-Dataload for 1 column to the copied Id from data export->Save the file
- STEP 5 : Select Salesforce Inspector ->Data Import->Action : Select Update->Object : EmailTemplate->Copy all the content from New Email Template-Subject-Dataload and paste in Data (Excel)->Import"

6. [x] ALR-1700
- Log in to Salesforce.
- Go to Setup->Search “Scheduled Jobs”->Scheduled Apex.
- Provide the below details:
  > Job Name->Trigger Email on March-15
- Apex Class-> search and select “ScheduledEmailTrigger”
  > Select Cron Expression->”0 0 0 15 3 ?”
- Save

7. [x] ALR-1701

- Log in to Salesforce.
- Go to Setup->Search “Scheduled Jobs”->Scheduled Apex.
- Provide the below details:
- Job Name->Trigger Email on Jan-15
- Apex Class-> search and select “ScheduleSendEmail” - Select Cron Expression->”0 0 0 15 1 ?” - Save

8. [x] ALR-1712
- Schedule Jobs1:
1.Log in to Salesforce.
2.Go to Setup->Search “Scheduled Jobs”->Scheduled Apex.
3.Provide the below details:
Job Name->AccountStatusUpdateOnApril
Apex Class-> search and select “AccountStatusUpdate”
Select Cron Expression->0 0 0 1 4 ?
4.Save

- Schedule Jobs 2:
1.Log in to Salesforce.
2.Go to Setup->Search “Scheduled Jobs”->Scheduled Apex.
3.Provide the below details:
Job Name->AccountStatusUpdateOnMay
Apex Class-> search and select “AccountStatusUpdateOnMay”
Select Cron Expression->0 0 0 1 5 ?
4.Save

9. [x] EHIS-1344

1. Login as System Administrator and click on setup icon
2. In Quick FInd section search for  State and Country/Territory Picklists
3. Open it and click on Configure States, Countries, and Territories
4. Change the Default Country/Territory to None "


6.[x] ALR-1073,1102 This step needs to be done after creating Admin person in ORG

7.[x] ALR-1206,ALR-1387,1386,1577 - This step to be performed after creating all users

DevOps checklist:

1. Make sure you activated the all docugen templates 
2. Validate the flows in org with Repo make sure active/inactive versions in branch which are deployed by devops should match in org
3. Email templates access and check body is present,html for templates 
4. Decision matrix data uploaded, activated back
5. deploy env specific folder for alr.org specific 
6. Ping Yen to send email to dawn to verify OWD