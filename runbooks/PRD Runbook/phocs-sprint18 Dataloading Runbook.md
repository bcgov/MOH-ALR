|Sandbox|`Runbook for PRD from SP-3 to SP18'|
|-|-|
|Runbook Created|`2026-02-23`|
|Runbook Last Modified|`2026-02-23`|

1. [ ] EHIS - 2998 , 1621

Create the following new Inspection Type records using the existing PHOCS Inspection Type record type:
> Retrieve RecordTypeId of PHOCSInspectionType in the Salesforce instance
> Copy RecordTypeId into CSV file,
> Upload the CSV file   into Data Loader or workbench (Insert) and do the 

- field mapping:
                - Name: Name
                - RecordType: RecordTypeId


4. 2810 ,2212 , 1708

[ ] Create Regulatory Authority records in salesforce Instance : 
> Retrieve RecordTypeId of PHOCSRegulatoryAuthorizationType in the Salesforce instance
> Copy RecordTypeId into CSV file,
> Upload the CSV file   into Data Loader or workbench (Insert) and do the

- field mapping:
                - Name: Name
                - RecordType: RecordTypeId


[ ] Create Regulatory Authorization Type records in salesforce Instance :  
> Retrieve RecordTypeId of PHOCSRegulatoryAuthorizationType in the Salesforce instance
> Copy RecordTypeId into CSV file,
> Copy IssuingDepartmentId from PHOCS Regulatory Authority 
> Upload the CSV file into Data Loader (Insert) and do the 

- field mapping:- 
                - Name: Name
                - RecordTypeId: RecordTypeId
                - RegulatoryAuthCategory: RegulatoryAuthCategory 
                - IssuingDepartmentId: IssuingDepartmentId


Verification steps
1.2212
2.3378