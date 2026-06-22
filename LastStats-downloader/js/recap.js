'use strict';
if (!Auth.isLoggedIn) location.href = 'index.html';

function initRecapPage() {
  document.getElementById('hello-username').textContent = Auth.username;
  const avatarEl = document.getElementById('user-avatar');
  if (Auth.avatarUrl) avatarEl.innerHTML = `<img src="${Auth.avatarUrl}" alt="">`;
  else avatarEl.textContent = (Auth.username[0] || '?').toUpperCase();

  document.getElementById('btn-logout').addEventListener('click', () => {
    Auth.clear();
    location.href = 'index.html';
  });

  const dropzone  = document.getElementById('dropzone');
  const fileInput = document.getElementById('file-input');

  document.getElementById('btn-choose').addEventListener('click', (e) => { e.stopPropagation(); fileInput.click(); });
  dropzone.addEventListener('click', () => fileInput.click());
  fileInput.addEventListener('change', () => { if (fileInput.files[0]) handleFile(fileInput.files[0]); });

  ['dragover', 'dragleave', 'drop'].forEach(evt => {
    dropzone.addEventListener(evt, (e) => { e.preventDefault(); e.stopPropagation(); });
  });
  dropzone.addEventListener('dragover', () => dropzone.classList.add('drag-over'));
  dropzone.addEventListener('dragleave', () => dropzone.classList.remove('drag-over'));
  dropzone.addEventListener('drop', (e) => {
    dropzone.classList.remove('drag-over');
    if (e.dataTransfer.files[0]) handleFile(e.dataTransfer.files[0]);
  });
}

async function handleFile(file) {
  const errEl = document.getElementById('recap-error');
  const resEl = document.getElementById('recap-results');
  errEl.textContent = '';
  try {
    const rows = await parseFile(file);
    if (!rows.length) throw new Error('empty');
    const type = detectType(Object.keys(rows[0]));
    if (!type) throw new Error('unknown-type');
    renderRecap(type, rows);
  } catch {
    errEl.textContent = t('recap_error_parse');
    resEl.classList.add('hidden');
  }
}

// Read a csv / xlsx / json export back into an array of row objects.
async function parseFile(file) {
  const name = file.name.toLowerCase();

  if (name.endsWith('.json')) {
    const parsed = JSON.parse(await file.text());
    return Array.isArray(parsed) ? parsed : (Array.isArray(parsed?.data) ? parsed.data : []);
  }

  if (name.endsWith('.xlsx') || name.endsWith('.xls')) {
    const wb = XLSX.read(await file.arrayBuffer(), { type: 'array' });
    return XLSX.utils.sheet_to_json(wb.Sheets[wb.SheetNames[0]]);
  }

  return parseCsv(await file.text());
}

// Minimal parser matching this site's own CSV format (";" separated, quoted fields, BOM).
function parseCsv(text) {
  text = text.replace(/^\uFEFF/, '');
  const lines = text.split(/\r?\n/).filter(l => l.length);
  if (!lines.length) return [];

  const parseLine = (line) => {
    const out = []; let cur = ''; let inQuotes = false;
    for (let i = 0; i < line.length; i++) {
      const c = line[i];
      if (inQuotes) {
        if (c === '"' && line[i + 1] === '"') { cur += '"'; i++; }
        else if (c === '"') { inQuotes = false; }
        else cur += c;
      } else if (c === '"') { inQuotes = true; }
      else if (c === ';') { out.push(cur); cur = ''; }
      else cur += c;
    }
    out.push(cur);
    return out;
  };

  const headers = parseLine(lines[0]);
  return lines.slice(1).map(line => {
    const cells = parseLine(line);
    const row = {};
    headers.forEach((h, i) => { row[h] = cells[i] ?? ''; });
    return row;
  });
}

// Figure out which dataset this file holds, from its column names.
function detectType(headers) {
  const h = new Set(headers);
  if (h.has('Date') && h.has('Title')) return 'history';
  if (h.has('Track')) return 'tracks';
  if (h.has('Album')) return 'albums';
  if (h.has('Artist')) return 'artists';
  return null;
}

function topCount(values, n = 10) {
  const counts = {};
  values.forEach(v => { if (v) counts[v] = (counts[v] || 0) + 1; });
  return Object.entries(counts).sort((a, b) => b[1] - a[1]).slice(0, n);
}

// Plays per calendar day, to find the single busiest day.
function busiestDay(rows) {
  const counts = {};
  rows.forEach(r => { const d = (r.Date || '').slice(0, 10); if (d) counts[d] = (counts[d] || 0) + 1; });
  let best = null, bestCount = 0;
  for (const [d, c] of Object.entries(counts)) if (c > bestCount) { best = d; bestCount = c; }
  return best ? `${best} (${bestCount})` : '\u2014';
}

// Plays per month, in chronological order, with a short localized label.
function monthlyDistribution(rows) {
  const counts = {};
  rows.forEach(r => { const m = (r.Date || '').slice(0, 7); if (m.length === 7) counts[m] = (counts[m] || 0) + 1; });
  return Object.keys(counts).sort().map(m => {
    const d = new Date(m + '-01T00:00:00');
    const label = isNaN(d) ? m : d.toLocaleDateString(LANG === 'fr' ? 'fr-FR' : 'en-US', { month: 'short', year: '2-digit' });
    return [label, counts[m]];
  });
}

// Plays per day of the week, Monday first.
function weekdayDistribution(rows) {
  const labels = LANG === 'fr' ? ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'] : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const order = [1, 2, 3, 4, 5, 6, 0]; // Date#getDay(): 0 = Sunday
  const counts = new Array(7).fill(0);
  rows.forEach(r => {
    const d = new Date((r.Date || '').replace(' ', 'T'));
    if (!isNaN(d)) counts[d.getDay()]++;
  });
  return order.map((dayIdx, i) => [labels[i], counts[dayIdx]]);
}

function renderRecap(type, rows) {
  const el = document.getElementById('recap-results');
  document.getElementById('recap-error').textContent = '';
  el.classList.remove('hidden');

  const labelKey = { history: 'card_history', artists: 'card_artists', albums: 'card_albums', tracks: 'card_tracks' }[type];
  const unit = type === 'history' ? t('pdf_plays') : t('pdf_items');
  let html = `<div class="recap-header"><h3>${escapeHtml(t(labelKey))}</h3><p>${rows.length} ${escapeHtml(unit)}</p></div>`;

  if (type === 'history') {
    const dates = rows.map(r => r.Date).filter(Boolean).sort();
    const artists = new Set(rows.map(r => r.Artist)).size;
    const activeDays = new Set(rows.map(r => (r.Date || '').slice(0, 10))).size;
    const avgPerDay = activeDays ? Math.round((rows.length / activeDays) * 10) / 10 : 0;

    html += statGrid([
      { num: rows.length, lbl: t('pdf_total_plays') },
      { num: artists, lbl: t('pdf_unique_artists') },
      { num: `${(dates[0] || '').slice(0, 10)} \u2192 ${(dates[dates.length - 1] || '').slice(0, 10)}`, lbl: t('pdf_date_range') },
      { num: busiestDay(rows), lbl: t('recap_busiest_day') },
      { num: avgPerDay, lbl: t('recap_avg_per_day') },
    ]);
    html += barList(t('recap_top_artists'), topCount(rows.map(r => r.Artist)));
    html += barList(t('recap_top_tracks'), topCount(rows.map(r => r.Title)));
    html += columnChart(t('recap_monthly'), monthlyDistribution(rows));
    html += columnChart(t('recap_weekday'), weekdayDistribution(rows));
  } else {
    const nameKey = type === 'artists' ? 'Artist' : type === 'albums' ? 'Album' : 'Track';
    const totalPlays = rows.reduce((s, r) => s + (parseInt(r.Plays, 10) || 0), 0);
    const avgPlays = rows.length ? Math.round((totalPlays / rows.length) * 10) / 10 : 0;

    html += statGrid([
      { num: rows.length, lbl: t('pdf_items') },
      { num: totalPlays, lbl: t('pdf_total_plays') },
      { num: avgPlays, lbl: t('recap_avg_per_item') },
    ]);
    const sorted = [...rows].sort((a, b) => (parseInt(b.Plays, 10) || 0) - (parseInt(a.Plays, 10) || 0)).slice(0, 10);
    const entries = sorted.map(r => [
      r[nameKey] + (type !== 'artists' && r.Artist ? ' \u2014 ' + r.Artist : ''),
      parseInt(r.Plays, 10) || 0,
    ]);
    html += barList('Top 10', entries);
  }

  el.innerHTML = html;
}

function statGrid(items) {
  return `<div class="stat-grid">${items.map(s =>
    `<div class="stat-tile"><div class="num">${escapeHtml(s.num)}</div><div class="lbl">${escapeHtml(s.lbl)}</div></div>`
  ).join('')}</div>`;
}

function barList(title, entries) {
  if (!entries.length) return '';
  const max = Math.max(...entries.map(e => e[1])) || 1;
  const rows = entries.map(([label, count]) => `
    <div class="bar-row">
      <span class="bar-label">${escapeHtml(label)}</span>
      <span class="bar-track3"><span class="fill" style="width:${Math.round(count / max * 100)}%"></span></span>
      <span class="bar-count">${count}</span>
    </div>`).join('');
  return `<div class="top-list"><h4>${escapeHtml(title)}</h4>${rows}</div>`;
}

// Simple vertical bar chart for breakdowns (months, weekdays) — no chart library needed.
function columnChart(title, entries) {
  if (!entries.length || !entries.some(e => e[1] > 0)) return '';
  const max = Math.max(...entries.map(e => e[1])) || 1;
  const bars = entries.map(([label, count]) => `
    <div class="chart-bar">
      <span class="chart-val">${count}</span>
      <span class="chart-col" style="height:${Math.max(4, Math.round(count / max * 100))}%"></span>
      <span class="chart-label">${escapeHtml(label)}</span>
    </div>`).join('');
  return `<div class="top-list"><h4>${escapeHtml(title)}</h4><div class="chart-bars">${bars}</div></div>`;
}

function escapeHtml(s) {
  return String(s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

document.addEventListener('DOMContentLoaded', initRecapPage);
