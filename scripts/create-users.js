#!/usr/bin/env node
/**
 * Bulk User Creation Script — Sandbox Refresh
 * ─────────────────────────────────────────────
 * Reads sandbox-refresh-csvs/users.xlsx, picks the sheet matching the
 * environment name, and creates/updates users + permissions in the target org.
 *
 * Usage (org auto-resolved from sheet name):
 *   node scripts/create-users.js --sheet Dev
 *   node scripts/create-users.js --sheet QA  --dry-run
 *
 * Usage (explicit org override):
 *   node scripts/create-users.js --sheet Dev --target-org PHOCS_Dev
 *
 * Options:
 *   --sheet, -s            Sheet name (Dev | ST | QA | UAT | PreProd | ...)
 *   --target-org, -o       SF CLI org alias — overrides SHEET_ORG_MAP below
 *   --file                 Override xlsx path (default: sandbox-refresh-csvs/users.xlsx)
 *   --dry-run, -d          Preview all actions without writing to org
 *   --skip-permissions     Skip PS / PSG / PG assignment
 *
 * Prerequisites:
 *   sf login org --alias <alias>    (per target org, one-time)
 */
'use strict';

const { spawnSync } = require('child_process');
const fs   = require('fs');
const path = require('path');

// ─── Configuration ─────────────────────────────────────────────────────────────

/**
 * Sheet name → SF CLI org alias mapping.
 * --target-org flag overrides this if provided.
 * Update aliases here to match your sf org list.
 */
const SHEET_ORG_MAP = {
  Dev:     'PHOCS_Dev',
  Dev2:    'Phocs/Dev2',
  ST:      'PHOCS_ST',
  QA:      'PHOCS/QA',
  UAT:     'PHOCS/UAT',
  UAT_Test_Users: 'PHOCS/UAT',
  PreProd: 'Phocspreprod',
};

/** Sheets that receive only User + Profile (no PS / PSG / PG). Empty — all sheets get full permissions. */
const NO_PERMISSIONS_SHEETS = [];

/** SF User fields to carry from the sheet directly into the upsert CSV. */
const USER_SF_FIELDS = [
  'FirstName', 'LastName', 'Email', 'Username', 'Alias',
  'Title', 'Department', 'Phone', 'MobilePhone',
  'FederationIdentifier',
  'TimeZoneSidKey', 'LocaleSidKey', 'EmailEncodingKey', 'LanguageLocaleKey',
  'IsActive',
];

/** Required columns that must be present in every sheet. */
const REQUIRED_COLS = [
  'FirstName', 'LastName', 'Email', 'Username', 'Alias',
  'Profile', 'TimeZoneSidKey', 'LocaleSidKey',
  'EmailEncodingKey', 'LanguageLocaleKey', 'IsActive',
];

const ROOT_DIR     = path.resolve(__dirname, '..');
const CSV_DIR      = path.join(ROOT_DIR, 'sandbox-refresh-csvs');
const TMP_DIR      = path.join(CSV_DIR, '.tmp');
const DEFAULT_XLSX = path.join(CSV_DIR, 'users.xlsx');

// ─── CLI arg parsing ────────────────────────────────────────────────────────────

const args      = process.argv.slice(2);
const getArg    = (f) => { const i = args.indexOf(f); return i !== -1 ? args[i + 1] : null; };
const hasFlag   = (f) => args.includes(f);

const sheet     = getArg('--sheet')      ?? getArg('-s');
const targetOrg = getArg('--target-org') ?? getArg('-o') ?? SHEET_ORG_MAP[sheet];
const xlsxFile  = getArg('--file')       ?? DEFAULT_XLSX;
const dryRun    = hasFlag('--dry-run')   || hasFlag('-d');
const skipPerms = hasFlag('--skip-permissions') || NO_PERMISSIONS_SHEETS.includes(sheet);

if (!sheet) {
  console.error(`
  Usage: node scripts/create-users.js --sheet <name> [options]

  Required:
    --sheet, -s        Sheet name (Dev | ST | QA | UAT | PreProd)
                       Org is auto-resolved from SHEET_ORG_MAP — override with --target-org
    --target-org, -o   SF CLI org alias

  Optional:
    --file             Path to xlsx (default: sandbox-refresh-csvs/users.xlsx)
    --dry-run, -d      Preview without writing to org
    --skip-permissions Skip PS / PSG / PG step
`);
  process.exit(1);
}

// ─── Logging ───────────────────────────────────────────────────────────────────

const LOG_DIR      = path.join(ROOT_DIR, 'sandbox-refresh-csvs', 'logs');
const LOG_FILE     = path.join(LOG_DIR, `create-users_${sheet ?? 'unknown'}_${new Date().toISOString().replace(/[:.]/g, '-')}.csv`);
const RUN_BY       = process.env.USERNAME ?? process.env.USER ?? 'unknown';
const RUN_TS       = new Date().toISOString();
const LOG_RETENTION_DAYS = 15;
fs.mkdirSync(LOG_DIR, { recursive: true });

/** Delete log files older than LOG_RETENTION_DAYS. */
function purgeOldLogs() {
  const cutoff = Date.now() - LOG_RETENTION_DAYS * 24 * 60 * 60 * 1000;
  const deleted = [];
  for (const f of fs.readdirSync(LOG_DIR)) {
    const fp = path.join(LOG_DIR, f);
    if (fs.statSync(fp).mtimeMs < cutoff) { fs.unlinkSync(fp); deleted.push(f); }
  }
  if (deleted.length) log(`Purged ${deleted.length} log file(s) older than ${LOG_RETENTION_DAYS} days.`);
}
purgeOldLogs();

const log  = (m) => console.log(`[INFO]  ${m}`);
const warn = (m) => console.warn(`[WARN]  ${m}`);
const fail = (m) => { console.error(`[ERROR] ${m}`); process.exit(1); };

/** Write the summary CSV log — one row per user. */
function writeSummaryLog(rows) {
  const headers = [
    'Timestamp', 'Sheet', 'Org', 'RunBy',
    'Username', 'FirstName', 'LastName', 'Email', 'Profile',
    'PermissionSets', 'PermissionSetGroups', 'PublicGroups',
    'PS_Inserted', 'PSG_Inserted', 'PG_Inserted',
  ];
  const lines = [
    headers.join(','),
    ...rows.map(r => headers.map(h => csvCell(r[h] ?? '')).join(',')),
  ];
  fs.writeFileSync(LOG_FILE, lines.join('\n'), 'utf8');
  log(`Log saved: ${LOG_FILE}`);
}

/** Escape a value for inclusion in a CSV cell. */
function csvCell(v) {
  const s = String(v ?? '');
  return s.includes(',') || s.includes('"') || s.includes('\n')
    ? `"${s.replace(/"/g, '""')}"` : s;
}

/** Write an array of objects to a CSV file. Returns false if array is empty. */
function writeCsv(filePath, rows) {
  if (!rows.length) return false;
  const headers = Object.keys(rows[0]);
  const lines   = [
    headers.join(','),
    ...rows.map(r => headers.map(h => csvCell(r[h])).join(',')),
  ];
  fs.writeFileSync(filePath, lines.join('\n').replace(/\r/g, ''), 'utf8');
  log(`  Written: ${filePath}  (${rows.length} rows)`);
  return true;
}

/** Escape single quotes for inclusion inside Apex string literals. */
const apexStr = (s) => String(s).replace(/'/g, "\\'");

/** Split a semicolon-delimited cell value into a trimmed array. */
const splitList = (v) =>
  v ? String(v).split(';').map(s => s.trim()).filter(Boolean) : [];

/**
 * Run an SF CLI command via spawnSync (no shell — avoids Windows quoting issues with / in aliases).
 * @param {string[]} sfArgs      Arguments to pass to `sf`
 * @param {boolean}  allowFail   If true, return parsed JSON even on non-zero exit (bulk jobs)
 */
function sfRun(sfArgs, allowFail = false) {
  if (dryRun) { log(`[DRY RUN] sf ${sfArgs.join(' ')}`); return null; }
  log(`Running: sf ${sfArgs.join(' ')}`);
  const [exe, args] = process.platform === 'win32'
    ? ['cmd.exe', ['/c', 'sf.cmd', ...sfArgs]]
    : ['sf', sfArgs];
  const result = spawnSync(exe, args, { encoding: 'utf8' });
  if (result.error) throw new Error(`Failed to spawn sf: ${result.error.message}`);
  const out = result.stdout ?? '';
  if (result.status !== 0 && !allowFail) {
    let msg = result.stderr ?? out;
    try { const j = JSON.parse(out); msg = j.message ?? msg; } catch { /* ignore */ }
    throw new Error(msg);
  }
  try { return JSON.parse(out); } catch { return null; }
}

/** Execute a SOQL query via SF CLI and return records[]. */
function soqlQuery(soql) {
  if (dryRun) { log(`[DRY RUN] SOQL: ${soql}`); return []; }
  const result = sfRun(['data', 'query', '--query', soql, '--target-org', targetOrg, '--json']);
  if (!result || result.status !== 0) throw new Error(`SOQL failed: ${soql}`);
  return result.result.records ?? [];
}

/**
 * Bulk upsert a CSV file against a Salesforce object.
 * Users only — PermissionSetAssignment / GroupMember need Apex (no external ID field).
 */
function bulkUpsert(csvPath, sobject, externalId) {
  const result = sfRun([
    'data', 'upsert', 'bulk',
    '--file', csvPath,
    '--sobject', sobject,
    '--external-id', externalId,
    '--target-org', targetOrg,
    '--line-ending', 'LF',
    '--wait', '10',
    '--json',
  ], true); // allowFail=true — bulk jobs return non-zero on partial failures
  if (!result) return; // dry run

  // result.result may be nested under jobInfo depending on SF CLI version
  const info = result.result?.jobInfo ?? result.result ?? {};
  const processed = info.numberRecordsProcessed ?? '?';
  const failed    = info.numberRecordsFailed ?? '?';
  log(`  Processed: ${processed} | Failed: ${failed}`);
  if (Number(failed) > 0) {
    warn(`  ${failed} record(s) failed — check the bulk job in Setup > Bulk Data Load Jobs for row-level errors.`);
  }
}

/**
 * Execute an Apex anonymous script file.
 * Used for PS / PSG / PG assignments that cannot use Bulk API upsert.
 */
/** Returns { inserted, failed } parsed from Apex System.debug output. */
function runApex(apexFile) {
  const result = sfRun(['apex', 'run', '--file', apexFile, '--target-org', targetOrg, '--json']);
  if (!result) return { inserted: 0, failed: 0 }; // dry run
  if (result.status !== 0) throw new Error(`Apex execute failed: ${result.message}`);
  const logs = result.result?.logs ?? '';
  const debugLines = logs.split('\n').filter(l => l.includes('USER_DEBUG'));
  let inserted = 0, failed = 0;
  debugLines.forEach(l => {
    const msg = l.split('DEBUG|').pop()?.trim() ?? l;
    log(`  Apex: ${msg}`);
    const m = msg.match(/inserted:\s*(\d+).*?failed[^:]*:\s*(\d+)/i);
    if (m) { inserted = parseInt(m[1]); failed = parseInt(m[2]); }
  });
  return { inserted, failed };
}

/**
 * Build and execute an Apex script to insert permission/group assignments.
 *
 * @param {'PS'|'PSG'|'PG'} type
 * @param {{ username: string, itemName: string }[]} assignments
 */
function apexAssign(type, assignments) {
  if (!assignments.length) return;
  // Normalize usernames to lowercase — Salesforce stores them lowercase; Apex Map.get() is case-sensitive
  assignments = assignments.map(a => ({ ...a, username: a.username.toLowerCase() }));

  const usernames  = [...new Set(assignments.map(a => a.username))];
  const itemNames  = [...new Set(assignments.map(a => a.itemName))];
  const apexQuote  = (arr) => arr.map(s => `'${apexStr(s)}'`).join(',');

  let queryBlock, insertBlock, listType;

  if (type === 'PS') {
    listType    = 'PermissionSetAssignment';
    queryBlock  = [
      `Map<String,Id> pMap=new Map<String,Id>();`,
      `for(PermissionSet p:[SELECT Id,Name FROM PermissionSet`,
      ` WHERE IsOwnedByProfile=false AND Name IN (${apexQuote(itemNames)})])`,
      ` pMap.put(p.Name,p.Id);`,
    ].join('');
    insertBlock = assignments.map(a =>
      `if(uMap.get('${apexStr(a.username)}')!=null&&pMap.get('${apexStr(a.itemName)}')!=null)` +
      ` rows.add(new PermissionSetAssignment(AssigneeId=uMap.get('${apexStr(a.username)}'),` +
      `PermissionSetId=pMap.get('${apexStr(a.itemName)}')));`
    ).join('\n');
  } else if (type === 'PSG') {
    listType    = 'PermissionSetAssignment';
    queryBlock  = [
      `Map<String,Id> pMap=new Map<String,Id>();`,
      `for(PermissionSetGroup g:[SELECT Id,MasterLabel FROM PermissionSetGroup`,
      ` WHERE MasterLabel IN (${apexQuote(itemNames)})])`,
      ` pMap.put(g.MasterLabel,g.Id);`,
    ].join('');
    insertBlock = assignments.map(a =>
      `if(uMap.get('${apexStr(a.username)}')!=null&&pMap.get('${apexStr(a.itemName)}')!=null)` +
      ` rows.add(new PermissionSetAssignment(AssigneeId=uMap.get('${apexStr(a.username)}'),` +
      `PermissionSetGroupId=pMap.get('${apexStr(a.itemName)}')));`
    ).join('\n');
  } else { // PG
    listType    = 'GroupMember';
    queryBlock  = [
      `Map<String,Id> pMap=new Map<String,Id>();`,
      `for(Group g:[SELECT Id,DeveloperName FROM Group`,
      ` WHERE Type='Regular' AND DeveloperName IN (${apexQuote(itemNames)})])`,
      ` pMap.put(g.DeveloperName,g.Id);`,
    ].join('');
    insertBlock = assignments.map(a =>
      `if(uMap.get('${apexStr(a.username)}')!=null&&pMap.get('${apexStr(a.itemName)}')!=null)` +
      ` rows.add(new GroupMember(UserOrGroupId=uMap.get('${apexStr(a.username)}'),` +
      `GroupId=pMap.get('${apexStr(a.itemName)}')));`
    ).join('\n');
  }

  const apexCode = [
    `// Auto-generated by create-users.js — ${type} assignments for sheet: ${sheet}`,
    `// ${new Date().toISOString()}`,
    `Map<String,Id> uMap=new Map<String,Id>();`,
    `for(User u:[SELECT Id,Username FROM User WHERE Username IN (${apexQuote(usernames)}) AND IsActive=true])`,
    ` uMap.put(u.Username.toLowerCase(),u.Id);`,
    queryBlock,
    `List<${listType}> rows=new List<${listType}>();`,
    insertBlock,
    `System.debug('${type} uMap size: '+uMap.size()+' | pMap size: '+pMap.size());`,
    `Database.SaveResult[] sr = Database.insert(rows, false); // allOrNone=false: skip duplicates`,
    `Integer ok=0,fail=0;`,
    `for(Database.SaveResult r:sr){ if(r.isSuccess()) ok++; else fail++; }`,
    `System.debug('${type} assignments — inserted: '+ok+' | failed/duplicate: '+fail);`,
  ].join('\n');

  const apexFile = path.join(TMP_DIR, `assign_${type.toLowerCase()}_${sheet}.apex`);
  fs.writeFileSync(apexFile, apexCode, 'utf8');
  log(`  Apex file: ${apexFile}`);

  if (dryRun) {
    log('  [DRY RUN] Apex preview:');
    console.log(apexCode.split('\n').map(l => '    ' + l).join('\n'));
    return { inserted: 0, failed: 0 };
  }

  return runApex(apexFile);
}

// ─── Main ──────────────────────────────────────────────────────────────────────

function main() {
  // ── 0. Check xlsx dependency ──────────────────────────────────────────────
  let xlsx;
  try { xlsx = require('xlsx'); } catch {
    fail('Missing dependency: xlsx\n  Fix: npm install --save-dev xlsx');
  }

  if (!targetOrg) {
    fail(`No org mapped for sheet "${sheet}".\n  Either add it to SHEET_ORG_MAP or pass --target-org <alias>.`);
  }

  log('='.repeat(60));
  log(`Sheet: ${sheet}  |  Org: ${targetOrg}  |  DryRun: ${dryRun}  |  SkipPerms: ${skipPerms}`);
  log('='.repeat(60));

  // ── 1. Load workbook ──────────────────────────────────────────────────────
  if (!fs.existsSync(xlsxFile)) fail(`File not found: ${xlsxFile}\n  Run: node scripts/generate-template.js`);

  const wb = xlsx.readFile(xlsxFile);
  if (!wb.SheetNames.includes(sheet)) {
    fail(`Sheet "${sheet}" not found.\n  Available: ${wb.SheetNames.join(', ')}`);
  }

  const rows = xlsx.utils.sheet_to_json(wb.Sheets[sheet], { defval: '' });
  if (!rows.length) { warn('Sheet is empty — nothing to do.'); return; }
  log(`Loaded ${rows.length} user row(s) from sheet "${sheet}"`);

  // ── 2. Validate required columns ──────────────────────────────────────────
  const sheetCols = Object.keys(rows[0]);
  const missing   = REQUIRED_COLS.filter(c => !sheetCols.includes(c));
  if (missing.length) fail(`Missing required column(s): ${missing.join(', ')}`);

  // ── 3. Resolve Profile names → IDs ───────────────────────────────────────
  log('\n--- Step 1 of 5: Resolve Profile IDs ---');
  const profileNames = [...new Set(rows.map(r => r.Profile).filter(Boolean))];
  if (!profileNames.length) fail('No Profile values found in sheet.');

  const profileRecords = soqlQuery(
    `SELECT Id, Name FROM Profile WHERE Name IN (${profileNames.map(n => `'${apexStr(n)}'`).join(',')})`
  );
  const profileMap = Object.fromEntries(profileRecords.map(p => [p.Name, p.Id]));

  const unknownProfiles = profileNames.filter(n => !profileMap[n] && !dryRun);
  if (unknownProfiles.length) fail(`Profile(s) not found in org: ${unknownProfiles.join(', ')}`);

  // ── 4. Build user CSV ─────────────────────────────────────────────────────
  log('\n--- Step 2 of 5: Build Users CSV ---');
  fs.mkdirSync(TMP_DIR, { recursive: true });

  const userRows = rows.map(r => {
    const u = {};
    USER_SF_FIELDS.forEach(f => { if (r[f] !== undefined) u[f] = r[f]; });
    u.ProfileId = profileMap[r.Profile] ?? r.Profile; // fallback to name in dry-run
    return u;
  });

  const usersCsv = path.join(TMP_DIR, `1_users_${sheet}.csv`);
  writeCsv(usersCsv, userRows);

  // ── 5. Upsert users ───────────────────────────────────────────────────────
  log('\n--- Step 3 of 5: Upsert Users ---');
  bulkUpsert(usersCsv, 'User', 'Username');

  // ── 6. Permissions ────────────────────────────────────────────────────────
  if (skipPerms) {
    const reason = NO_PERMISSIONS_SHEETS.includes(sheet)
      ? `sheet "${sheet}" is in NO_PERMISSIONS_SHEETS`
      : '--skip-permissions flag';
    log(`\nSkipping permissions — ${reason}`);
    log('\n' + '='.repeat(60));
    log('Done.');
    return;
  }

  // Gather all assignment pairs
  const psAssign  = []; // { username, itemName }
  const psgAssign = [];
  const pgAssign  = [];

  for (const r of rows) {
    const u = String(r.Username ?? '').trim();
    if (!u) continue;
    splitList(r.PermissionSets).forEach(n       => psAssign.push( { username: u, itemName: n }));
    splitList(r.PermissionSetGroups).forEach(n  => psgAssign.push({ username: u, itemName: n }));
    splitList(r.PublicGroups).forEach(n         => pgAssign.push( { username: u, itemName: n }));
  }

  // ── 7. Permission Set assignments ─────────────────────────────────────────
  log('\n--- Step 4 of 5: Permission Set Assignments ---');
  let psResult = { inserted: 0, failed: 0 };
  if (psAssign.length) {
    log(`  ${psAssign.length} PS assignment(s) across ${[...new Set(psAssign.map(a=>a.itemName))].length} unique sets`);
    psResult = apexAssign('PS', psAssign) ?? psResult;
  } else {
    log('  No Permission Sets specified — skipping.');
  }

  // ── 8. Permission Set Group assignments ───────────────────────────────────
  log('\n--- Step 5 of 5: PSG & Public Group Assignments ---');
  let psgResult = { inserted: 0, failed: 0 };
  if (psgAssign.length) {
    log(`  ${psgAssign.length} PSG assignment(s) across ${[...new Set(psgAssign.map(a=>a.itemName))].length} unique groups`);
    psgResult = apexAssign('PSG', psgAssign) ?? psgResult;
  } else {
    log('  No Permission Set Groups specified — skipping.');
  }

  // ── 9. Public Group memberships ───────────────────────────────────────────
  let pgResult = { inserted: 0, failed: 0 };
  if (pgAssign.length) {
    log(`  ${pgAssign.length} Public Group membership(s)`);
    pgResult = apexAssign('PG', pgAssign) ?? pgResult;
  } else {
    log('  No Public Groups specified — skipping.');
  }

  // ── 10. Write summary log ─────────────────────────────────────────────────
  const summaryRows = rows.map(r => ({
    Timestamp:           RUN_TS,
    Sheet:               sheet,
    Org:                 targetOrg,
    RunBy:               RUN_BY,
    Username:            r.Username,
    FirstName:           r.FirstName,
    LastName:            r.LastName,
    Email:               r.Email,
    Profile:             r.Profile,
    PermissionSets:      r.PermissionSets      ?? '',
    PermissionSetGroups: r.PermissionSetGroups ?? '',
    PublicGroups:        r.PublicGroups        ?? '',
    PS_Inserted:         psResult.inserted,
    PSG_Inserted:        psgResult.inserted,
    PG_Inserted:         pgResult.inserted,
  }));
  writeSummaryLog(summaryRows);

  log('\n' + '='.repeat(60));
  log('Done. All steps completed successfully.');
}

main();
