# Release Deployment Runbook

|Sandbox|`PHOCS-SP3`
|Runbook Created|`2025-07-21`|
|Runbook Last Modified|`2025-06-21`|

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

2. [ ] Checkout to `phocs-sprint3`code 
 
## Assumptions

1. Total execution time ~ > 30 mins

## Open Items

## Pre-Deployment Steps (3 mins)

[ ] None

## Deployment Steps (20 mins)

1. [ ]  Deploy full repository (~20 min)
   1. [ ] Verify folders
      |Folder|Path|
      |-|-|
      |'bcgov-source`|

   2. [ ] Deploy Omni studio components

   - sf project deploy start --source-dir bcgov-source/app-phocs/main/default/omniDataTransforms --wait 30 --target-org 
   - sf project deploy start --source-dir bcgov-source/core/main/default/omniDataTransforms --wait 30 --target-org
   
   3. [ ] Deploy 
   - sf project deploy start --target-org deployment.user@phocs.ci -m "bcgov-source"  -l RunLocalTests 

## Post-Deployment Steps (30 mins)

1. Create Test users 

[ ] Name - EHIS Admin Test User
> Username : EHIS-ADMIN-USER@test.UAT.com
> Email id : yet to be provided
> Profile assigned - EHIS Standard User
> User License - Salesforce
> PSG Assigned - EHIS Water Business Admin PSG
> Public Group Membership - EHIS Water Admin Users PG

[ ] Name - EHIS Officer Test
> Username : EHIS-Officer-USER@test.UAT.com
> Email id : yet to be provided
> Profile assigned - EHIS Standard User
> User License - Salesforce
> PSG Assigned - EHIS Water Officer PSG
> PS License Assignments - Public Sector Access
> Public Group Membership - EHIS Officer Users PG

DevOps checklist:

1.Ensure below steps
- Go To EHIS Standard User Profile -> object setting --> Account Account Relation -->  provide access to record type - Facility Linkage and make it default.