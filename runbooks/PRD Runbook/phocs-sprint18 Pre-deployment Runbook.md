|Sandbox|`Runbook for PRD from SP-3 to SP18'|
|-|-|
|Runbook Created|`2026-02-20`|
|Runbook Last Modified|`2026-02-20`|

## Pre-Requisites [5 min ]

1. [ ] Deployment User has assigned Permission Sets

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

2. [ ] Checkout to ``code 

## Assumptions

1. Total execution time ~ >  hrs 

## Pre-Deployment Steps (20 mins)

[ ] 1. EHIS-2530
- Include changes in salesforcebackupadmininstratorbackup.ps copy from BCMOHAD-28583-Release-1.14.0.8 branch in the current deployment branch for UAT

[ ] 1. EHIS-1639   

Delete Record Types in Asset object : 
go to setup - object manager - search for Asset object and delete below 

> [ ] delete record types and remove the references from Profiles 
1. Water Distribution
2. Water Storage

> [ ] Delete compact layouts
1. EHIS Water Storage
2. EHIS Water Distribution

> [ ] Delete Layouts
1. EHIS Water Storage Compact Layout
2. Water Distribution

> [ ] Delete Record Pages
1.EHIS Water Distribution Record Page
2.EHIS Water Storage Record Page

> [ ] Delete sharing rules associated with these record types water distribution and water storage Asset record types

[ ] 2. EHIS-2592

> Delete fields from account object

        <members>Account.Well_Casing_Diameter_cm__c</members>
		<members>Account.Well_Depth_m__c</members>
		<members>Account.Well_Construction_Method__c</members>
		<members>Account.Well_Elevation_m__c</members>
		<members>Account.Well_Casing_Seal__c</members>
		<members>Account.Wellhead_Cap__c</members>
        <members>Account.Wellhead_Protection_Plan__c</members>
        <members>Account.Construction_Date__c</members>
        <members>Account.Source_Water_Body__c</members>

[ ] 3. EHIS-1668 ,2306 , 3105

Create new record type for ALR and  PHOCS under Action Plan Template object

> Go to setup - object manager - Action Plan Template - record type -
Name - PHOCS Action Plan Template
Label - PHOCSActionPlanTemplate
Record Type label: PHOCS Action Plan Template
Description: Capture templates for PHOCS Action Plans
Active=True

> Go to phocs app services - open action plan templates - click on setup - edit object - go to record type - create ALR action plan template 

Label ALR Action Plan Template
API Name - ALRActionPlanTemplate
Active=True
Description - Capture templates for ALR Action Plans

[ ] 4. EHIS-2070

To avoid deployment overrides the manual configuration, the listview has been deleted from DEV branch. Instead, the following configuration need to take place in Production:

> Create a listView on ViolationEnforcementAction with API name “MyViolationEnforcementActionsPHOCS"  to distinguish from ALR’s list view and label name “My Violation Enforcement Actions"

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

[ ] EHIS-2258

> Quick Find → Digital Experience → Settings and enable all items under Experience Management Settings.
> Provide Deployment User for Site
- bcgov-source\app-phocs\main\default\sites\phocsservices.site-meta.xml
- bcgov-source\app-phocs\main\default\sites\phocsportal.site-meta.xml


## Post-Deployment Steps

[ ] 3. EHIS-1815

> Login as System Admin

> Navigate to app launcher - search for regulatory authorization type object - select the list view with last modified date - go to list view filter - select the list view and delete

[ ] 4. 1786

> Navigate to Inspection, Select All list view, delete one duplicate

[ ] 5. EHIS- 2089

> navigate to visited party object - go to list view under visited party - open list view with fields contacts, visits - and delete this list view

[ ] 6. EHIS-3292

- Open Developer Console (or Workbench / VS Code SOQL runner).

> Run the following SOQL query to identify duplicate List Views:

> SELECT Id, SobjectType, DeveloperName, LastModifiedBy.Name, LastModifiedDate
  FROM ListView
  WHERE SobjectType = 'RegulatoryCodeViolation'
  Review the query results and identify any duplicate List Views based on the DeveloperName.

> Delete the old list and keep the list view which is deployed newly

Re-verify that only the correct List View remains.

[?] 7. EHIS-1725 Decision Matrix - revisit

- Navigate to App Launcher, search “Business Rules Engine” , Select Lookup Tables tab, find “PHOCS Inspection Action Plan Template Decision Matrix” record
- Select the latest version in Related list
- Click “Upload CSV File” to upload attached file

[? ] 7.1 EHIS-2221 Decision Matrix revist

- go to business rules engine -  decision matrix - PHOCS DOCUMENT CHECKLIST EXCEPTION - In the related tab under 

- Decision Matrix Versions - open the active verision and click on upload file attached and then reload to see the records once loaded

[?] 8.2 EHIS-2865 Decision matrix revist

- Update Decision Metrics - Click App Launcher, search “Business Rules Engine”
- Select Lookup Tables tab, find “PHOCS Document Checklists Decision Matrix” record
- Select the latest version in Related list
- Click “Upload PHOCS Document Checklists V1_2025-11-26 14_05_31 CSV File” to upload attached file 

[ ] 9. EHIS - 1861

> Give Viewer access to EHIS PHOCS Users PG Group .   

- Switch to Classic - > Goto libraries → Select  DocgenDocumentTemplateLibrary   → Select Add memebers to give access.

- Upload  All PHOCS Doc Gen templates from phocs-DocgenTemplates Folder 

- go to , App Launcher -> OMNISTUDIO - Document Template Designer- Select import on right top and First Import all Json files

- After uploading go to Document template designer - > Select imported doc gen template → replace latest word file → save template details → Activate "

[ ] 10. EHIS-2111

> Verify each document template is active and status = 'Active'
 
- App Menu - search for Document Templates - Click on Document Templates
- Verify all phocs related document templates are Active (Active Checkbox checked) and status field value = 'Active'
- If any document template is not active then select the template and click on edit and check the checkbox Active and mark status field as Active.

[ ] 11. EHIS - 2527

Set the default domain according to the environment: Custom metadata - "User Registration User Mappings" 

- Go to custom metadata in org and search for “User Registration user mappings” custom metadata - click on manage records - open

1. 	NHA_Business_Admin -> click on edit and under Default Domain field - give value as 'phocs.prod ' repeat the same for below records
2.  NHA_Officer
3.  NHA_Reporting_User
4.  Provincial_Reporting_User
5.  System_Administrator

- go to setup - search for “My Domain” under authentication service add “PHOCS IDIR” and “Health BC” and save it.


[ ] 12. EHIS-2703

Assign Profile and Permission set related to Operator portal.

> go to potal - click on workspace - administration - memebers - add potal profile and ps 
  Profile - Custom Community Operator.
  Permission set - PHOCS Operator User CRE PS.

[ ] 13. Ehis-2258

> Go to Quick find → Sites → click on phocsservices → add David user meail in site admin and record owner.
> Go to Quick find → Sites → click on phocsportal → add David user meail in site admin and record owner.

EMAIL - david.surrao@gov.bc.ca

Verification checklist

1. [ ] EHIS-2527 
-  Under subtask step-5 please verify after completing all steps 

2. [ ] EHIS-3247 - this step has to be performed after each PRD deployment

3. [ ] EHIS-2894 verify this step if it doen't exit ignore
-  Object: BusinessLicenseApplication
-  List view API name: MyApplicationsPHOCS
Note: 
1. the above list view may or may not exist in lower environment. If it exists, please do destructive deployment to delete it.
2. The above list view does NOT exist on DEV main branch.
3. There is another list view with same label name (API: PHOCSMyApplications). Please keep it as-is and do NOT delete it.

4.[ ] Ensure all docgen templates are activated proper document is uploaded and access is provided to library

5. [ ] Action plan templates are published and shared with phocs users

6. [ ] EHIS-3266 Recheck the data in Decision matrix data for Dairy plant licence should have “ce”  at end

7. [ ] EHIS-3128

8. Make sure Operator Portal Sharing Sets sharing sets are deployed
