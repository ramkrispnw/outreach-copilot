/**
 * outreach-copilot — tracker formatting + Status dropdown.
 *
 * The Status dropdown (data validation) has no MCP equivalent, so this runs as a
 * bound Apps Script. Open your tracker > Extensions > Apps Script, paste this file,
 * then Run > setupTracker (authorize once).
 *
 * Assumes three tabs: Prospects, Replies Log, Drafts (created by the setup skill
 * or manually). Idempotent: safe to re-run.
 */
var HEADER_BG = '#1f3864', HEADER_FG = '#ffffff';
var STATUSES = ['Pending','Approved','Sending','Sent','Skip','Failed'];

function setupTracker() {
  var ss = SpreadsheetApp.getActive();
  var msgs = [];
  msgs.push(formatTab_(ss, 'Prospects', 16));
  msgs.push(formatTab_(ss, 'Replies Log', 8));
  msgs.push(setupDrafts_(ss));
  return msgs.join(' | ');
}

function formatTab_(ss, name, lastCol) {
  var s = ss.getSheetByName(name); if (!s) return name + ': not found';
  var h = s.getRange(1, 1, 1, lastCol);
  h.setBackground(HEADER_BG).setFontColor(HEADER_FG).setFontWeight('bold')
   .setVerticalAlignment('middle').setWrap(true);
  s.setFrozenRows(1); s.setRowHeight(1, 34);
  return name + ': formatted';
}

function setupDrafts_(ss) {
  var s = ss.getSheetByName('Drafts'); if (!s) return 'Drafts: not found';
  formatTab_(ss, 'Drafts', 14);
  // Status dropdown on K2:K1000
  var rule = SpreadsheetApp.newDataValidation()
    .requireValueInList(STATUSES, true).setAllowInvalid(false)
    .setHelpText('Set Approved to have the sender send this reply.').build();
  s.getRange('K2:K1000').setDataValidation(rule).setHorizontalAlignment('center');
  // Status color-coding
  var c = function(v, bg, fg){ return SpreadsheetApp.newConditionalFormatRule()
    .whenTextEqualTo(v).setBackground(bg).setFontColor(fg)
    .setRanges([s.getRange('K2:K1000')]).build(); };
  s.setConditionalFormatRules([
    c('Pending','#fff2cc','#7f6000'), c('Approved','#d9ead3','#274e13'),
    c('Sending','#cfe2f3','#0b5394'), c('Sent','#d9d9d9','#444444'),
    c('Skip','#efefef','#777777'),    c('Failed','#f4cccc','#990000')
  ]);
  // Wrap long text columns
  s.getRange('C2:G1000').setWrap(true).setVerticalAlignment('top');
  s.getRange('N2:N1000').setWrap(true).setVerticalAlignment('top');
  return 'Drafts: dropdown + format OK';
}
