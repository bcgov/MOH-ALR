Sandbox|`Post refresh runbook till SP-18 " UAT ORG "|
|-|-|
|Runbook Created|`2026-02-16`|
|Runbook Last Modified|`2026-02-16`|

2. [x] Checkout to `release-phocs-uat-sp18`code

3.[x]  Deploy full repository (~20 min)

> sf project deploy start --source-dir bcgov-source --target-org deployment.user@phocs.uat.com --test-level RunLocalTests -g

4. [x] EHIS-3260 

Go to the Document template designer and replace the existing word documents of ALR Document templates with the below.

InvoiceTemplate
Unit Receipt Template
Renewal Receipt Template
Renewal Invoice_Templates
Renewal Invoice
Late Fee Invoice
Late Fee Invoice Template
Application Fee Receipt Template
ReceiptTemplate

[x] EHIS-3260

Recheck the data in Decision matrix data for Dairy plant licence should have “ce”  at end

[x] EHIS-3292

[x] EHIS-3344 
Data Load on Lab Test Master List

[x] EHIS-3378, 3379 ,3292