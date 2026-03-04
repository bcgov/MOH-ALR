|Sandbox|`Runbook for PRD from SP-3 to SP18 and Hardening '|
|-|-|
|Runbook Created|`2026-03-03`|
|Runbook Last Modified|`2026-03-03`|

## Pre-Requisites [5 min ]

1. [ ] Deployment User has assigned Permission Sets


   1.Action Plans PS
   2.Document checklist PS
   3.DocGen Designer PS 
   4.DocGen Designer
   5.Docgen Designer Standard User
   6.Groupmembership PS
   7.OmniStudio User
  8.OmniStudio Admin
  9.Industries Visit
  10.PublicSector
  11.InteractionSummary

- [ ] Public Groups
    - ALR All Users PG
    - ALR Data Analyst Users PG
    - ALR Admin Users PG
    - EHIS Officer Users PG
    - EHIS Water Admin Users PG

- [ ] Permission Set Groups
    - EHIS ALR Admin PSG
    - EHIS ALR Data Analyst PSG
    - EHIS ALR Data Migration PSG
    - EHIS System Administrator PSG
    - EHIS Officer PSG
    - EHIS Business Admin PSG

2. [ ] Checkout to `latest branch`code 

## Assumptions

1. Total execution time ~ >  hrs 

## Pre-Deployment Steps (20 mins)

[x] 1. EHIS-2530 - 2mins
- Include changes in salesforcebackupadmininstratorbackup.ps copy from BCMOHAD-28583-Release-1.14.0.8 branch in the current deployment branch for UAT

> Deactivate matching rule 
- Navigate to setup , search for matching rules - search for - Residence_Account_Matching_Rule_V2 - click on deactivate

> Remove Action Plan Template from the folder and AAR sharing rules till deployment , once deployed move it back to the folder

- bcgov-source/app-alr/main/default/actionPlanTemplates
- bcgov-source\app-phocs\main\default\sharingRules\AccountAccountRelation.sharingRules-meta.xml

[x] 2. EHIS-1639 - 10mins one time activity

Delete Record Types in Asset object : 
go to setup - object manager - search for Asset object and delete below 

> [x] delete record types and remove the references from Profiles 
1. Water Distribution
2. Water Storage

> [x] Delete compact layouts
1. EHIS Water Storage
2. EHIS Water Distribution

> [x] Delete Layouts
1. EHIS Water Storage Compact Layout
2. Water Distribution

> [x] Delete Record Pages
1.EHIS Water Distribution Record Page
2.EHIS Water Storage Record Page

> [x] Delete sharing rules associated with these record types water distribution and water storage Asset record types

[x] one time activity
3. Delete EHIS_Water_Source_Intake_Record_Page , EHIS_Water_System_Record_Page from account object
4. Delete Water_Source_Intake_Layout , Water_System_Layout compact Layout from account object
5. Delete Water_Source_Intake , Water_System record type from account object
6  Delete sharing rules associated with this recordtype from account object

7.AccountAccountRelation.EHIS_Facility_AAR - Recordtype
8.PartyRoleRelation.EHIS_PRR - Recordtype

[x] 2. EHIS-2592 (5mins) - one time activity

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

[x] 3. EHIS-1668 ,2306 , 3105 (3mins)

Create new record type for ALR and  PHOCS under Action Plan Template object

> Go to setup - object manager - Action Plan Template - record type -
Label - PHOCS Action Plan Template
Name - PHOCSActionPlanTemplate
Record Type label: PHOCS Action Plan Template
Description: Capture templates for PHOCS Action Plans
Active=True

> Go to phocs app services - open action plan templates - click on setup - edit object - go to record type - create ALR action plan template 

Label ALR Action Plan Template
API Name - ALRActionPlanTemplate
Active=True
Description - Capture templates for ALR Action Plans

> Create RecordType this step is for data loading of Assessment Indicator defintion and provide field access to the PS

API Name - PHOCSAssessmentIndicatorDefinition
Active=True
description=Capture inspection questions
label=PHOCS Assessment Indicator Definition
Provide RT access
field access
Deploy - bcgov-source\core\main\default\objects\AssessmentIndicatorDefinition\fields\Criticality__c.field-meta.xml

[x] 4. EHIS-2070 (3mins)

To avoid deployment overrides the manual configuration, the listview has been deleted from DEV branch. Instead, the following configuration need to take place in Production:

> Create a listView on ViolationEnforcementAction with API name “MyViolationEnforcementActionsPHOCS"  to distinguish from ALR’s list view and label name “My Violation Enforcement Actions"

FilterScope: My Violation Enforcement Actions records

Filters:
    <filters>
        <field>Status</field>
        <operation>notEqual</operation>
        <value>Resolved</value>
    </filters>

[x] 5. EHIS-2258 (3 mins)

> Quick Find → Digital Experience → Settings enable Enable Digital Experiences
> and enable all items under Experience Management Settings.
> Provide Deployment User for Site - user format should be @gov.bc.ca
- bcgov-source\app-phocs\main\default\sites\phocsservices.site-meta.xml - 
- bcgov-source\app-phocs\main\default\sites\phocsportal.site-meta.xml

[x] 6. Include custom metadata during deployment (3mins)

from 
- copy files from C:\repo\MOH-ALR\src-env-specific\prod\main\default\customMetadata
in 
-C:\repo\MOH-ALR\bcgov-source\app-phocs\main\default\customMetadata 

[x] Deploy DecisionMatrixDefinition files (3mins)

> sf project deploy start --source-dir src-bre\main\default\PhocsdecisionMatrixDefinition --wait 30 --target-org deployment.user@phocs.preprd.com

## Deployment Steps (60 mins)

1. [x] Deploy Omni studio components (~15min)

> sf project deploy start --source-dir bcgov-source\app-alr\main\default\omniDataTransforms --source-dir bcgov-source\app-alr\main\default\omniIntegrationProcedures --source-dir bcgov-source\app-alr\main\default\omniScripts --source-dir bcgov-source\app-alr\main\default\OmniInteractionConfig --source-dir bcgov-source\app-alr\main\default\omniUiCard --source-dir bcgov-source\app-phocs\main\default\omniDataTransforms --source-dir bcgov-source\app-phocs\main\default\omniIntegrationProcedures --source-dir bcgov-source\app-phocs\main\default\omniScripts --source-dir bcgov-source\app-phocs\main\default\omniUiCard --source-dir bcgov-source\core\main\default\omniDataTransforms --source-dir bcgov-source\core\main\default\omniScripts --target-org deployment.user@phocs.preprd.com

2. [ ] Validate components

> sf project deploy start --dry-run --source-dir bcgov-source --wait 30 --target-org deployment.user@phocs.preprd.com -l RunLocalTests -g

[ ]  Deploy full repository (~20 min)

3. [ ] Deploy 
   - sf project deploy start --source-dir bcgov-source --target-org deployment.user@phocs.preprd.com --test-level RunLocalTests -g

## Post-Deployment Steps 

[ ] 1. deactivate and activate Omni studio Active version components after deployment , make sure the active version to be verified from branch during deactivation and activation and 

  1. App Launcher -> OmniStudio -> Omnistudio **Integration Procedures**
      2. Locate all active custom **Integration Procedures** -> deactivate them -> activate them back.
      3. App Launcher -> Omniflex cards -> **Omnistudio Flex Cards**
      4. Locate all active custom **Flex Cards** -> open each Flex Card -> deactivate -> activate back.
      5. App Launcher -> OmniStudio -> **OmniScripts**
      6. Locate all active custom **OmniScripts** -> open each omni script -> deactivate -> activate back

[ ] 2. EHIS-2070

After deployment share list view with public groups and add columns

> “My Violation Enforcement Actions"
update columns
Columns: 
    <columns>Violation enforcement action</columns>
    <columns>Type</columns>
    <columns>Violation</columns>
    <columns>ComplianceDueDate</columns>
    <columns>Action_Received_By__c</columns>
    <columns>DaysOpen</columns>
share To:

    <sharedTo>
        <group>EHISUsersPG</group>
        <group>PHOCSDataLoadUser</group>
        <group>PHOCSReportingUserPG</group>
    </sharedTo>hare To:

    <sharedTo>
        <group>EHISUsersPG</group>
        <group>PHOCSDataLoadUser</group>
        <group>PHOCSReportingUserPG</group>
    </sharedTo>

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

[ ] 14. Populate AAR recordtypeID in PRD

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

9. - Click App Launcher, search “Business Rules Engine”
   - Select Lookup Tables tab, find “PHOCS Document Checklists Decision Matrix” record
   - Select Lookup Tables tab, find “PHOCS Inspection Action Plan Template Decision Matrix”
   - Select Lookup Table tab, find "PHOCS Document Checklist Exemption " 
   - Make sure the above DM's are activated

10. Verify sharing rules for account , ARR , PRR, Asset