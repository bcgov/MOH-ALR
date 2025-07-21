# Release Deployment Runbook

|Sandbox|`PHOCS-SP3`
|Runbook Created|`2025-07-21`|
|Runbook Last Modified|`2025-07-21`|

## Pre-Requisites [5 min ]

1. [ ] Deployment User has assigned Permission Sets , Public Groups , PSG below

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

2. [ ] Checkout to `phocs-sprint4`code 
 
## Assumptions

1. Total execution time ~ > 30 mins

## Open Items

## Pre-Deployment Steps (3 mins)

[ ] EHIS-1668
- Create new record type with name PHOCS Action Plan Template Record Type under Action plan template object

- Go to setup - object manager - Action Plan Template - record type 
  1. Name - PHOCS Action Plan Template
  2. Label - PHOCSActionPlanTemplate
  3. Description - Capture templates for PHOCS Action Plans

[ ] EHIS- 1713 Data Loading Steps for inspection related objects 

- Load Regulatory Code - Resolve Regulatory Authority ( column Regulatory Authority)   & PHOCS Regulatory Code record Type , Check for missing regulatory authority and resolve manually  . Map ( Name, Subject , Description, RegulatoryAuthority Id, Effective From, Record Type Id)

- Load Assessment Task Definition - Resolve Record Type with PHOCS Assessment task Definition record type Id. Map ( Name, RecordType, TaskType)"

## Deployment Steps (20 mins)

1. [ ]  Deploy full repository (~20 min)
   1. [ ] Verify folders
      |Folder|Path|
      |-|-|
      |'bcgov-source`|

    2. [ ] Deploy Action Plan Templates
   - sf project deploy start --source-dir ActionPlanTemplates-Phocs/main/default --wait 30 --target-org  

   3. [ ] Deploy Omni studio components

   - sf project deploy start --source-dir bcgov-source/app-phocs/main/default/omniDataTransforms --wait 30 --target-org 
   - sf project deploy start --source-dir bcgov-source/core/main/default/omniDataTransforms --wait 30 --target-org

  [ ] deploy decision matrix 
  - sf project deploy start --source-dir src-bre\main\default\PhocsdecisionMatrixDefinition --wait 30 --target-or
  
   4. [ ] Deploy 
   - sf project deploy start --target-org deployment.user@phocs.ci -m "bcgov-source"  -l RunLocalTests 

## Post-Deployment Steps (30 mins)

1. [ ] EHIS-1701
Clone action plan templates below and publish them share templates for 
- " EHIS Water Admin Users PG" , " EHIS Officer Users PG " - R/W Access
  " PHOCS Reporting User PG" -  Read Access

1. Water Source Evaluation Application Checklist
2. Child Care License Application Checklist
3. Community Care Facility License Application Checklist
4. Food Premise Operating Permit Application Checklist
5. High Risk Temporary Food Service Operating Permit Application Checklist
6. Personal Service Establishment Health Approval Application Checklist
7. Pool Construction Permit Application Checklist
8. Pool Operating Permit Application Checklist
9. Sewerage Holding Tank Permit to Construct Application Checklist
10. Sewerage System Letter of Certification Application Checklist
11. Water Construction Permit Application Checklist
12. Water Operating Permit Application Checklist
13. Water Source Evaluation Application Checklist"

2. [ ] EHIS-1622 ,1725see subtask for csv file

- Click App Launcher, search “Business Rules Engine”
- Select Lookup Tables tab, find 
  1. “PHOCS Document Checklists Decision Matrix”  
  2. “PHOCS Inspection Action Plan Template Decision Matrix” 
- Select the latest version in Related list
- Click “Upload CSV File” to upload attached file 

3. [ ] EHIS - 1708 see subtask for csv file

- Insert Regulatory Authority Records
- go to salesforce Inspector or dataloader.io
  salesforce inspector - data import - select object regulatory authority - Insert excel - download the results or copy the RA Id’s
- Copy  Regulatory Authority Id and map in Regulatoty Authorization type excel as per regulatory authorization code map it in issuing department (paste RA id’s as per regulatory authorization code  )column 

OR

- salesforce inspector - data import - select object regulatory authorization type - Insert excel - download the results or copy the RA Id’s

4. [ ] EHIS-1621 see subtask for csv file

- Retrieve RecordTypeId of PHOCSInspectionType in the Salesforce instance
- Copy RecordTypeId into CSV file, Column B
- Upload the CSV file   into Data Loader (Insert) and do the 

- field mapping:
              - Name: Name
              - RecordType: RecordTypeId

5. [ ] EHIS-1815 

- Navigate to app launcher - search for regulatory authorization type object - select the list view with last modified date - go to list view filter - select the list view and delete

6. [ ] EHIS-1786

- Login as System Admin - Navigate to Inspection - All list view- Select All - delete one duplicate

DevOps checklist:

1.Ensure below steps are deployed - EHIS-1707
2. Action plan templates are published and shared with phocs users