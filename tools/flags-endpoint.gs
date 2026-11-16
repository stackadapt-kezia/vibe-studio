/**
 * Vibe studio dev flags: the web app that dev mode (?dev) syncs flags to.
 *
 * Setup: open the "Vibe studio · dev flags" Sheet, Extensions > Apps Script,
 * paste this file over Code.gs, then Deploy > New deployment > Web app,
 * Execute as: Me, Who has access: Anyone. Copy the /exec URL into the Sync
 * button in Vibe's dev flag list.
 *
 * POST  {flags:[...]}  replaces the flag rows with the browser's list. The
 *       "claude reply" column is kept per flag id, so replies survive syncs.
 * GET   returns {replies:{id: text}} so dev mode can show the replies.
 */
const HEAD = ["id", "#", "status", "where", "note", "claude reply", "selector", "x", "y", "view", "version", "created", "updated"];
const REPLY = HEAD.indexOf("claude reply");

function sheet_() { return SpreadsheetApp.getActiveSpreadsheet().getSheets()[0]; }

function rows_(sh) {
  const n = sh.getLastRow() - 1;
  return n > 0 ? sh.getRange(2, 1, n, HEAD.length).getValues() : [];
}

function json_(o) {
  return ContentService.createTextOutput(JSON.stringify(o)).setMimeType(ContentService.MimeType.JSON);
}

function doPost(e) {
  const lock = LockService.getScriptLock();
  lock.waitLock(10000);
  try {
    const flags = JSON.parse(e.postData.contents).flags || [];
    const sh = sheet_();
    sh.getRange(1, 1, 1, HEAD.length).setValues([HEAD]);
    const replies = {};
    rows_(sh).forEach(r => { if (r[0]) replies[r[0]] = r[REPLY]; });
    const now = new Date().toISOString();
    const out = flags.slice(0, 500).map(f => [
      String(f.id), f.n, f.done ? "done" : "open", String(f.name || ""), String(f.note || ""),
      replies[f.id] || "", String(f.sel || ""), f.fx, f.fy, String(f.view || ""), String(f.ver || ""), String(f.at || ""), now
    ]);
    const old = sh.getLastRow() - 1;
    if (old > 0) sh.getRange(2, 1, old, HEAD.length).clearContent();
    if (out.length) sh.getRange(2, 1, out.length, HEAD.length).setValues(out);
    return json_({ ok: true, count: out.length });
  } finally {
    lock.releaseLock();
  }
}

function doGet() {
  const replies = {};
  rows_(sheet_()).forEach(r => { if (r[0] && r[REPLY]) replies[r[0]] = String(r[REPLY]); });
  return json_({ replies });
}
