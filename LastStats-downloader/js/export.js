'use strict';
// Map raw Last.fm API items into flat row objects, ready for any export format.
const Rows = {
  history(tracks) {
    return tracks.filter(tr => !tr['@attr']?.nowplaying).map((tr, i) => {
      const raw = tr.date?.['#text'] || '';
      let dt = raw;
      try {
        if (raw) {
          const d = new Date(raw.replace(',', ''));
          if (!isNaN(d)) {
            const p = n => String(n).padStart(2, '0');
            dt = `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}`;
          }
        }
      } catch {}
      return { '#': i + 1, Date: dt, Title: tr.name || '', Artist: tr.artist?.['#text'] || tr.artist?.name || '', Album: tr.album?.['#text'] || '', URL: tr.url || '' };
    });
  },
  artists(items) {
    return items.map((d, i) => ({ Rank: d['@attr']?.rank || i + 1, Artist: d.name || '', Plays: parseInt(d.playcount || 0), URL: d.url || '' }));
  },
  albums(items) {
    return items.map((d, i) => ({ Rank: d['@attr']?.rank || i + 1, Album: d.name || '', Artist: d.artist?.name || '', Plays: parseInt(d.playcount || 0), URL: d.url || '' }));
  },
  tracks(items) {
    return items.map((d, i) => ({ Rank: d['@attr']?.rank || i + 1, Track: d.name || '', Artist: d.artist?.name || '', Duration_s: parseInt(d.duration || 0), Plays: parseInt(d.playcount || 0), URL: d.url || '' }));
  },
};

// Save rows as a file the browser downloads: csv | xlsx | json | pdf
// ctx = { title, type, pdfStyle } — type/pdfStyle only matter for pdf
async function downloadRows(rows, filename, format, ctx) {
  if (!rows.length) throw new Error('empty');
  const sheetTitle = ctx.title;

  if (format === 'json') {
    const payload = { section: sheetTitle, count: rows.length, exported_at: new Date().toISOString(), data: rows };
    saveBlob(new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json' }), filename + '.json');

  } else if (format === 'xlsx') {
    const ws = XLSX.utils.json_to_sheet(rows);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, sheetTitle.slice(0, 31)); // sheet names max 31 chars
    XLSX.writeFile(wb, filename + '.xlsx');

  } else if (format === 'pdf') {
    await downloadPdf(rows, filename, sheetTitle, ctx.type, ctx.pdfStyle, ctx.includeImages);

  } else {
    const SEP = ';'; // semicolon = Excel-friendly separator in most locales
    const esc = v => `"${String(v ?? '').replace(/"/g, '""')}"`;
    const headers = Object.keys(rows[0]);
    const csv = [
      headers.map(esc).join(SEP),
      ...rows.map(r => headers.map(h => esc(r[h])).join(SEP)),
    ].join('\n');
    saveBlob(new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8;' }), filename + '.csv');
  }
}

function saveBlob(blob, filename) {
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = filename;
  a.click();
  setTimeout(() => URL.revokeObjectURL(a.href), 2000);
}
