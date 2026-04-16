# SFDMU — Food Inspection Data Migration
**Stories:** EHIS-3137 + EHIS-3138  
**Source org:** Phocs/Dev2  
**Objects:** 6 (in dependency order)

---

## Prerequisites

```bash
# Install SFDMU plugin (one-time)
sf plugins install sfdmu

# Verify installation
sf sfdmu --version

# Check authenticated orgs
sf org list
```

---

## Commands

### 1. Org → Org (direct migration — no files involved)
Migrates data directly from source org to target org in memory. Fastest option. Use for Dev2 → QA → UAT → PreProd.

```bash
sf sfdmu run export --sourceusername "Phocs/Dev2" --targetusername "PHOCS/QA" --path "sfdmu/food-inspection-data"
```

Replace `PHOCS/QA` with any target alias: `PHOCS/UAT`, `Phocspreprod`, etc.

---

### 2. Org → Local (export org data to CSV files)
Reads from the source org and writes each object's data into a CSV file in this folder. Use this to snapshot Dev2 data or to review before importing.

```bash
sf sfdmu run export --sourceusername "Phocs/Dev2" --targetusername csvfile --path "sfdmu/food-inspection-data"
```

Writes these files into `sfdmu/food-inspection-data/`:
- `RegulatoryAuthority.csv`
- `RegulatoryCode.csv`
- `AssessmentIndicatorDefinition.csv`
- `RegulatoryCodeAssessmentInd.csv`
- `AssessmentTaskDefinition.csv`
- `AssessmentTaskIndDefinition.csv`

---

### 3. Local → Org (import CSV files into target org)
Reads data from the CSV files in this folder and upserts into the target org. Use this for Production where you want a reviewable paper trail before import.

Uses `export-seed.json` (not `export.json`) — the seed file uses a 2-field `externalId` on `AssessmentIndicatorDefinition` (`Name;Category__c`) so SFDMU can match child records correctly without needing to resolve parent IDs from the CSV.

**Dairy:**
```bash
sf sfdmu run export --sourceusername csvfile --targetusername "Phocs/UAT" --path "sfdmu/dairy-data" --config "export-seed.json"
```

**Food:**
```bash
sf sfdmu run export --sourceusername csvfile --targetusername "Phocs/UAT" --path "sfdmu/food-inspection-data" --config "export-seed.json"
```

**PSE:**
```bash
sf sfdmu run export --sourceusername csvfile --targetusername "Phocs/UAT" --path "sfdmu/pse-inspection-data" --config "export-seed.json"
```

Replace `Phocs/UAT` with any target alias: `Phocspreprod`, etc.

> **Note:** CSV files must exist in the pipeline folder before running. Either run the Org → Local command first, or export each sheet from the Excel as CSV and place them here.

> **Why two config files?**  
> `export.json` — org-to-org migrations (Dev2 → QA → UAT). Uses 3-field AID externalId (`Name;Category__c;PHOCSParentId__r.Name`) because SFDMU can resolve parent IDs live from the source org.  
> `export-seed.json` — CSV-to-org / Production seeding. Uses 2-field AID externalId (`Name;Category__c`) because SFDMU cannot resolve relationship-based parent IDs from static CSV files.

---

### 4. With timestamped log (recommended for UAT / PreProd / Prod)

```bash
TARGET="PHOCS/QA"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
sf sfdmu run export \
  --sourceusername "Phocs/Dev2" \
  --targetusername "$TARGET" \
  --path "sfdmu/food-inspection-data" \
  2>&1 | tee "sfdmu/food-inspection-data/migration_${TARGET//\//-}_${TIMESTAMP}.log"
```

---

## Recommended promotion path

```
Dev2 ──(org→org)──▶ QA ──(sign-off)──▶ UAT ──(sign-off)──▶ PreProd ──(sign-off)──▶ Prod
                                                                                       ↑
                                                                              use local→org
                                                                              (CSV as audit trail)
```

> **Do not run org → org directly to Prod.** Use local → org for Production so the CSV files serve as an audit trail and change management evidence.

---

## export.json — Block by Block

### Common properties (every block has these)

| Property | What it does |
|----------|-------------|
| `query` | SOQL to select records from source org. Also defines which fields get inserted/updated in target. |
| `operation` | `Upsert` = insert if record not found, update if found. Safe to re-run — no duplicates created. |
| `externalId` | Field(s) SFDMU uses to match a record in the target org. If a match exists → update. If not → insert. |
| `updateWithNull` | `false` = blank fields in source do not overwrite existing values in target. |
| `excludedFields` | Fields read from source (for audit in Excel/CSV) but never written to target. `CreatedDate`, `CreatedById` etc. are system-managed — Salesforce sets them automatically. |
| `csvFileName` | Name of the CSV file this block reads from (local → org) or writes to (org → local). Links the block to the correct sheet exported from Excel. Ignored in org → org mode. |

---

### Block 1 — RegulatoryAuthority

```json
"query"      : "SELECT ... FROM RegulatoryAuthority WHERE Name IN ('Food Premises Regulation', 'Public Health Act', 'Canadian Food Inspection Agency', 'BCCDC') ...",
"externalId" : "Name",
"csvFileName": "RegulatoryAuthority.csv"
```

**What it does:**  
Pulls the 4 food regulatory authorities by name. `externalId: "Name"` means SFDMU matches records in the target by the `Name` field — if a RegulatoryAuthority with that name already exists it updates it, otherwise it creates it.

**Why BCCDC is included:**  
BCCDC already exists in all orgs (pre-existing Dairy record). Including it here is safe — upsert by Name just updates it in place. It must be here so Block 2 (RegulatoryCode) can resolve the BCCDC lookup by name in the target.

**Must run first** because Block 2 depends on these records existing.

---

### Block 2 — RegulatoryCode

```json
"query"      : "SELECT ... FROM RegulatoryCode WHERE Id IN (SELECT RegulatoryCodeId FROM RegulatoryCodeAssessmentInd WHERE AssessmentIndDefinition.Category__c IN (...food categories...)) ...",
"externalId" : "Name;RegulatoryAuthority.Name",
"csvFileName": "RegulatoryCode.csv"
```

**What it does:**  
Pulls only the regulatory codes that are actually linked to food inspection questions. The `WHERE Id IN (SELECT ...)` subquery navigates from AID categories → RCAI junction → RegulatoryCode, so only food-linked codes are selected. This automatically excludes BCCDC Dairy codes even though BCCDC itself is in Block 1.

**Why composite externalId `Name;RegulatoryAuthority.Name`:**  
Different regulatory authorities can have codes with the same section number (e.g. "Section 3" under Food Premises Regulation vs "Section 3" under another authority). Using `Name` alone would cause wrong matches. The composite ensures SFDMU matches on both the code name AND the authority name together.

**How the lookup resolves:**  
`RegulatoryAuthority.Name` in the SELECT tells SFDMU to resolve `RegulatoryAuthorityId` in the target by finding the authority by Name — using records created in Block 1.

---

### Block 3 — AssessmentIndicatorDefinition

```json
"query"      : "SELECT ..., PHOCSParentId__r.Name, ... FROM AssessmentIndicatorDefinition WHERE Category__c IN (...food categories...) ... ORDER BY PHOCSParentId__c NULLS FIRST",
"externalId" : "Name",
"csvFileName": "AssessmentIndicatorDefinition.csv"
```

**What it does:**  
Pulls all 126 food AID records — 31 parent questions (DataType = String) and 77 child canned comments (DataType = Boolean) — filtered by the 10 food category names.

**Why `ORDER BY PHOCSParentId__c NULLS FIRST`:**  
SFDMU processes rows in the order they appear in the CSV. Parent records have `PHOCSParentId__c = null` so they sort first. All 31 parents are inserted into the target before any child row is processed. This ensures when SFDMU resolves `PHOCSParentId__r.Name` for a child, the parent already exists in the target.

**How `PHOCSParentId__r.Name` resolves:**  
The `__r.Name` notation tells SFDMU this is a lookup field resolved by Name — not by ID. For each child row:
1. SFDMU reads the value in `PHOCSParentId__r.Name` (e.g. "All food obtained from an approved source.")
2. Looks up that Name in AssessmentIndicatorDefinition in the target org
3. Takes the matching record's Id
4. Sets `PHOCSParentId__c` to that Id

For parent rows where `PHOCSParentId__r.Name` is blank, SFDMU sets `PHOCSParentId__c = null`.

---

### Block 4 — RegulatoryCodeAssessmentInd

```json
"query"      : "SELECT ..., AssessmentIndDefinition.Name, RegulatoryCode.Name FROM RegulatoryCodeAssessmentInd WHERE AssessmentIndDefinition.Category__c IN (...food categories...)",
"externalId" : "AssessmentIndDefinition.Name;RegulatoryCode.Name",
"csvFileName": "RegulatoryCodeAssessmentInd.csv"
```

**What it does:**  
Links each AID record (all 126 — parents and children) to its regulatory code. This is a junction object with no meaningful Name of its own (auto-generated like `RCAI-000001`), so Name cannot be used as externalId — it differs between orgs.

**Why composite externalId `AssessmentIndDefinition.Name;RegulatoryCode.Name`:**  
The unique key for a junction record is the combination of both sides. SFDMU looks up the AID by Name (from Block 3) and the RegCode by Name (from Block 2) in the target, then checks if a junction already links them. If yes → update. If no → create.

**Why filtered by Category__c and not CreatedById:**  
The same user who loaded food data also previously loaded Dairy junction records. Filtering by `CreatedById` would pull both food and Dairy RCAI records. Filtering by food categories is precise and safe.

---

### Block 5 — AssessmentTaskDefinition

```json
"query"      : "SELECT Id, Name, TaskType, ... FROM AssessmentTaskDefinition WHERE Name IN (...11 food ATD names...) ...",
"externalId" : "Name",
"csvFileName": "AssessmentTaskDefinition.csv"
```

**What it does:**  
Pulls the 11 food AssessmentTaskDefinition records by their exact names. ATD names are unique across the org — no Dairy ATD shares a name with any food ATD — so `Name IN (...)` is a safe and precise filter.

**Important field — `TaskType`:**  
`TaskType` is a required non-nullable field on ATD. It must always be `InspectionChecklist`. If omitted during insert the record creation fails. It is included in the SELECT so it is always written to the target.

---

### Block 6 — AssessmentTaskIndDefinition

```json
"query"      : "SELECT ..., AssessmentTaskDefinition.Name, AssessmentIndDefinition.Name FROM AssessmentTaskIndDefinition WHERE AssessmentTaskDefinition.Name IN (...11 food ATD names...)",
"externalId" : "AssessmentTaskDefinition.Name;AssessmentIndDefinition.Name",
"csvFileName": "AssessmentTaskIndDefinition.csv"
```

**What it does:**  
Links each AID record (all 126 — parents and children) to its ATD. Same junction pattern as Block 4 — no meaningful own Name, so composite externalId is used.

**Why composite externalId `AssessmentTaskDefinition.Name;AssessmentIndDefinition.Name`:**  
SFDMU looks up the ATD by Name (from Block 5) and the AID by Name (from Block 3) in the target, then checks if that junction already exists. If yes → update. If no → create.

**Why filtered by ATD names and not CreatedById:**  
Same reason as Block 4 — the same user created both food and Dairy ATID junction records. Filtering by the 11 food ATD names is precise and excludes Dairy.

---

## How all 6 blocks chain together

```
Block 1 — RegulatoryAuthority        (no dependencies)
    |
    └──▶ Block 2 — RegulatoryCode     (needs RA from Block 1)
                |
                └──▶ Block 4 — RCAI   (needs RC from Block 2 + AID from Block 3)

Block 3 — AssessmentIndicatorDefinition
    |         parents inserted first,
    |         then children (PHOCSParentId__r.Name resolved from same block)
    |
    ├──▶ Block 4 — RCAI               (needs AID from Block 3)
    └──▶ Block 6 — ATID               (needs AID from Block 3)

Block 5 — AssessmentTaskDefinition    (no dependencies)
    |
    └──▶ Block 6 — ATID               (needs ATD from Block 5 + AID from Block 3)
```

---

## Not covered here — deploy separately via metadata

```bash
sf project deploy start \
  --metadata "ActionPlanTemplate:Food Premises Inspection" \
  --metadata "ActionPlanTemplate:L1-Food Services Establishment Inspection" \
  --metadata "ActionPlanTemplate:L2-Temporary Food Service Inspection" \
  --metadata "CustomMetadata:PHOCSActionPlanTemplateDecisionMap.Food_APT_Base" \
  --metadata "CustomMetadata:PHOCSActionPlanTemplateDecisionMap.Food_APT_L1_Food_Service_Establishment" \
  --metadata "CustomMetadata:PHOCSActionPlanTemplateDecisionMap.Food_APT_L2_Temporary_Food_Service" \
  --target-org <TARGET_ALIAS>
```

---

## Post-migration verification queries

Run these in the target org after migration to confirm record counts and audit details.

```sql
-- Regulatory Authorities (expect 3 food + BCCDC)
SELECT Name, CreatedDate, CreatedBy.Name
FROM RegulatoryAuthority
WHERE Name IN ('Food Premises Regulation', 'Public Health Act', 'Canadian Food Inspection Agency', 'BCCDC')

-- Regulatory Codes (expect 48)
SELECT COUNT(Id) FROM RegulatoryCode
WHERE Id IN (SELECT RegulatoryCodeId FROM RegulatoryCodeAssessmentInd
             WHERE AssessmentIndDefinition.Category__c IN (
               'Construction of Food Premises', 'Approvals and Permits',
               'Food Sources and Protection', 'Equipment, Utensils and Cleaning',
               'Employee', 'Food Safety Management', 'Miscellaneous',
               'Training', 'Previously Served Food',
               'Temporary Food Service and Inspection Report'))

-- AID count by type (expect 31 parents + 77 children = 108... or 126 if more were loaded)
SELECT DataType, COUNT(Id)
FROM AssessmentIndicatorDefinition
WHERE Category__c IN (
  'Construction of Food Premises', 'Approvals and Permits',
  'Food Sources and Protection', 'Equipment, Utensils and Cleaning',
  'Employee', 'Food Safety Management', 'Miscellaneous',
  'Training', 'Previously Served Food',
  'Temporary Food Service and Inspection Report')
GROUP BY DataType

-- ATD count (expect 11)
SELECT COUNT(Id) FROM AssessmentTaskDefinition
WHERE Name IN (
  'Construction of Food Premises', 'Approvals and Permits',
  'Food Sources and Protection', 'Equipment, Utensils and Cleaning',
  'Employee', 'Food Safety Management', 'Miscellaneous',
  'Permit to Operate Food Service Establishment',
  'Training', 'Previously Served Food',
  'Temporary Food Service and Inspection Report')
```
