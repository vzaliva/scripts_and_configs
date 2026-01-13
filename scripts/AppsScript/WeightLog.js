/**
 * Fitbit Aria -> Google Sheets
 * Requires OAuth2 library (you added v43).
 *
 * Sheet columns:
 * A: DateTime (e.g. "December 10, 2016 at 03:20PM")
 * B: Weight
 * C: Unit (e.g. "pounds")
 * D: BMI (blank allowed)
 * E: LogId (blank for legacy rows)
 */

const FITBIT_AUTH_URL = 'https://www.fitbit.com/oauth2/authorize';
const FITBIT_TOKEN_URL = 'https://api.fitbit.com/oauth2/token';
const FITBIT_SCOPE = 'weight';
const N_DAYS = 14;

const STORE_WEIGHT_IN_POUNDS = true;
const KG_TO_LB = 2.2046226218;

function getFitbitService_() {
  const sp = PropertiesService.getScriptProperties();
  const clientId = sp.getProperty('FITBIT_CLIENT_ID');
  const clientSecret = sp.getProperty('FITBIT_CLIENT_SECRET');

  if (!clientId || !clientSecret) {
    throw new Error('Missing FITBIT_CLIENT_ID / FITBIT_CLIENT_SECRET in Script Properties.');
  }

  // OAuth2 library is provided by the added library.
  return OAuth2.createService('fitbit')
    .setAuthorizationBaseUrl(FITBIT_AUTH_URL)
    .setTokenUrl(FITBIT_TOKEN_URL)
    .setClientId(clientId)
    .setClientSecret(clientSecret)
    .setCallbackFunction('authCallback')
    .setPropertyStore(PropertiesService.getUserProperties())
    .setScope(FITBIT_SCOPE)
    // Fitbit expects Basic auth for token requests:
    .setTokenHeaders({
      Authorization: 'Basic ' + Utilities.base64Encode(clientId + ':' + clientSecret),
      'Content-Type': 'application/x-www-form-urlencoded'
    });
}

/**
 * Run once. Check logs for the URL, open it, approve Fitbit access.
 */
function getAuthorizationUrl() {
  const service = getFitbitService_();
  const url = service.getAuthorizationUrl({
    prompt: 'consent'
  });
  Logger.log(url);
}

/**
 * Fitbit OAuth callback
 */
function authCallback(request) {
  const service = getFitbitService_();
  const ok = service.handleCallback(request);
  return HtmlService.createHtmlOutput(
    ok ? 'Fitbit authorisation complete. You can close this tab.'
       : 'Fitbit authorisation denied. Please try again.'
  );
}

function syncWeightLogs() {
  const service = getFitbitService_();
  if (!service.hasAccess()) {
    throw new Error('No Fitbit access yet. Run getAuthorizationUrl() and complete authorisation.');
  }

  const sheet = getWeightSheet_();
  const unitLabel = PropertiesService.getScriptProperties().getProperty('UNIT_LABEL') || 'pounds';

  const { logIdSet, legacyKeySet } = buildDedupeSets_(sheet);

  const tz = Session.getScriptTimeZone();
  const today = new Date();
  const start = new Date(today.getTime());
  start.setDate(start.getDate() - (N_DAYS - 1));

  const startStr = Utilities.formatDate(start, tz, 'yyyy-MM-dd');
  const endStr = Utilities.formatDate(today, tz, 'yyyy-MM-dd');

  const logs = fetchWeightLogsRange_(service, startStr, endStr);

  logs.sort((a, b) => (a.date + 'T' + a.time).localeCompare(b.date + 'T' + b.time));

  const rows = [];
  for (const e of logs) {
    const logId = e.logId != null ? String(e.logId) : '';
    const dt = formatHumanDateTime_(e.date, e.time, tz);
    let weight = e.weight;

    if (STORE_WEIGHT_IN_POUNDS) {
      weight = weight * KG_TO_LB;
      // Match typical Fitbit / IFTTT precision (1 decimal place)
      weight = Math.round(weight * 10) / 10;
    }
    const bmi = (e.bmi != null && e.bmi !== '') ? e.bmi : '';

    // Primary dedupe: logId
    if (logId && logIdSet.has(logId)) continue;

    // Transition dedupe: legacy rows (DateTime + Weight)
    const legacyKey = makeLegacyKey_(dt, weight);
    if (legacyKeySet.has(legacyKey)) continue;

    rows.push([dt, weight, unitLabel, bmi, logId]);

    if (logId) logIdSet.add(logId);
    legacyKeySet.add(legacyKey);
  }

  if (rows.length) {
    sheet.getRange(sheet.getLastRow() + 1, 1, rows.length, 5).setValues(rows);
  }
  Logger.log(`Appended ${rows.length} row(s).`);
}

function fetchWeightLogsRange_(service, startDate, endDate) {
  const url = `https://api.fitbit.com/1/user/-/body/log/weight/date/${startDate}/${endDate}.json`;
  const resp = UrlFetchApp.fetch(url, {
    method: 'get',
    headers: { Authorization: 'Bearer ' + service.getAccessToken() },
    muteHttpExceptions: true
  });

  const code = resp.getResponseCode();
  const text = resp.getContentText();
  if (code < 200 || code >= 300) {
    throw new Error(`Fitbit API error ${code}: ${text}`);
  }

  const json = JSON.parse(text);
  return Array.isArray(json.weight) ? json.weight : [];
}

function getWeightSheet_() {
  const sp = PropertiesService.getScriptProperties();
  const spreadsheetId = sp.getProperty('SPREADSHEET_ID');
  if (!spreadsheetId) throw new Error('Missing SPREADSHEET_ID in Script Properties.');

  const name = sp.getProperty('WEIGHT_SHEET_NAME') || 'Weght Logs';
  const ss = SpreadsheetApp.openById(spreadsheetId);
  const sheet = ss.getSheetByName(name);
  if (!sheet) throw new Error(`Sheet "${name}" not found.`);
  return sheet;
}

function buildDedupeSets_(sheet) {
  const lastRow = sheet.getLastRow();
  if (lastRow < 2) return { logIdSet: new Set(), legacyKeySet: new Set() };

  const data = sheet.getRange(2, 1, lastRow - 1, 5).getValues();
  const logIdSet = new Set();
  const legacyKeySet = new Set();

  for (const r of data) {
    const dt = String(r[0] || '').trim();
    const w = r[1];
    const logId = String(r[4] || '').trim();

    if (logId) logIdSet.add(logId);
    if (dt && w !== '' && w != null) legacyKeySet.add(makeLegacyKey_(dt, w));
  }
  return { logIdSet, legacyKeySet };
}

function makeLegacyKey_(dateTimeStr, weight) {
  const w = (typeof weight === 'number') ? weight.toFixed(2) : String(weight).trim();
  return `${dateTimeStr}||${w}`;
}

function formatHumanDateTime_(dateStr, timeStr, tz) {
  const d = new Date(`${dateStr}T${timeStr}`);
  const datePart = Utilities.formatDate(d, tz, 'MMMM d, yyyy');
  const timePart = Utilities.formatDate(d, tz, 'hh:mma');
  return `${datePart} at ${timePart}`;
}

function installDailyTrigger() {
  // Remove existing triggers for this handler
  for (const t of ScriptApp.getProjectTriggers()) {
    if (t.getHandlerFunction() === 'syncWeightLogs') ScriptApp.deleteTrigger(t);
  }

  ScriptApp.newTrigger('syncWeightLogs')
    .timeBased()
    .everyDays(1)
    .atHour(9) 
    .create();

  Logger.log('Daily trigger installed.');
}


