'use strict';
// Builds a PDF from rows. style: 'simple' (plain table) or 'pretty' (branded report).
function downloadPdf(rows, filename, title, type, style) {
  const headers = Object.keys(rows[0]).filter(h => h !== 'URL'); // URL clutters a printed page
  const body = rows.map(r => headers.map(h => String(r[h] ?? '')));
  const subtitle = `${new Date().toLocaleDateString()} \u00b7 ${rows.length} ${type === 'history' ? t('pdf_plays') : t('pdf_items')}`;

  if (style === 'pretty') {
    buildPrettyPdf(headers, body, title, subtitle, buildHighlights(type, rows), filename);
  } else {
    buildSimplePdf(headers, body, title, subtitle, filename);
  }
}

// Top stats shown on the "pretty" cover: a podium for ranked lists, key numbers for history.
function buildHighlights(type, rows) {
  const ACCENTS = [[247, 209, 140], [197, 224, 216], [234, 239, 236]]; // gold / teal / neutral tint

  if (type === 'history') {
    const dates = rows.map(r => r.Date).filter(Boolean).sort();
    const artists = new Set(rows.map(r => r.Artist)).size;
    return [
      { value: rows.length, label: t('pdf_total_plays'), accent: ACCENTS[0] },
      { value: artists, label: t('pdf_unique_artists'), accent: ACCENTS[1] },
      { value: `${(dates[0] || '').slice(0, 10)} \u2192 ${(dates[dates.length - 1] || '').slice(0, 10)}`, label: t('pdf_date_range'), accent: ACCENTS[2] },
    ];
  }

  const nameKey = type === 'artists' ? 'Artist' : type === 'albums' ? 'Album' : 'Track';
  const top3 = [...rows].sort((a, b) => (a.Rank || 0) - (b.Rank || 0)).slice(0, 3);
  return top3.map((r, i) => ({ value: `${r.Plays}`, label: `#${r.Rank} ${r[nameKey]}`, accent: ACCENTS[i] }));
}

// Plain, fast PDF: title + table, default styling.
function buildSimplePdf(headers, body, title, subtitle, filename) {
  const { jsPDF } = window.jspdf;
  const doc = new jsPDF({ unit: 'mm', format: 'a4' });

  doc.setFontSize(15); doc.setTextColor(20);
  doc.text(title, 14, 16);
  doc.setFontSize(9); doc.setTextColor(120);
  doc.text(subtitle, 14, 22);

  doc.autoTable({
    head: [headers], body,
    startY: 28,
    styles: { fontSize: 8 },
    headStyles: { fillColor: [60, 60, 60] },
    didDrawPage: (data) => {
      doc.setFontSize(8); doc.setTextColor(150);
      doc.text(`Page ${data.pageNumber}`, 14, doc.internal.pageSize.getHeight() - 8);
    },
  });

  doc.save(filename + '.pdf');
}

// Branded report: colored header band, cover stats, themed table.
function buildPrettyPdf(headers, body, title, subtitle, highlights, filename) {
  const { jsPDF } = window.jspdf;
  const doc = new jsPDF({ unit: 'mm', format: 'a4' });
  const W = doc.internal.pageSize.getWidth();

  const PRIMARY = [43, 110, 99], ON_PRIMARY = [255, 255, 255];
  const TEXT = [26, 28, 27], MUTED = [100, 110, 105], STRIPE = [234, 239, 236];

  // Header band with the reel mark + app name
  doc.setFillColor(...PRIMARY); doc.rect(0, 0, W, 28, 'F');
  doc.setDrawColor(...ON_PRIMARY); doc.setLineWidth(0.8);
  doc.circle(16, 14, 4, 'S'); doc.circle(26, 14, 4, 'S');
  doc.setFillColor(...ON_PRIMARY); doc.circle(16, 14, 1, 'F'); doc.circle(26, 14, 1, 'F');
  doc.setTextColor(...ON_PRIMARY); doc.setFontSize(11);
  doc.text('LastStat Downloader', 35, 16);

  // Report title
  doc.setTextColor(...TEXT); doc.setFontSize(19);
  doc.text(title, 14, 40);
  doc.setFontSize(9); doc.setTextColor(...MUTED);
  doc.text(subtitle, 14, 47);

  // Highlight tiles (podium or key stats)
  let y = 55;
  if (highlights?.length) {
    const n = highlights.length, gap = 6;
    const boxW = (W - 28 - gap * (n - 1)) / n;
    highlights.forEach((h, i) => {
      const x = 14 + i * (boxW + gap);
      doc.setFillColor(...h.accent);
      doc.roundedRect(x, y, boxW, 24, 3, 3, 'F');
      doc.setTextColor(...TEXT); doc.setFontSize(12);
      doc.text(String(h.value), x + boxW / 2, y + 10, { align: 'center' });
      doc.setFontSize(7); doc.setTextColor(...MUTED);
      doc.text(doc.splitTextToSize(String(h.label), boxW - 6), x + boxW / 2, y + 16, { align: 'center' });
    });
    y += 32;
  }

  doc.autoTable({
    head: [headers], body,
    startY: y,
    styles: { fontSize: 8, textColor: TEXT },
    headStyles: { fillColor: PRIMARY, textColor: ON_PRIMARY },
    alternateRowStyles: { fillColor: STRIPE },
    didDrawPage: (data) => {
      doc.setFontSize(8); doc.setTextColor(...MUTED);
      doc.text(`LastStat Downloader \u2014 Page ${data.pageNumber}`, 14, doc.internal.pageSize.getHeight() - 8);
    },
  });

  doc.save(filename + '.pdf');
}
