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


2. EHIS-2810 ,2212 , 1708

[ ] Create Regulatory Authority records in salesforce Instance : 
> Retrieve RecordTypeId of PHOCSRegulatoryAuthority in the Salesforce instance
> Copy RecordTypeId into CSV file,
> Upload the CSV file   into Data Loader or workbench (Insert) and do the

- field mapping:
                - Name: Name
                - RecordType: RecordTypeId


[ ] Create Regulatory Authorization Type records in salesforce Instance :  
> Retrieve RecordTypeId of PHOCSRegulatoryAuthorizationType in the Salesforce instance
> Copy RecordTypeId into CSV file,
> Copy IssuingDepartmentId from PHOCS Regulatory Authority Id records and mapp in the excel
> Upload the CSV file into Data Loader (Insert) and do the 

- field mapping:- 
                - Name: Name
                - RecordTypeId: RecordTypeId
                - RegulatoryAuthCategory: RegulatoryAuthCategory 
                - RegulatoryAuthorityId;s: IssuingDepartmentId


3. EHIS-1713

1. Create Regulatory code records in Salesforce Instance

> Retrieve RecordTypeId of PHOCSRegulatorycode in the Salesforce instance
> Copy RecordTypeId into CSV file
> Map RegulatoryAuthority Id's in the excel 
> Upload the CSV file into Data Loader (Insert) and do the mapping 

- field mapping:- 
                - Name: Name
                - RecordTypeId: RecordTypeId 
                - RegulatoryAuthorityId: RegulatoryAuthorityId
                - Effective from (created date)
                - Subject
                - Description

2. Create Assessment Indicator Definition Parent Questions

> Retrieve RecordTypeId of PHOCSAssessmentIndicator definition in the Salesforce instance
> Copy RecordTypeId into CSV file
> Map RecordTypeId, category , datatype , Name(Parentquestions)
Upload the CSV file into Data Loader (Insert)

Map : Category__c - Parent categories 
      Name - Parent questions
      Criticality__c	
      DataType- string
      RecordTypeId - Phocs record typeId

3. Create Assessment Indicator Definition Child Questions

> Retrieve RecordTypeId of PHOCSAssessmentIndicator definition in the Salesforce instance
> Copy RecordTypeId into CSV file
> Map RecordTypeId, category , datatype , Name(Childquestions)
Upload the CSV file into Data Loader (Insert)

Map : Category__c - Child categories 
      Name - Child questions
      Criticality__c	
      DataType- Boolean
      RecordTypeId - Phocs record typeId


4. Map Child with Parent questions

> Copy Parent results 
> In another tab copy child results Id, Name(childquestions) , category - A,B,C coloumns
> In D column Map Parent category and in E column map Parent names to each questions 
> In Parent results arrange columns - In c column add Parent category , D column add Parent Names and in E column add Id of parent results
> Now in F column do vlookup 
Formula
> =XLOOKUP(D2&"|"&E2,Parentresults!C:C&"|"&Parentresults!D:D,Parentresults!E:E)

> Once parent Id's are populated 
> Map child results Id's with the Vlookup results
> Do update operation

5. Map LPI Assessment Task Indicator Definition

> Retrieve RecordTypeId of PHOCSAssessmentIndicatordefinition in the Salesforce instance
> Copy RecordTypeId into CSV file
> In one tab or excel copy results of AssessmentIndicatordefinition , AssessmentTaskdefinition results 
> In A, B ,C column copy Name , Category and Id's of AssessmentIndicatordefinition
> In D,E,F column copy Name , Id;s of AssessmentTaskdefinition
> Now do Vlookup to category column of AID and ATD category and Id's 
>=VLOOKUP(B2,E:F,2,0)
> Insert Operation

5. Map Dairy Assessment Task Indicator Definition
> Copy results of Assessment Task definition in A (Name ), B (Id) column 
> Copy Reults of Assessment Indicator definition 
 - Add Parent and child Id's in same column 
 - Add Parent category and child category in same column
 - do vlookup for AID category and ATD Category and ID
 - you will get ATD Id's vlookup to AID Id's
 - Insert Operation

 - field mapping:- 
                - AssessmentTaskdefinitionId
                - AssessmentInddefinitionId

6. Map Parent and Child Regulatory codes with ParentAssessmentIndicatordefinition and ChildAssessmentIndicatordefinition questions
> Copy results of ParentAssessmentIndicatordefinition
> Copy results of ChildAssessmentIndicatordefinition
> Copy results of Regulatory codes
> Use the reference file for mapping Parent questions with RC and child questions with RC based on category (9.ReferencefileDairyRegulatoryCodeAssessmentInd)and arrange columns as per refernece file and use the same lookup

> Here we are getting Regulatory code Id's using vlookup for parent and child questions and AssessmentIndDefindition Id's using Xlookup

- field mapping:- 
                - RegulatorycodeId
                - AssessmentInddefinitionId


7. [ ] Create record EHIS-3093

Record Type : PHOCS Assessment Indicator Definition
Name : Instructions for the operator (outcomes of environmental swabbing or monthly product evaluations)
Category : Directive to operators 
Indicatory Field Type : Text
Criticality : Non-Critical
ParentId : Null


Verification steps
1.2212
2.3378