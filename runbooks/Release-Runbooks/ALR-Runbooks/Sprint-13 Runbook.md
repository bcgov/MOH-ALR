## UAT SP12 Deployment Runbook

|Sandbo|`Release runbook for " ALR-SP-13"|
|-|-|
|Runbook Created|`2024-8-16`|
|Runbook Last Modified|`2024-8-16`|

## Pre-Requisites [5 min ]

1. [ ] Deployment User has assigned Permission Sets

   1.EHIS Data Migration PS
   2.EHIS Enable MFA PS
   3.Action Plans PS
   4.Document checklist PS
   5.DocGen Designer PS
   6.ALR All Users PG
   7.ALR Data Analyst Users PG
   8.Business Milestones and Life Events Access PS

2. [ ] Checkout to tag  QA.tag create release branch out of it 

## Assumptions

1. Total excecution time ~ > 30 mins

## Open Items

## Pre-Deployment Steps (5 mins)

1. [ ] ALR-1787

- STEP 1: Go to app launcher

- STEP 2: Select Salesforce Inspector->Data Export->Execute the below Query. OR Go to Developer Console → Query Editor → Execute the below Query.

  > Select folderId,Id,Name,HtmlValue, Body, DeveloperName from EmailTemplate where DeveloperName ='Upcoming_Renewal_Email_Template'

- STEP 3 : Copy the FolderId, Id of Name “Upcoming_Renewal_Email_Template” from the export.

- STEP 4 : Replace the folderId, Id Column in Email Template-upcoming Renewal File.csv for 1 column and 2 column to the copied Id from data export->Save the file

- STEP 5:Select Salesforce Inspector->Data Import. OR Data Loader-Select the below:

Action->upsert
Object->Email Template

## Deployment Steps (20 mins)

1. [ ] Deploy OmniStudio components and its dependencies (5 min)
   > sfdx force:source:deploy --sourcepath "ehis-source\core\main\default\omniScripts,ehis-source\core\main\default\omniDataTransforms,src\main\default\omniDataTransforms,src\main\default\omniIntegrationProcedures,src\main\default\omniUiCard,src\main\default\omniScripts" --wait 30 -u gandloju.vishwantha@accenture.com.alr.uat


2. [ ]  Deploy full code (~10 min)

- sfdx force:source:deploy --sourcepath "ehis-source,src-access-mgmt\main\default,src-ui\main\default,src\main\default" --wait 30 -u gandloju.vishwantha@accenture.com.alr.uat -l RunLocalTests

3. [ ] Re-activate Omnistudio components
      1. App Launcher -> OmniStudio -> Omnistudio **Integration Procedures**
      2. Locate all active custom **Integration Procedures** -> deactivate them -> activate them back.
      3. App Launcher -> Omniflex cards -> **Omnistudio Flex Cards**
      4. Locate all active custom **Flex Cards** -> open each Flex Card -> deactivate -> activate back.
      5. App Launcher -> OmniStudio -> **OmniScripts**
      6. Locate all active custom **OmniScripts** -> open each omni script -> deactivate -> activate back

4. [ ] ALR-1199 Go to Omniscript “RiskAssessment“ → Open active version → Click on dropdown and select “Select Deploy Standard Runtime Compatible LWC “ → Done.

## Post-Deployment Steps (30 mins)

1. [ ] ALR-1796
- go to Setup-> Users-> Admin User and Data Analyst User ->Edit → check in Marketing User -> Save

- " ALR Admin Users "

   > UAT admin users : "Dawn Admin, Britney Torrell, Emily Trenchard, Graham Bruce,  Kristine Harper, Sonia Grewal, Denise Admin, Ranadheer Gundla, Mojtaba Admin, Yash Singh"
   > Prod admin users: "Sonia Grewal, Kristine Harper, Kaleigh Vukobrat"

- " ALR Data Analyst Users "

   > UAT admin users: "Mojtaba Rahmani, Dawn Data Analyst"
   > Prod admin users: "Mojtaba Rahmani"

2. [ ] ALR-1820
- Profile->MOH Standard USers-> System Permission-> Edit->”Allow sending of List Emails” uncheck this → Save

3. [ ] ALR-1829

- Go to Workbench - SOQL Queries-> Select Bulk CSV-> "Select Id,ActualVisitStartTime, PlannedVisitStartTime from Visit".
- Download file->Open->Remove  ActualVisitStartTime Column -> Change PlannedVisitStartTime name to ActualVisitStartTime name → Save 
- open data loader - go to Data Import->update-> Select Visit(Inspection)->Select CSV-> automatch fields and upload.

   > if Error as “Actual Start Time cannot be in the past; or, Actual End Time cannot be before Actual Start Time” or  “Update Actual Start Time to a current or past date.”

   > copy Id from the list and paste it in URL post lightning.force.com Like below “https://bcministryofhealth-environmentalh2--dev.sandbox.lightning.force.com/0fhbZ00000002mbQAA”.

   > edit the Actual start time  to present date and save .

4. [ ] ALR-1810 - Below mentioned templates is available in repository - under folder "DocgenTemplates"

- Navigate to App launcher->search for omnistudio ->search for Document template designer delete below 3 templates and import one after other one by one

  > " CertificateTemplateSN ,certificateTemplateSU ,CertificateTemplateMH "

Step 2 :- First Import all 3 certificate template Json files and then replace with ppt

1.Import CertificateTemplateSN.json ->select replace - > select CertificateBackground_SN.pptx and click on save template details and activate the template

2.Import CertificateTemplateSU.json->select replace -> select CertificateBackground_SN.pptx and click on save template details and activate the template

3.Import CertificateTemplateMH.json->select replace -> CertificateBackground_MH.pptx and click on save template details and activate the template

5. [ ] ALR-1838 - Below mentioned templates is available in repository - under folder "DocgenTemplates"

- Navigate to App launcher->search for omnistudio ->search for Document template designer delete below template
  > "InspectionReport"

- First Import Json file and then replace with word Document

1.Import InspectionReport.json ->select replace - > select Inspection Report.doc and click on save template details and activate the template

6. [x] ALR-1840

- Setup → Scheduled Jobs → Delete the “Trigger Email on Jan-15“ Job
- Job Name: Trigger Email on Jan-15
- Apex Class: ScheduleSendEmail
- Cron Expression: True
- Cron Expression: 0 0 0 15 1 ?

DevOps checklist:

1. Make Sure "CertificateTemplateSN ,certificateTemplateSU ,CertificateTemplateMH" activated