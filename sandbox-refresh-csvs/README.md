# Sandbox Refresh — Bulk User Creation

Creates users with full permissions (Profile, Permission Sets, Permission Set Groups, Public Groups) in a target Salesforce org by reading from `users.xlsx`.

---

## Installation & Setup

### 1. Install Node.js
Download and install from https://nodejs.org (LTS version recommended).
Verify:
```bash
node -v   # should print v18 or higher (v20+ recommended)
npm -v
```

### 2. Install Salesforce CLI
```bash
npm install --global @salesforce/cli
```
Verify:
```bash
sf --version
```

### 3. Install project dependencies (one-time)
Run this from the repo root:
```bash
npm install
```
This installs the `xlsx` package (used to read `users.xlsx`). Verify:
```bash
node -e "require('xlsx'); console.log('OK')"
```

### 4. Authenticate target orgs
Run once per org. Use the alias that matches `SHEET_ORG_MAP` in `scripts/create-users.js`.
```bash
sf org login web --alias PHOCS_Dev
sf org login web --alias Phocs/Dev2
sf org login web --alias PHOCS/QA
sf org login web --alias PHOCS/UAT
sf org login web --alias Phocspreprod
```
Verify all connected orgs:
```bash
sf org list
```

---

## Prerequisites Checklist

| Requirement | Verify with | Expected output |
|-------------|-------------|-----------------|
| Node.js | `node -v` | `v18.x.x` or higher |
| SF CLI | `sf --version` | version string |
| xlsx package | `node -e "require('xlsx')"` | no error |
| Org authenticated | `sf org list` | alias listed as Connected |

---

## File: `users.xlsx`

One sheet per environment. Each row = one user.

| Column | Required | Notes |
|--------|----------|-------|
| `FirstName` | ✅ | |
| `LastName` | ✅ | |
| `Email` | ✅ | |
| `Username` | ✅ | Must be unique across Salesforce. Use env suffix e.g. `jane@gov.bc.ca.qa` |
| `Alias` | ✅ | Max 8 chars, no spaces |
| `Profile` | ✅ | Exact profile name as it appears in the org |
| `TimeZoneSidKey` | ✅ | e.g. `America/Vancouver` |
| `LocaleSidKey` | ✅ | e.g. `en_CA` |
| `EmailEncodingKey` | ✅ | e.g. `UTF-8` |
| `LanguageLocaleKey` | ✅ | e.g. `en_US` |
| `IsActive` | ✅ | `TRUE` or `FALSE` |
| `FederationIdentifier` | — | IDIR / SSO identifier |
| `Title` | — | Job title |
| `Department` | — | |
| `Phone` | — | |
| `MobilePhone` | — | |
| `PermissionSets` | — | Semicolon-separated PS API names e.g. `EHIS_Admin_User_PS;PHOCSREADReportingUser` |
| `PermissionSetGroups` | — | Semicolon-separated PSG labels e.g. `EHIS Business Admin PSG;PHOCS System Administrator PSG` |
| `PublicGroups` | — | Semicolon-separated Group DeveloperNames e.g. `EHISUsersPG;PHOCSReportingUserPG` |

### Sheet → Org mapping

| Sheet | Target Org Alias |
|-------|-----------------|
| Dev | PHOCS_Dev |
| ST | PHOCS_ST |
| QA | PHOCS/QA |
| UAT | PHOCS/UAT |
| PreProd | Phocspreprod |

> To add a new environment, add a row to `SHEET_ORG_MAP` in `scripts/create-users.js`.

---

## Commands

### Dry run — validate without touching the org
```bash
node scripts/create-users.js --sheet Dev --dry-run
```
Shows exactly what will be created. Always run this first.

### Create users
```bash
node scripts/create-users.js --sheet Dev
node scripts/create-users.js --sheet Dev2
node scripts/create-users.js --sheet QA
node scripts/create-users.js --sheet UAT
node scripts/create-users.js --sheet UAT_Test_Users
node scripts/create-users.js --sheet PreProd
```

### Create users only (skip PS / PSG / PG)
```bash
node scripts/create-users.js --sheet Dev --skip-permissions
```

### Override org alias
```bash
node scripts/create-users.js --sheet Dev --target-org SomeOtherAlias
```

### Use a different xlsx file
```bash
node scripts/create-users.js --sheet Dev --file path/to/other.xlsx
```

---

## Reset Passwords

Sends a password reset email to all active users listed in a sheet. Run this separately after user creation.

### Dry run — preview without sending
```bash
node scripts/reset-passwords.js --sheet Dev --dry-run
```

### Send password reset emails
```bash
node scripts/reset-passwords.js --sheet Dev
node scripts/reset-passwords.js --sheet QA
node scripts/reset-passwords.js --sheet UAT
node scripts/reset-passwords.js --sheet PreProd
```

### Override org alias
```bash
node scripts/reset-passwords.js --sheet Dev --target-org SomeOtherAlias
```

> This script is intentionally separate from `create-users.js` — run it only when you want to trigger reset emails.

---

## What the script does (in order)

1. Reads the specified sheet from `users.xlsx`
2. Validates all required columns are present
3. Resolves Profile names to IDs via SOQL
4. Upserts users using `sf data upsert bulk` — safe to re-run (updates existing users)
5. Assigns Permission Sets via Apex anonymous execute
6. Assigns Permission Set Groups via Apex anonymous execute
7. Adds users to Public Groups via Apex anonymous execute

> Steps 5–7 use `allOrNone=false` — duplicate assignments are silently skipped.

---

## Temp files

After a run, inspect what was sent to Salesforce:

```
sandbox-refresh-csvs/.tmp/
  1_users_<sheet>.csv          ← user payload sent to Bulk API
  assign_ps_<sheet>.apex       ← Permission Set assignment script
  assign_psg_<sheet>.apex      ← Permission Set Group assignment script
  assign_pg_<sheet>.apex       ← Public Group membership script
```

These are gitignored and safe to delete after verifying results.
