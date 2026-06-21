'use strict';
const LASTFM_URL = 'https://ws.audioscrobbler.com/2.0/';

const LastFM = {
  // Build a request URL using the saved credentials
  _url(method, params) {
    const u = new URL(LASTFM_URL);
    u.searchParams.set('method', method);
    u.searchParams.set('api_key', Auth.apiKey);
    u.searchParams.set('user', Auth.username);
    u.searchParams.set('format', 'json');
    Object.entries(params).forEach(([k, v]) => u.searchParams.set(k, String(v)));
    return u.toString();
  },

  // One request, retried a few times on failure
  async fetch(method, params = {}, retries = 3) {
    for (let i = 0; i < retries; i++) {
      try {
        const res = await fetch(this._url(method, params));
        const data = await res.json();
        if (data.error) throw new Error(data.message || 'API error');
        return data;
      } catch (e) {
        if (i === retries - 1) throw e;
        await new Promise(r => setTimeout(r, 700 * (i + 1)));
      }
    }
  },

  // Check that username + key are valid, without touching saved Auth
  async testLogin(username, apiKey) {
    const u = new URL(LASTFM_URL);
    u.searchParams.set('method', 'user.getInfo');
    u.searchParams.set('user', username);
    u.searchParams.set('api_key', apiKey);
    u.searchParams.set('format', 'json');
    const res = await fetch(u.toString());
    const data = await res.json();
    if (data.error) throw new Error(data.message || 'Invalid credentials');
    return data.user;
  },

  // Fetch every page of a paginated method (5 requests in parallel per batch)
  async fetchAll(method, dataKey, itemKey, params, onProgress) {
    const BATCH = 5;
    const first = await this.fetch(method, { ...params, page: 1 });
    const attr  = first[dataKey]?.['@attr'] || {};
    const pages = parseInt(attr.totalPages || 1);
    const raw0  = first[dataKey]?.[itemKey];
    const items = Array.isArray(raw0) ? [...raw0] : (raw0 ? [raw0] : []);
    onProgress?.(1, pages, items.length);

    const remaining = Array.from({ length: pages - 1 }, (_, i) => i + 2);
    for (let i = 0; i < remaining.length; i += BATCH) {
      const batch   = remaining.slice(i, i + BATCH);
      const results = await Promise.all(batch.map(p => this.fetch(method, { ...params, page: p })));
      for (const r of results) {
        const arr = r[dataKey]?.[itemKey];
        if (Array.isArray(arr)) items.push(...arr); else if (arr) items.push(arr);
      }
      onProgress?.(Math.min(i + BATCH + 1, pages), pages, items.length);
      if (i + BATCH < remaining.length) await new Promise(r => setTimeout(r, 120));
    }
    return items;
  },
};
