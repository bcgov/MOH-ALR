# Release Deployment Runbook

|Sandbox|`PHOCS-SP7`
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

2. [ ] Checkout to tag ST.882 create a new branch out of it `phocs-sprint7` code 
 
## Assumptions

1. Total execution time ~ > 30 mins

## Open Items

## Pre-Deployment Steps (3 mins)

- None

## Deployment Steps (20 mins)

1. [ ]  Deploy full repository (~20 min)
    1. [ ] Verify folders
      |Folder|Path|
      |-|-|
      |'bcgov-source`|

    2. [ ] Deploy Omni studio components

   - sf project deploy start --source-dir bcgov-source/app-phocs/main/default/omniDataTransforms --wait 30 --target-org 
   - sf project deploy start --source-dir bcgov-source/core/main/default/omniDataTransforms --wait 30 --target-org

   3. [ ] sf project deploy start --source-dir src-bre\main\default\PhocsdecisionMatrixDefinition --wait 30 --target-org
   
   4. [ ] Deploy 
   - sf project deploy start --target-org deployment.user@phocs.ci -m "bcgov-source"  -l RunLocalTests 

## Post-Deployment Steps (30 mins)

[ ] EHIS-2070
- Create a listView on ViolationEnforcementAction with API name “MyViolationEnforcementActionsPHOCS"  to distinguish from ALR’s list view and label name “My Violation Enforcement Actions"

Columns: 

    <columns>Name</columns>
    <columns>Type</columns>
    <columns>Violation</columns>
    <columns>ComplianceDueDate</columns>
    <columns>Action_Received_By__c</columns>
    <columns>DaysOpen</columns>

FilterScope: My Violation Enforcement Actions records

Filters:

    <filters>
        <field>Status</field>
        <operation>notEqual</operation>
        <value>Resolved</value>
    </filters>

Share To:

    <sharedTo>
        <group>EHISUsersPG</group>
        <group>PHOCSDataLoadUser</group>
        <group>PHOCSReportingUserPG</group>
    </sharedTo>

[ ] EHIS-2035 LabTestMasterList DataLoad see subtask for csv

[ ] EHIS-2079

- Login with admin user and add below buttons in home tab for all PHOCS test users 
  1. Home
  2. Accounts
  3. Contacts
  4. Business License Applications
  5. Business License
  6. Public Complaint
  7. Cases
  8. Reports
  9. Dashboards
  10. Interaction Summaries

[ ] EHIS-2089
- navigate to visited party object - go to list view - phocs visited party - open list view with fields contacts, visits - and delete this list view

[ ] EHIS-2098
- Import PHOCSInvoiceTemplate and PHOCSReceiptTemplate in the target org .  (ST,QA,UAT & PROD)-Save Template details and Activate 

[ ] EHIS-2111 "PD Step - Verify each document template is active and status = 'Active'
- Steps 
  1. App Menu - Document Templates - Click on Document Templates
  2. Verify all phocs related document templates are Active (Active Checkbox checked) and status field value = 'Active'
  3. If any document template is not active then select the template and click on edit and check the checkbox Active and mark status field as Active.

[ ] EHIS-2134

Setup, in the Quick Find box, enter Document Generation, and then select Custom Fonts Configuration.
To transfer your fonts from Static Resources to the centralized Docgen Custom Fonts Library, click Migrate.

From Setup, in the Quick Find box, enter Document Generation, and then select Custom Fonts Configuration.
To synchronize all font updates, additions, or deletions and to ensure they’re available for document generation, click Sync.

[ ] EHIS-2192

"After the metadata is deployed, the following five Public Groups need to be added into “PHOCS Reporting User PG” as the post deployment steps in ST, QA, and Production:

EHIS FHA Reporting User

EHIS IHA Reporting User

EHIS NHA Reporting User

EHIS VCH Reporting User

EHIS VCIS Reporting User"

[ ] EHIS-2221 see subtask for csv

- go to business rules engine -  decision matrix - PHOCS DOCUMENT CHECKLIST EXCEPTION - In the related tab under 

- Decision Matrix Versions - open the active verision and click on upload file attached and then reload to see the records once loaded


DevOps checklist:

1.Ensure all docgen templates are activated proper document is uploaded and access is provided to library