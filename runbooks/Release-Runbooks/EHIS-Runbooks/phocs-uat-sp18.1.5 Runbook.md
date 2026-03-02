Sandbox|`Post refresh runbook till SP-18 " UAT ORG "|
|-|-|
|Runbook Created|`2026-03-2`|
|Runbook Last Modified|`2026-03-2`|

2. [x] Checkout to `release-phocs-uat-sp18.1.5`code

3.[x]  Deploy full repository (~20 min)

> sf project deploy start --source-dir bcgov-source\app-phocs\main\default\permissionsets\EHIS_Manage_System_Admin_User_PS.permissionset-meta.xml --target-org deployment.user@phocs.uat.com