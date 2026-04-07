|Sandbox|`Post refresh runbook till SP-16 " UAT ORG "for March 2026 release UAT`|
|-|-|
|Runbook Created|`2025-12-12`|
|Runbook Last Modified|`2025-12-15`|

2. [x] Checkout to `release-phocs-uat-sp16.1.1`code

3. [x] ## Deployment Steps (20 mins)

- sf project deploy start --source-dir bcgov-source --target-org deployment.user@phocs.uat.com --test-level RunLocalTests -g

Data Creation 

[x] EHIS-2998

- Create the following new Inspection Type records using the existing PHOCS Inspection Type record type:

In-depth

In-depth Follow-up

Pre-licensing

Pre-licensing Follow-up

Inspection Update