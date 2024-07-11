# Post refresh Deployment Runbook

|Sandbox|`Updated-ALR-SP9`|
|-|-|This runbook is updated with ALR-SP9 deployment to EHISDev org
|Runbook Created|`2024-05-28`|
|Runbook Last Modified|`2024-05-29`|

## Pre-Requisites [5 min ]

1. [x] Deployment User has assigned Permission Sets

   1.EHIS ALR Data Migration PS
   2.EHIS Enable MFA PS
   3.Action Plans PS
   4.Document checklist PS
   5.DocGen Designer PS
   6.ALR All Users PG
   7.ALR Data Analyst Users PG

2. [x] Checkout to `dev` code 

## Assumptions

1. Total execution time ~ > 3 hrs

## Open Items

## Pre-Deployment Steps (3 mins)

## Pre-Deployment Steps (1-2 hrs)

1. [x] Set Email Deliverability to `All Email` (1 min)
   1. Setup -> Email -> Deliverability -> Update **Access Level** dropdown to `All Email` -> click **Save**

3. [x] ALR-818 creating Auth Provider 

4. [x] Delete Action Plan Template,DecisionMatrix Definitions,DecisionMatrix versions

> while deleting decision matrix definitions getting error
delete the flows 
1.InspectionAssessmentTaskCreation
2.Get_Action_Plan_Template_Name flows with same name delete both flows ,make sure they should be as per branch 

   1. Destructive deployment

   > sfdx force:source:deploy --manifest "destructive\destructive-post-refresh\package.xml" --postdestructivechanges "destructive\destructive-post-refresh\destructiveChanges.xml" -w 30 --targetusername gandloju.vishwantha@accenture.com.ehis.dev


5. [x] Data Loading ALR-1180, ALR-1123 

1. ALR-1180 Please deploy these Login as Data Analyst and create data in the order as mentioned below

1.Regulatory Authority
2.Regulatory Authorization Type
3.Regulatory Code
4.Assessment Indicator Definition
5.Regulatory Code Assessment Indicator
6.Assessment Task Definition
7.Assessment Task Indicator Definition
8.Inspection Type

2. [x] ALR-1123 After creating data for above objects verify ALR-1123 is not excecute it manually  

3. [x] Create Action plan templates from Jira ALR-1268

[x] ALR-1567 destructive deployment

- Deleting validation rule - go to Setup-->Object Manager-->Inspection object-->validation rule-->RestrictingFieldsEditForVisitRule--> click on dropdown and delete it

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

1. [x] Deploy OmniStudio components and its dependencies (5 min)
   > sfdx force:source:deploy --sourcepath "src\main\default\omniDataTransforms,src\main\default\omniIntegrationProcedures,src\main\default\omniUiCard,src\main\default\omniScripts" --wait 30 --targetusername gandloju.vishwantha@accenture.com.ehis.dev
3. [x]  Deploy full repository (~20 min)
   1. [ ] Verify folders
      |Folder|Path|
      |-|-|
      |`src`|`src\main\default`|
      |`src-access-mgmt`|`src-access-mgmt\main\default`|
      |`src-ui`|`src-ui\main\default`|
   
   2. [x] Deploy 
      > sfdx force:source:deploy --sourcepath "src\main\default,src-access-mgmt\main\default,src-ui\main\default" --wait 30 --targetusername gandloju.vishwantha@accenture.com.ehis.dev -l RunLocalTests

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

2.[x] ALR-792 Residence ID will be starting at 000XX
    1. Go to Object Manager and select the Account object
    2. Click Fields & Relationships, select the UniqueAccountNumber__c field, then click Edit
    3. Click Change Field Type. Select 'Text' for the Data Type, then click Next - > Click Save on the next screen.
    4. Repeat Step 2–4. For step 3, select 'Auto-Number' for the Data Type.
    5. Set the Start Number as 10000

3. [x] 1. Import Templates:
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

4.[x] ALR-1533

- Deactivate the flow in every org with this story deployment:
- Flow Name: GenerateRenewalsForAccounts

5.[x] ALR-1562 Refer Jira for this step

6.[x] Flow status verification

- Please verify if the latest version of the mentioned flows are activated in all orgs. If not, Please activate the latest version.
- Flows
 1.Get Category List From Assessment Indicator Definition
 2.add Inspection Tasks

 7q.[x] ALR-1586 List view deletion
-From app launcher - EHIS Services - Go to Accounts(in home dropdown)->ListView->Residence Ready for Renewals->select settings->Delete

8.[x] ALR-1587 refer jira

9.[x] ALR-1199 Go to Omniscript “RiskAssessment“ → Open active version → Click on dropdown and select “Select Deploy Standard Runtime Compatible LWC “ → Done.

10.[x] ALR-1438 , ALR-1524 VERIFY THIS STEPS

11. [x] Update Sharing on Action Plan Template `Application Document Checklist template` record (1 min) ALR-793 ,853, 948
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

12. [ ] wait for same confirmation on EHIS email
For Org Wide Addresses: Setup->Search : Organization-Wide Addresses-> Select-> Add
      Provide the below details:
      Display Name:Test
      Email Address: 
      Select - Allow All Profiles to Use this From Address ->Save

13.[x] ALR-1073,1102 This step needs to be done after creating Admin person in ORG

14. [ ] ALR-1206,ALR-1387,1386,1577 - This step to be performed after creating all users

15.[x] Delete two flows
1.Account Contact Relationship Delete Restriction	
2.Task Created On Business License Record Create

DevOps checklist:

1. Make sure you activated the templates CertificateTemplateMH , CertificateTemplateSN Json ,CertificateTemplateSU Json
2. Validate the flows in org with Repo make sure active/inactive versions in branch which are deployed by devops should match in org
3.Accounts-ListView->Residence Ready for Renewals is deleted sometimes its not deleting properly