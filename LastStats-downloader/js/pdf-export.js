'use strict';
// Builds a PDF from rows. style: 'simple' (plain table) or 'pretty' (branded report with photos).
async function downloadPdf(rows, filename, title, type, style, includeImages) {
  const headers = Object.keys(rows[0]).filter(h => h !== 'URL'); // URL clutters a printed page
  const body = rows.map(r => headers.map(h => String(r[h] ?? '')));
  const subtitle = `${new Date().toLocaleDateString()} \u00b7 ${rows.length} ${type === 'history' ? t('pdf_plays') : t('pdf_items')}`;

  if (style === 'pretty') {
    const highlights = await buildHighlights(type, rows, includeImages);
    buildPrettyPdf(headers, body, title, subtitle, highlights, filename);
  } else {
    buildSimplePdf(headers, body, title, subtitle, filename);
  }
}

// Top stats shown on the "pretty" cover: a podium with photos for ranked lists,
// or key numbers for history (no single "winner" to show a photo for).
async function buildHighlights(type, rows, includeImages) {
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
  // Skip the network calls entirely when photos are turned off — monogram avatars only.
  const avatars = includeImages
    ? await Promise.all(top3.map(item => fetchPodiumImage(type, item)))
    : top3.map(() => null);

  return top3.map((r, i) => ({
    value: `${r.Plays} ${t('pdf_plays')}`,
    label: `#${r.Rank} ${r[nameKey]}`,
    accent: ACCENTS[i],
    avatar: avatars[i],                          // {dataUrl, format} or null
    monogram: (r[nameKey] || '?').charAt(0).toUpperCase(), // fallback when there's no photo
  }));
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

// Branded report: colored header band, cover stats (with photos when available), themed table.
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

  let y = drawHighlightRow(doc, highlights, W, 55, { TEXT, MUTED, PRIMARY });

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

// Draws the row of highlight tiles (history stats, or a podium with photos/monograms).
// Returns the Y position where content can continue below the row.
function drawHighlightRow(doc, highlights, W, y, colors) {
  const { TEXT, MUTED, PRIMARY } = colors;
  const hasAvatars = highlights.some(h => h.avatar || h.monogram);
  const boxH = hasAvatars ? 40 : 24;
  const n = highlights.length, gap = 6;
  const boxW = (W - 28 - gap * (n - 1)) / n;

  highlights.forEach((h, i) => {
    const x = 14 + i * (boxW + gap);
    doc.setFillColor(...h.accent);
    doc.roundedRect(x, y, boxW, boxH, 3, 3, 'F');

    if (!hasAvatars) {
      doc.setTextColor(...TEXT); doc.setFontSize(12);
      doc.text(String(h.value), x + boxW / 2, y + 10, { align: 'center' });
      doc.setFontSize(7); doc.setTextColor(...MUTED);
      doc.text(doc.splitTextToSize(String(h.label), boxW - 6), x + boxW / 2, y + 16, { align: 'center' });
      return;
    }

    const avSize = 16, avX = x + boxW / 2 - avSize / 2, avY = y + 4;
    doc.setDrawColor(...PRIMARY); doc.setLineWidth(0.5);
    if (h.avatar) {
      doc.addImage(h.avatar.dataUrl, h.avatar.format, avX, avY, avSize, avSize);
      doc.roundedRect(avX, avY, avSize, avSize, 2, 2, 'S'); // frame on top of the photo
    } else {
      doc.setFillColor(255, 255, 255);
      doc.circle(x + boxW / 2, avY + avSize / 2, avSize / 2, 'FD'); // fill + matching round border
      doc.setTextColor(80, 90, 85); doc.setFontSize(13);
      doc.text(h.monogram || '?', x + boxW / 2, avY + avSize / 2 + 4.5, { align: 'center' });
    }

    doc.setTextColor(...TEXT); doc.setFontSize(7.5);
    doc.text(doc.splitTextToSize(String(h.label), boxW - 6), x + boxW / 2, avY + avSize + 6, { align: 'center' });
    doc.setFontSize(9); doc.setTextColor(...MUTED);
    doc.text(String(h.value), x + boxW / 2, avY + avSize + 13, { align: 'center' });
  });

  return y + boxH + 8;
}
