
Sandbox|`Post refresh runbook till SP-18 " UAT ORG "|
|-|-|
|Runbook Created|`2026-02-23`|
|Runbook Last Modified|`2026-02-23`|

2. [x] Checkout to `release-phocs-uat-sp18.1.4`code

3.[x]  Deploy full repository (~20 min)

>sf project deploy start --source-dir bcgov-source/core/main/default/omniDataTransforms/DrAccountName_1.rpt-meta.xml --source-dir bcgov-source/core/main/default/omniDataTransforms/DRCreateAccountContactRelation_1.rpt-meta.xml --source-dir bcgov-source/core/main/default/omniDataTransforms/DRToCreateDuplicateContacts_1.rpt-meta.xml --source-dir bcgov-source/core/main/default/omniScripts/EHIS_AccountContactRelation_English_8.os-meta.xml --source-dir bcgov-source/core/main/default/omniScripts/EHIS_AccountContactRelation_English_9.os-meta.xml --target-org deployment.user@phocs.uat.com