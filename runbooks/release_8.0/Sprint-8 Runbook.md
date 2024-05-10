# Post refresh Deployment Runbook

|Sandbox|`SP8`|
|-|-|This deployment is done before PRD Spirnt-5 deployment
|Runbook Created|`2024-04-7`|
|Runbook Last Modified|`2024-04-7`|

## Pre-Requisites [5 min ]

1. [] Deployment User has assigned Permission Sets

   1.EHIS ALR Data Migration PS
   2.EHIS Enable MFA PS
   3.Action Plans PS
   4.Document checklist PS
   5.DocGen Designer PS
   6.ALR All Users PG
   7.ALR Data Analyst Users PG

2. [] Checkout to `latest QA.tag` code  - create new branch out of it ""

## Assumptions

1. Total execution time ~ > 3 hrs

## Open Items

## Pre-Deployment Steps (1 hr 15mins)




## Deployment Steps (20 mins)

1. [ ] Deploy OmniStudio components and its dependencies (5 min)
   > sfdx force:source:deploy --sourcepath "src\main\default\omniDataTransforms,src\main\default\omniIntegrationProcedures,src\main\default\omniUiCard,src\main\default\omniScripts" --wait 30 --targetusername deployment.user@gov.bc.ca.alr

3. [ ]  Deploy full repository (~20 min)
   1. [ ] Verify folders
      |Folder|Path|
      |-|-|
      |`src`|`src\main\default`|
      |`src-access-mgmt`|`src-access-mgmt\main\default`|
      |`src-ui`|`src-ui\main\default`|
   
   2. [ ] Deploy 
      > sfdx force:source:deploy --sourcepath "src\main\default,src-access-mgmt\main\default,src-ui\main\default" --wait 30 --targetusername deployment.user@gov.bc.ca.alr -l RunLocalTests

   3. [ ] Re-activate Omnistudio components
      1. App Launcher -> OmniStudio -> Omnistudio **Integration Procedures**
      2. Locate all active custom **Integration Procedures** -> deactivate them -> activate them back.
      3. App Launcher -> OmniStudio -> **Omnistudio FlexCards**
      4. Locate all active custom **FlexCards** -> open each FlexCard -> deactivate -> activate back.
      5. App Launcher -> OmniStudio -> **OmniScripts**
      6. Locate all active custom **OmniScripts** -> open each FlexCard -> deactivate -> activate back

## Post-Deployment Steps (1hr)

1. [ ] ALR-1379

- Login to Salesforce as System admin
- Go to Set up - Search Account Settings in Quick find box.
- Click on Edit - under “Contacts to Multiple Accounts Settings“  select the Radio button on “Delete the relationship between the contact and the previous primary account”
- Click Save.

2.[ ] ALR-1386 , ALR- 1444 Assign MMHA, SPDR User to Public Group & PSG

- Assign MMHA , SPDR User to Public Group
- Go To Setup - Search Public Groups - edit ALR MMHA Users PG
- Assign the MMHA user you created in step 1 to Selected Members and click Save
- Go To Setup - Search Public Groups - edit ALR SPDR Users PG
- Assign the SPDR user you created in step 1 to Selected Members and click Save

[ ] Assign Permission Set Group to MMHA User,SPDR User

- Go To Setup - Search Users - Open the MMHA User you created (for production it is Megan and lower environment it is Vasanthi MMHA / Vishwantha MMHA)
- Go to Permission Set Group Section and Add EHIS ALR MMHA PSG
- Go To Setup - Search Users - Open the SPDR User you created (for production it is Megan and lower environment it is Vasanthi MMHA / Vishwantha MMHA)
- Go to Permission Set Group Section and Add EHIS ALR SPDR PSG

3.[ ] ALR-1402 Please add share to below reports folder for the user Pooled Org Admin

- Open reports-select All Folders - 
- Give access to below folders - Click on right arrow - click share

Make Sure below folders only have pooled org admin access, If you see any other name under Who Can access, please remove and click Done
Dashboard Reports - Adoption
Sales and Marketing Reports
Sales & Marketing Dashboards Reports
Einstein Bot Reports
Einstein Bot Reports Spring '23
Einstein Bot Reports Summer '23
Einstein Bot Reports Summer ’22
Einstein Bot Reports Winter '23
Service Dashboards Reports

Got to reports
Select All Folders
On right side of  ALR Leadership Reports
Click on right arrow - click share

Under Who Can Access
Remove ALR Admin Users PG
Remove ALR Investigator Users PG
Click Done Button

- Select User for each folder - pooled Org Admin,give Manage access , click share and Done



5. ALR-1455 This step is destructive deployment not required after refresh

- Please remove below report in lower orgs -
- go to reports > all folders > mmha folder >
- on right dropdown click and delete

> MMHA Complaints' Violations Cases Report
> Complaints_and_Violations_Report_TgQ
> MMHAReports/MMHA_Illegal_Operators_33v
> MMHAReports/MMHA_Investigator_Workload_by_Region_rTG
> MMHAReports/MMHA_NonCompliant_Issues_Report_gKZ
> MMHAReports/MMHA_Reportable_Incidents_Report_n7Q
> MMHAReports/Rate_of_Operator_Compliance_bHB
> MMHAReports/Residence_Report_by_Type_GWd
> MMHAReports/Residences_within_Region_q3x

>[ ] Checklist after excecuting all steps

- [ ] Make sure 4 Decision matrix's and its data uploaded and activated 
- [ ] 7 Action Plan Templates are created and published and shared to PG 
- [ ] verify 1123 for data loading
- [ ] Email templates - make sure 4 email templates are cloned from PRD along with body and view access shared to Admin and data analyst PG (ALR-1438)
- [ ] Make sure 15 templates are created - first import Json files for each template and upload word documents and activate them
- [ ] Org wide email address verification should get it verified by Divya from Dawn inform Divya
- [ ] Verify the flows in repository and Org's active or inactive 

6. [ ] ALR-1387 - Create MMHA & SPDR User

- Go To Setup - Search Users in quick find box in left - Create New User
- In Production the user need to be created with email - megan.daly@gov.bc.ca
- Please create MMHA Test and SPDR User same like other personas we had. In other lower sandbox please create MMHA,SPDR user for testing purpose with Vishwantha or Vasanthi. Make sure you create user with last name as MMHA,SPDR

7. flows check if they are activated, as per Repository