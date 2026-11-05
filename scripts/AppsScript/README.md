# AppsScript

Google Apps Script projects. This directory holds backup copies of the source; the scripts themselves run inside Google's Apps Script environment, not on this machine.

## WeightLog.js: Fitbit Aria to Google Sheets

Copies weigh-ins from Fitbit into a Google Sheet. A daily trigger appends any new entries to the end of the sheet.

> **Status as of 2026-11-05: broken, needs migrating.** The script reads from the legacy Fitbit Web API, and Google has switched that off. On 2026-11-05 a request to `https://api.fitbit.com/oauth2/token` returned HTTP 410 with the message "The legacy Fitbit Web API and OAuth 2.0 endpoints were decommissioned on October 30, 2026." Support had already ended on 30 September 2026 ([Fitbit developer blog](https://dev.fitbit.com/blog/author/gordon-crenshaw/)); the [Google Health API page](https://developers.google.com/health) gives 2 November 2026 as the switch-off date. The endpoint's own message says 30 October, but the last successful sync ran on 2 November (the newest row is from 07:01 that day), and the three runs after it failed, the latest on 5 November at 09:09.
>
> The script can no longer refresh its OAuth token, and the Apps Script *Executions* page shows the failures as the script's own `No Fitbit access yet. Run getAuthorizationUrl() and complete authorisation.`, not a `Fitbit API error`, because the OAuth2 library reports a failed refresh as "no access". That error does not mean the script is misconfigured. Weigh-ins after the last successful sync (2 November) are not in the sheet. With the current 14-day window they are still picked up if a working sync first runs by about 15 November. See [Migrating to the Google Health API](#migrating-to-the-google-health-api).

```
Aria scale --> Fitbit cloud --> legacy Fitbit Web API --> WeightLog.js --> Google Sheet
              (scale syncs)    (OAuth2, 'weight'; OFF)    (Apps Script)    (tab, columns A-E)
```

### Where it reads from (as written; this API is now off)

The script does not talk to the scale. It reads from the Fitbit cloud, which the scale syncs to.

- **Endpoint:** `GET https://api.fitbit.com/1/user/-/body/log/weight/date/{start}/{end}.json`
- **Auth:** OAuth2 authorization-code flow, scope `weight`, using the Apps Script OAuth2 library. Requests carry `Authorization: Bearer <access token>`.
- **Window:** the last `N_DAYS` days (14), counting today, with dates computed in the script's time zone (`Session.getScriptTimeZone()`). Entries older than that are never fetched, so if the trigger is broken for more than 14 days, those weigh-ins are missed.
- **Fields used from each entry:** `logId`, `date`, `time`, `weight`, `bmi`. The script assumes `weight` is in kilograms (it multiplies by `KG_TO_LB`) and sends no `Accept-Language` header to request a particular unit system.

### Where it writes to

- **Spreadsheet:** the one whose ID is in the `SPREADSHEET_ID` script property. It is a Google Sheets file titled `Weight Logs`.
- **Tab:** the `WEIGHT_SHEET_NAME` script property, set to `Weight` in the live project. That is the spreadsheet's only tab, and also the built-in default.
- **Row 1** is assumed to be a header and is never written. Data is read from row 2 down.
- **New rows** are appended after the last used row. Rows already in the sheet are never modified or removed.

| Col | Content | Notes |
|-----|---------|-------|
| A | DateTime | Text such as `December 10, 2016 at 03:20PM`, built from the entry's date and time in the script's time zone |
| B | Weight | Converted from kg to pounds and rounded to 1 decimal (`STORE_WEIGHT_IN_POUNDS = true`) |
| C | Unit | The `UNIT_LABEL` script property, default `pounds` |
| D | BMI | Taken from Fitbit as-is; blank if Fitbit returned none |
| E | LogId | Fitbit's `logId`, which is the primary dedupe key. Blank for legacy rows |

Legacy rows are the ones that predate this script. The code comments mention IFTTT as the earlier source.

### Deduplication

Each run reads columns A to E of the whole sheet and skips a Fitbit entry if either of these matches:

1. its `logId` is already in column E, or
2. its `DateTime` and weight (to 2 decimals) match an existing row. This covers legacy rows that have no `logId`.

Re-running the script is therefore safe. It only appends entries that are not yet in the sheet.

### Configuration

Script properties (Project Settings, then Script Properties):

| Property | Required | Purpose |
|----------|----------|---------|
| `FITBIT_CLIENT_ID` | yes | Client ID of the Fitbit developer app |
| `FITBIT_CLIENT_SECRET` | yes | Client secret of the Fitbit developer app |
| `SPREADSHEET_ID` | yes | The target spreadsheet |
| `WEIGHT_SHEET_NAME` | no | Tab name; default `Weight Logs` |
| `UNIT_LABEL` | no | Text for column C; default `pounds` |

The OAuth tokens are stored in the *user* properties of whoever authorised the script, not in script properties.

Constants at the top of `WeightLog.js`: `N_DAYS`, `STORE_WEIGHT_IN_POUNDS`, `KG_TO_LB`. `UNIT_LABEL` is not tied to `STORE_WEIGHT_IN_POUNDS`: if you switch to kilograms, also set `UNIT_LABEL`, or column C will still say `pounds`.

### Installation and running

Live script properties, as reported on 2026-11-05: `WEIGHT_SHEET_NAME` = `Weight`, `UNIT_LABEL` = `pounds`, and `SPREADSHEET_ID`, `FITBIT_CLIENT_ID` and `FITBIT_CLIENT_SECRET` are all set. This repository is public, so the IDs and the secret are deliberately not recorded here. Read them in the Apps Script project under *Project Settings, Script Properties*.

The Apps Script project itself (script ID / URL) is not recorded anywhere; find it at [script.google.com](https://script.google.com/home).

One-time setup (as it was; the authorisation flow in steps 1 and 4 can no longer complete, because the Fitbit OAuth endpoints are off):

1. Create a Fitbit developer app and set its redirect URL to the one the OAuth2 library uses for the Apps Script project, `https://script.google.com/macros/d/<script ID>/usercallback`.
2. Paste the `WeightLog.js` source into the Apps Script project and add the **OAuth2 for Apps Script** library (the header comment says version 43 was used).
3. Set the script properties above.
4. Run `getAuthorizationUrl()`, copy the URL from the execution log, open it and approve access. `authCallback()` completes the flow.
5. Run `installDailyTrigger()`. It deletes any existing `syncWeightLogs` triggers and creates one that runs daily around 09:00.

Normal operation is just the daily trigger calling `syncWeightLogs()`. To sync on demand, run `syncWeightLogs()` from the editor. The execution log reports `Appended N row(s).`.

### Known issues

- The built-in default tab name in `getWeightSheet_()` used to be `'Weght Logs'`, apparently a misspelling of the spreadsheet's file title rather than of its tab. The repo copy now defaults to `'Weight'`, the real tab. This never affected the live project, because `WEIGHT_SHEET_NAME` is set to `Weight`. The Apps Script project has its own copy of the code, so the change only reaches it if pasted there, which is optional.
- The script is append-only. If a weigh-in is corrected or deleted in Fitbit after it was synced, the sheet keeps the original row.
- A failed sync leaves a gap that is only filled while it is still inside the 14-day window (`N_DAYS`). Sync failures stay silent unless you look at the *Executions* page or set up failure notifications on the trigger.

### Moving the files around in Drive

The location of the spreadsheet and the script in Drive does not matter to the code. `SpreadsheetApp.openById()` resolves the sheet by its Drive ID, and moving a file between folders keeps its ID. Triggers, script properties and the stored OAuth tokens belong to the script project and the user who authorised it, not to a folder. So moving either file between folders in your own My Drive is safe.

Things that do matter:

- **Ownership.** Triggers run as the user who installed them, and the tokens live in that user's properties. Transferring ownership, or moving the files into a Shared Drive, can break that. Re-check the trigger and re-authorise after any such move.
- **Copying.** "Make a copy" creates a new file ID. A copied sheet needs `SPREADSHEET_ID` updated, and a copied script project is a new project with its own ID, triggers and authorisation.
- **Standalone or bound.** The code opens the sheet by ID, so the script is presumably standalone, a separate file in Drive. A container-bound script (created from the sheet's *Extensions, Apps Script* menu) does not appear as a file in Drive and moves together with its sheet. To check, open the script and look for a container under *Project Settings*.
- **IFTTT.** The code comments mention IFTTT as the source of the legacy rows. If an IFTTT applet still writes to this sheet, note that IFTTT's Google Sheets actions are configured with a Drive folder path and a spreadsheet name (check the applet's settings), so moving or renaming the file would probably break it.

### Migrating to the Google Health API

The replacement for the legacy Fitbit Web API is the [Google Health API](https://developers.google.com/health). What the documentation says (the exact REST path and response fields for weight are not yet confirmed):

- Weight is the `weight` data type, with a list operation. It supports Aria, Aria 2 and Aria Air ([data types](https://developers.google.com/health/data-types)). The read scope ends in `.health_metrics_and_measurements.readonly`, under the `https://www.googleapis.com/auth/googlehealth` prefix.
- Authentication is Google OAuth 2.0 with apps registered in a Google Cloud project, replacing the Fitbit developer app. Existing Fitbit tokens cannot be transferred, so the sync has to be authorised again.
- The Fitbit account must be moved to a Google Account first ([migration guide](https://developers.google.com/health/migration)). Otherwise API calls return `ACCOUNT_NOT_LINKED`.
- The migration guide describes no mapping between legacy `logId`s and the new data point IDs, so assume there is none. After migration, the `logId` column cannot dedupe against old rows, and the DateTime and weight fallback key has to do the work. Entries must be compared at the same rounding (pounds, 1 decimal).
- The API supports querying historical data, so the gap since the last successful sync (2 November) can be backfilled. With a 14-day window that happens by itself if the first migrated run is by about 15 November; after that, widen the window for the first run. The legacy API cannot be used for that any more.

An open question is whether a personal script like this needs a verified OAuth consent screen, or whether refresh tokens are limited in testing mode. The documentation pages read so far do not say.
