|Sandbox|`Runbook for PRD from SP-3 to SP18'|
|-|-|
|Runbook Created|`2026-02-20`|
|Runbook Last Modified|`2026-02-20`|

## Pre-Requisites [5 min ]

> Deployment User has assigned Permission Sets Group and Public group

- PHOCS System Administrator PSG
- PHOCS Business Admin & Officer PG

## Post-Deployment Steps

[ ] 1. EHIS-1815

> Login as System Admin

> Navigate to app launcher - search for regulatory authorization type object - select the list view with last modified date - go to list view filter - select the list view and delete

[ ] 2. 1786

> Navigate to Inspection, Select All list view, delete one duplicate

[ ] 3. EHIS- 2089

> navigate to visited party object - go to list view under visited party - open list view with fields contacts, visits - and delete this list view

[ ] 4. EHIS-3292

- Open Developer Console (or Workbench / VS Code SOQL runner).

> Run the following SOQL query to identify duplicate List Views:

> SELECT Id, SobjectType, DeveloperName, LastModifiedBy.Name, LastModifiedDate
  FROM ListView
  WHERE SobjectType = 'RegulatoryCodeViolation'
  Review the query results and identify any duplicate List Views based on the DeveloperName.

> Delete the old list and keep the list view which is deployed newly

Re-verify that only the correct List View remains.

[?] 5. EHIS-1725 Decision Matrix - revisit

- Navigate to App Launcher, search “Business Rules Engine” , Select Lookup Tables tab, find “PHOCS Inspection Action Plan Template Decision Matrix” record
- Select the latest version in Related list
- Click “Upload CSV File” to upload attached file

[? ] 5.1 EHIS-2221 Decision Matrix revist

- go to business rules engine -  decision matrix - PHOCS DOCUMENT CHECKLIST EXCEPTION - In the related tab under 

- Decision Matrix Versions - open the active verision and click on upload file attached and then reload to see the records once loaded

[?] 5.2 EHIS-2865 Decision matrix revist

- Update Decision Metrics - Click App Launcher, search “Business Rules Engine”
- Select Lookup Tables tab, find “PHOCS Document Checklists Decision Matrix” record
- Select the latest version in Related list
- Click “Upload PHOCS Document Checklists V1_2025-11-26 14_05_31 CSV File” to upload attached file 

[ ] 6. EHIS - 1861

> Give Viewer access to EHIS PHOCS Users PG Group .   

- Switch to Classic - > Goto libraries → Select  DocgenDocumentTemplateLibrary   → Select Add memebers to give access.

- Upload  All PHOCS Doc Gen templates from phocs-DocgenTemplates Folder 

- go to , App Launcher -> OMNISTUDIO - Document Template Designer- Select import on right top and First Import all Json files

- After uploading go to Document template designer - > Select imported doc gen template → replace latest word file → save template details → Activate "

[ ] 7. EHIS-2111

> Verify each document template is active and status = 'Active'
 
- App Menu - search for Document Templates - Click on Document Templates
- Verify all phocs related document templates are Active (Active Checkbox checked) and status field value = 'Active'
- If any document template is not active then select the template and click on edit and check the checkbox Active and mark status field as Active.

[ ] 8. EHIS - 2527

Set the default domain according to the environment: Custom metadata - "User Registration User Mappings" 

- Go to custom metadata in org and search for “User Registration user mappings” custom metadata - click on manage records - open

1. 	NHA_Business_Admin -> click on edit and under Default Domain field - give value as 'phocs.prod ' repeat the same for below records
2.  NHA_Officer
3.  NHA_Reporting_User
4.  Provincial_Reporting_User
5.  System_Administrator

- go to setup - search for “My Domain” under authentication service add “PHOCS IDIR” and “Health BC” and save it.


[ ] 9. EHIS-2703

Assign Profile and Permission set related to Operator portal.

> go to potal - click on workspace - administration - memebers - add potal profile and ps 
  Profile - Custom Community Operator.
  Permission set - PHOCS Operator User CRE PS.

[ ] 10. Ehis-2258

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
