# Post refresh Deployment Runbook

|Sandbox|`Post refresh runbook for EHIS-SP1 " QA ORG "`|
|-|-|
|Runbook Created|`2024-06-17`|
|Runbook Last Modified|`2024-06-17`|

## Pre-Requisites [5 min ]

1. [x] Deployment User has assigned Permission Sets

   1.EHIS ALR Data Migration PS
   2.EHIS Enable MFA PS
   3.Action Plans PS
   4.Document checklist PS
   5.DocGen Designer PS
   6.ALR All Users PG
   7.ALR Data Analyst Users PG
   8.Business Milestones and Life Events Access PS

2. [x] Checkout to `QA.322` code 

## Assumptions

1. Total execution time ~ > 3 hrs

## Open Items

## Pre-Deployment Steps (1-2 hrs)

1. [X] Set Email Deliverability to `All Email` (1 min)
   1. Setup -> Email -> Deliverability -> Update **Access Level** dropdown to `All Email` -> click **Save**

2. [x] EHIS - 1153
> Log in as System Administrator - Click on gear icon and open setup
> In the Quick find type Group Membership settings and open it
> Enable Create and manage households and groups
> This needs to be done in all the higher orgs else deployment will fail

3. [x] EHIS-1263

- Go to Setup → User Interface → Enable “Use custom address fields“. → Save.

4. [x] ALR -1646 

- Setup->Quick Find-> Organization-Wide Addresses- Change Display Name from Test to ALR Support Email
For Org Wide Addresses: Setup->Search : Organization-Wide Addresses-> Select-> Add
    > Provide the below details:
      Display Name:Change Display Name to ALR Support Email
    > Email Address: hlth.assistedlivingregistry.test@hlthpss.gov.bc.ca
    > Select - Allow All Profiles to Use this From Address ->Save

5. [X] ALR-818 creating Auth Provider and also search for Identity verification and check enable MFA option

6. [x] Fix the OmniStudio package omnistudio:DML currently not allowed error (1 min)

- Switch to Classic Mode. Click on the + sign from the Tab Panel. Search Documents.
- Go to Documents.
- In the Document folders section, click the dropdown list and select Vlocity Document Uploads
- Click New Document.
- Name and Unique Name = VlocityLogoDocumentUploads.
- Attach the sample file [any image file will do] and click Save

7. [x] Delete DecisionMatrix versions , DecisionMatrix Definitions
      - Query and delete 
      > select Id , DeveloperName from DecisionMatrixDefinitionVersion 
      > select Id , DeveloperName from DecisionMatrixDefinition 

> while deleting decision matrix definitions getting error
delete the flow
> InspectionAssessmentTaskCreation and deploy it back during deployment

7.[x] Destructive deployment - Delete Action Plan Template

> sfdx force:source:deploy --manifest "destructive\destructive-post-refresh\package.xml" --postdestructivechanges "destructive\destructive-post-refresh\destructiveChanges.xml" -w 30 --targetusername  gandloju.vishwantha@accenture.com.alr.qa

8. [x] Data Loading ALR-1180, ALR-1123 

- 1. ALR-1180 Please deploy these Login as Data Analyst and create data in the order as mentioned below

1.Regulatory Authority
2.Regulatory Authorization Type
3.Regulatory Code
4.Assessment Indicator Definition
5.Regulatory Code Assessment Indicator
6.Assessment Task Definition
7.Assessment Task Indicator Definition
8.Inspection Type

- sfdx sfdmu:run --path "Omnistudio\data" --sourceusername csvfile --targetusername gandloju.vishwantha@accenture.com.alr.qa

- 2. [x] ALR-1123 After creating data for above objects verify ALR-1123, if not linked excecute it manually  

- 3. [x] Create Action plan templates from Jira ALR-1268

- Load action plan templates through Work bench 
- Now perform ALR-1268 LINK Assessment task definition to Action plan template Item

## Deployment Steps (20 mins)

1. [x] Deploy Decision Matrix (5 min)
   - Deploy decisionMatrixDefinition folder
   > sfdx force:source:deploy --sourcepath "src-bre\main\default\decisionMatrixDefinition" --wait 30 --targetusername gandloju.vishwantha@accenture.com.alr.qa

> [ALR-1250] App launcher → Business Rules Engine → Lookup Table Navigation Tab
   > Open one by one below matrix:
      - Action Plan Template Decision Matrix
      - Risk Score Decision Matrix
      - Assigned Score Decision Matrix
      - Total Compliance Score Decision Matrix
   > Open - Open the Matrix version - edit - uncheck the Active checkbox - >  Upload the csv for the required decision matrix -> activate the template again 

2. [x] Deploy OmniStudio components and its dependencies (5 min)
   > sfdx force:source:deploy --sourcepath "src\main\default\omniDataTransforms,src\main\default\omniIntegrationProcedures,src\main\default\omniUiCard,src\main\default\omniScripts" --wait 30 --targetusername gandloju.vishwantha@accenture.com.alr.qa

3. [x]  Deploy full repository (~20 min)
   1. [x] Verify folders
      |Folder|Path|
      |-|-|
      |`src`|`src\main\default`|
      |`src-access-mgmt`|`src-access-mgmt\main\default`|
      |`src-ui`|`src-ui\main\default`|
      |'Ehis-source'|
   
   2. [x] Deploy
   
    1. sfdx force:source:deploy --sourcepath "ehis-source,src\main\default,src-access-mgmt\main\default,src-ui\main\default" --wait 30 --targetusername gandloju.vishwantha@accenture.com.alr.qa -l RunLocalTests

    2. Deploy custom metadata env specific folder 

    > sfdx force:source:deploy --sourcepath 
    "src-env-specific\qa\main\default\customMetadata" --wait 30 --targetusername gandloju.vishwantha@accenture.com.alr.qa

   3. [x] Re-activate Omnistudio components
      1. App Launcher -> OmniStudio -> Omnistudio **Integration Procedures**
      2. Locate all active custom **Integration Procedures** -> deactivate them -> activate them back.
      3. App Launcher -> OmniStudio -> **Omnistudio FlexCards**
      4. Locate all active custom **FlexCards** -> open each FlexCard -> deactivate -> activate back.
      5. App Launcher -> OmniStudio -> **OmniScripts**
      6. Locate all active custom **OmniScripts** -> open each omni script -> deactivate -> activate back

   4. [x] ALR-1199 Go to Omniscript “RiskAssessment“ → Open active version → Click on dropdown and select “Select Deploy Standard Runtime Compatible LWC “ → Done.

## Post-Deployment Steps (30 mins)

1.[x] ALR-792 Residence ID will be starting at 000XX
    1. Go to Object Manager and select the Account object
    2. Click Fields & Relationships, select the UniqueAccountNumber__c field, then click Edit
    3. Click Change Field Type. Select 'Text' for the Data Type, then click Next - > Click Save on the next screen.
    4. Repeat Step 2–4. For step 3, select 'Auto-Number' for the Data Type.
    5. Set the Start Number as 10000

2. [x] 1. Import Templates:
      - App Launcher -> Document Template Designer
      - Select import on right top and First Import all Json files 

      - [x] ALR-1540 Download below templates from JIRA
         - App launcher-> Document template designer ->Import Jsonfile->deactivate-> replace file->select ppt (from below ppt)->save ->activate-> Save template 
         |`CertificateTemplateSU`|
         |`CertificateTemplateMH`|
         |`CertificateTemplateSN`|

      - [x] ALR-1014 Download below templates from JIRA
         - App launcher-> Document template designer ->Import Jsonfile ->deactivate-> replace file->select Word doc->save ->activate->Save template.
         |`InvoiceTemplate`|
         |'RenewalReceiptTemplate'|
         |'UnitReceiptTemplate'|
         |'ApplicationFeeTemplate'|
         |'RenewalInvoiceTemplate'|
         |'RenewalInvoice_Templates'|

      - [x] ALR-932 Download only 2 templates from this Jira
         - App launcher-> Document template designer ->Import Jsonfile ->deactivate-> replace file->select Word doc->save ->activate->Save template.
        |`ReceiptTemplate`|
        |`RenewalApplicationForm`|

      - [x] ALR-899 Download below templates from JIRA
         - App launcher-> Document template designer ->Import Jsonfile ->deactivate-> replace file->select Word doc->save ->activate->Save template.
        |'GenerateInspectionPlan'|

      - [x] ALR-1018 Download below templates from JIRA
         - App launcher-> Document template designer ->Import Jsonfile ->deactivate-> replace file->select Word doc->save ->activate->Save template.
        |'LateFeeTemplate'|

      - [x] ALR-1085 
        - After importing above template -> clone the LateFeeTemplate-> Rename the Template name to “LateFee_Template“ → Copy should be removed from DR’s mentioned in the template →download word doc from ALR-1085  replace file->select word doc (from below word doc)->save ->activate->Save template
        |LateFee_Template|

      - [x] ALR- 1178 
      - App launcher-> Document template designer ->Import Jsonfile ->deactivate-> replace   file->select Word doc->save ->activate->Save template.
        |'InspectionReport'|
      - When uploading Json file if it fails to upload, clone the RenewalReceiptTemplate and change the name and data raptor as per the screen shot in JIRA


      - If Facing any errors while Importing template Follow the below steps:
      Clone the RenewalReceiptTemplate or invoice template and change the name and dataraptor  as per the screen shot in JIRA
      - Navigate to classic mode - check for content - search for private library - > if template are available in private library, please move it to docgenDocumentTemplate Library

3.[x] Update Sharing on Action Plan Template `Application Document Checklist template` record (1 min) ALR-793 ,853, 948

   1. App Launcher -> Action Plan Templates -> **navigate** to `Application Document Checklist template` record

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


5. [ ] ALR-1073,1102 This step needs to be done after creating Admin person in ORG

6. [ ] ALR-1206,ALR-1387,1386,1577 - This step to be performed after creating all users

DevOps checklist:

1. Make sure you activated the all docugen templates 
2. Validate the flows in org with Repo make sure active/inactive versions in branch which are deployed by devops should match in org
3. Check reports and dashboards users access
4. Email templates access
5. Decision matrix data uploaded, activated back
6. deploy env specific folder for alr.org specific 