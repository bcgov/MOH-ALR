|Sandbox|`Post refresh runbook till SP-17 " UAT ORG "|
|-|-|
|Runbook Created|`2026-01-19`|
|Runbook Last Modified|`2026-01-19`|

## Pre-Requisites [5 min ]

1. [x] Deployment User has assigned Permission Sets

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

2. [x] Checkout to `release-phocs-uat-sp17`code 

## Assumptions

1. Total execution time ~ > 3hrs 

## Open Items

## Pre-Deployment Steps (20 mins)

[x] 1. Delete Fields from Account object and from facility record page
ExclusiveChangeRoomplantworkers__c
AnimalsOnSite__c
ExclusiveWashroomplantworkers__c

[x] Delete custom metadata field from PHOCSActionPlanTemplateDecisionMap
InspectionAccountType__c
- deployed InspectionFacilityType__c, InspectionCategory__c fields as a predeployment step before deploying apexclass
field dependency on apexclass - deploy apex class change from branch to target org

[x] EHIS-3105
Go to phocs app services - open action plan templates - click on setup - edit object - go to record type - create ALR action plan template 
1. Label ALR Action Plan Template
   API Name - ALRActionPlanTemplate
   Active=True
   Description - Capture templates for ALR Action Plans

## Deployment Steps (20 mins)

1. [x] EHIS-3000 Deploy ActionPlanTemplates

> BCCDC Holder Pasteurizer equipment
> BCCDC HTST 
> BCCDC In Depth Inspection
> BCCDC Inspection Update
> BCCDC Routine Inspection
> BCCDC UHT Pasteurizer Equipment

2. [x] Deploy Omni studio components 

> Deploy Omni data transforms
PHOCSRegulatoryTrxnFeeDataMapper_1	
PHOCSRegulatoryTrxnFeeExtract_1	
PHOCSRegulatoryTrxnFeeReceiptDM_1
PHOCSRegulatoryTrxnFeeReceiptExtract_1
getDSWRelatedStorageFacilities_1
DRdocgengetRegulatoryTrxnFeeDetails_1

> Deploy Omniscripts
DocumentGeneration_PHOCSDocumentGeneration_English_3
LicensingAndPermitting_storagefacilities_English_3

4.[x]  Deploy full repository (~20 min)

> sf project deploy start --source-dir bcgov-source --target-org deployment.user@phocs.uat.com --test-level RunLocalTests -g

## Post-Deployment Steps (30 mins)

[x] EHIS-3079 Update Sharing on PHOCS Action Plan Template

   1. App Launcher -> Action Plan Templates -> **navigate** to `ActionPlanTemplates` record above

   [x] - As part of post deployment steps, after the deployment of “Action plan templates“, the status of this template is ‘Read only’, it's not visible to the users while adding a template on Action plan creation.
   -So please do the following steps to activate the template, 
   -Note: Login as Phocs system admin user should have only phocs Permissions assigned
   -Step 1: Clone the existing Templates
   -Step 2: After cloning the Original Action Plan Template
   Before Publishing the template in the items section of Document checklist items 
   -Step 3: **Add** Sharing 

      |Item Type|Item Name|Access Level|
      |-|-|-|
      |Public Group|` EHISUsersPG`|Read/Write|
      |Public Group|`PHOCS Reporting User PG` |Read Only|
      |Public Group|`PHOCS Operator User PG` |Read Only|

   3. Click **Save**

> DataLoading

[x] EHIS-2998

- Create  inspection type record in all sandboxes with phocs inspection type
In-depth
In-depth Follow-up
Pre-licensing
Pre-licensing Follow-up
Inspection Update

[X] EHIS-3057,3079,3095,3109