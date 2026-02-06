|Sandbox|`Post refresh runbook till SP-17 and SP18 " UAT ORG "|
|-|-|
|Runbook Created|`2026-02-2026`|
|Runbook Last Modified|`2026-02-2026`|

# Pre-Requisites [5 min ]

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

2. [x] Checkout to `release-uat-1.17.0.9`code 

[x] Deploy full repository (~20 min)

> sf project deploy start --source-dir bcgov-source --target-org deployment.user@phocs.uat.com -g

[x] Upload EHIS-3274,3279 BLA worker License and BLA plant License document template from Document template designer 
For document refer repo under PHOCS-Docgentemplates folder

[x] EHIS-3292