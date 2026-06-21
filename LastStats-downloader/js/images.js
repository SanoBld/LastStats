'use strict';
// Picture lookups for the "Beautiful" PDF. Every function returns null on any
// failure (network, CORS, rate limit, no match) — the PDF then draws a
// monogram avatar instead, so a missing photo never breaks the export.

function abortSignal(ms) {
  const ctrl = new AbortController();
  setTimeout(() => ctrl.abort(), ms);
  return ctrl.signal;
}

// Artist photo: try Wikipedia first (no key, reliable, good CORS support),
// then fall back to TheAudioDB (public test key "123", or the user's own Patreon key).
async function fetchArtistImageUrl(name) {
  const wiki = await fetchWikipediaImageUrl(name);
  if (wiki) return wiki;
  try {
    const key = Auth.imagesKey || '123';
    const url = `https://www.theaudiodb.com/api/v1/json/${key}/search.php?s=${encodeURIComponent(name)}`;
    const res = await fetch(url, { signal: abortSignal(6000) });
    const data = await res.json();
    const a = data?.artists?.[0];
    return a?.strArtistThumb || a?.strArtistFanart || null;
  } catch {
    return null;
  }
}

// Wikipedia's summary endpoint: keyless, CORS-enabled, usually has an infobox photo.
// Prefer the original (full-res) image over the small thumbnail, which often looked compressed.
async function fetchWikipediaImageUrl(name) {
  try {
    const url = `https://en.wikipedia.org/api/rest_v1/page/summary/${encodeURIComponent(name)}`;
    const res = await fetch(url, { signal: abortSignal(6000) });
    if (!res.ok) return null;
    const data = await res.json();
    if (data.type === 'disambiguation') return null; // ambiguous name, no single photo
    return data.originalimage?.source || data.thumbnail?.source || null;
  } catch {
    return null;
  }
}

// Album/track artwork via the iTunes Search API (free, no key needed).
async function fetchItunesArtUrl(query, entity) {
  try {
    const url = `https://itunes.apple.com/search?term=${encodeURIComponent(query)}&entity=${entity}&limit=1`;
    const res = await fetch(url, { signal: abortSignal(6000) });
    const data = await res.json();
    const art = data?.results?.[0]?.artworkUrl100;
    return art ? art.replace('100x100', '400x400') : null;
  } catch {
    return null;
  }
}

const AVATAR_PX = 240;       // render size before the PDF scales it down
const AVATAR_RADIUS_PX = 36; // corner rounding — kept smaller than the PDF's frame radius so the frame never shows a square corner peeking out

// Download a picture URL and turn it into a square, rounded-corner, PDF-ready data URL.
// Cropping (not stretching) keeps portrait/landscape photos from looking squashed.
// Falls back to the plain image if canvas processing isn't available. Null on any failure.
async function imageUrlToDataUrl(url) {
  if (!url) return null;
  try {
    const res = await fetch(url, { signal: abortSignal(8000) });
    const blob = await res.blob();
    try {
      return { dataUrl: await roundedSquareDataUrl(blob), format: 'PNG' };
    } catch {
      return await plainDataUrl(blob); // canvas step failed — still better than nothing
    }
  } catch {
    return null;
  }
}

async function roundedSquareDataUrl(blob) {
  const bitmap = await createImageBitmap(blob);
  const canvas = document.createElement('canvas');
  canvas.width = AVATAR_PX; canvas.height = AVATAR_PX;
  const ctx = canvas.getContext('2d');

  const r = AVATAR_RADIUS_PX;
  ctx.beginPath();
  ctx.moveTo(r, 0);
  ctx.arcTo(AVATAR_PX, 0, AVATAR_PX, AVATAR_PX, r);
  ctx.arcTo(AVATAR_PX, AVATAR_PX, 0, AVATAR_PX, r);
  ctx.arcTo(0, AVATAR_PX, 0, 0, r);
  ctx.arcTo(0, 0, AVATAR_PX, 0, r);
  ctx.closePath();
  ctx.clip();

  // Cover-fit: crop the longer side to a centered square, never stretch.
  const s = Math.min(bitmap.width, bitmap.height);
  const sx = (bitmap.width - s) / 2, sy = (bitmap.height - s) / 2;
  ctx.drawImage(bitmap, sx, sy, s, s, 0, 0, AVATAR_PX, AVATAR_PX);

  return canvas.toDataURL('image/png');
}

async function plainDataUrl(blob) {
  const format = blob.type.includes('png') ? 'PNG' : 'JPEG';
  const dataUrl = await new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.onerror = reject;
    reader.readAsDataURL(blob);
  });
  return { dataUrl, format };
}

// Pick the right lookup for a podium item, then resolve it to a usable image (or null).
async function fetchPodiumImage(type, item) {
  let picUrl = null;
  if (type === 'artists') picUrl = await fetchArtistImageUrl(item.Artist);
  else if (type === 'albums') picUrl = await fetchItunesArtUrl(`${item.Artist} ${item.Album}`, 'album');
  else if (type === 'tracks') picUrl = await fetchItunesArtUrl(`${item.Artist} ${item.Track}`, 'song');
  return imageUrlToDataUrl(picUrl);
}
