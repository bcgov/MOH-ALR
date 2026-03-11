Sandbox|`Post refresh runbook till SP-18 " UAT ORG "|
|-|-|
|Runbook Created|`2026-03-9`|
|Runbook Last Modified|`2026-03-9`|

2. [x] Checkout to `release-phocs-uat-sp18.1.7`code

3.[x]  Deploy full repository (~20 min)

> sf project deploy start --source-dir bcgov-source/app-alr/main/default/classes/FetchAndGenerateCSV.cls --source-dir bcgov-source/app-alr/main/default/classes/FetchAndGenerateCSVTest.cls --source-dir bcgov-source/app-alr/main/default/permissionsetgroups/EHIS_ALR_Admin_PSG.permissionsetgroup-meta.xml --source-dir bcgov-source/app-alr/main/default/permissionsetgroups/EHIS_ALR_Data_Analyst_PSG.permissionsetgroup-meta.xml --source-dir bcgov-source/app-alr/main/default/permissionsets/EHIS_InvoiceFLS_Access_PS.permissionset-meta.xml --target-org deployment.user@phocs.uat.com

