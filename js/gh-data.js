// Shared GitHub data loader (stars + releases) used by the index and the versions page.
// GitHub's API allows only 60 requests/hour per visitor IP, so we avoid it when we can:
//  1. data/releases.json  = a static copy refreshed by a GitHub Action (no limit at all)
//  2. the API, only if that copy is missing or too old (ETag + localStorage cache,
//     a 304 answer does not count against the limit)
//  3. the last cached answer, if everything else fails
// Usage: ghData.get().then(({ stars, releases, updated }) => ...)
(function () {
  const repo = 'SanoBld/LastStats-App';
  const STATIC_URL = 'data/releases.json';
  const MAX_STATIC_AGE = 24 * 3600 * 1000; // older than this -> try the API
  const API_TTL = 30 * 60 * 1000;          // do not hit the API more than every 30 min
  const KEY = 'ghdata:' + repo;

  let promise = null;

  const read = () => { try { return JSON.parse(localStorage.getItem(KEY)); } catch (e) { return null; } };
  const write = (v) => { try { localStorage.setItem(KEY, JSON.stringify(v)); } catch (e) { /* storage full or blocked */ } };

  function valid(d) { return d && Array.isArray(d.releases) && d.releases.length; }

  function fromStatic() {
    return fetch(STATIC_URL, { cache: 'no-cache' })
      .then((r) => (r.ok ? r.json() : null))
      .catch(() => null)
      .then((d) => (valid(d) ? d : null));
  }

  // keep only what the pages use (smaller cache)
  function slim(rel) {
    return {
      tag_name: rel.tag_name, name: rel.name, published_at: rel.published_at,
      prerelease: rel.prerelease, draft: rel.draft, body: rel.body,
      assets: (rel.assets || []).map((a) => ({
        name: a.name, size: a.size, download_count: a.download_count, browser_download_url: a.browser_download_url,
      })),
    };
  }

  // conditional GET: if nothing changed GitHub answers 304 and it is free
  function apiGet(url, cached) {
    const headers = {};
    if (cached && cached.etag) headers['If-None-Match'] = cached.etag;
    return fetch(url, { headers }).then((r) => {
      if (r.status === 304 && cached) return { json: cached.json, etag: cached.etag };
      if (!r.ok) throw new Error('api ' + r.status);
      return r.json().then((json) => ({ json, etag: r.headers.get('ETag') }));
    });
  }

  function fromApi(cache) {
    const c = cache || {};
    return Promise.all([
      apiGet('https://api.github.com/repos/' + repo, c.info),
      apiGet('https://api.github.com/repos/' + repo + '/releases?per_page=100', c.rels),
    ]).then(([info, rels]) => {
      const out = {
        fetched: Date.now(),
        info: { json: { stargazers_count: info.json.stargazers_count }, etag: info.etag },
        rels: { json: rels.json.map(slim), etag: rels.etag },
      };
      write(out);
      return out;
    });
  }

  function toData(cache) {
    return {
      updated: new Date(cache.fetched).toISOString(),
      stars: cache.info.json.stargazers_count,
      releases: cache.rels.json,
    };
  }

  function load() {
    const cache = read();
    // recent API answer already stored: nothing to do
    if (cache && cache.rels && Date.now() - cache.fetched < API_TTL) return Promise.resolve(toData(cache));

    return fromStatic().then((stat) => {
      const fresh = stat && Date.now() - new Date(stat.updated).getTime() < MAX_STATIC_AGE;
      if (fresh) return stat;
      // static copy missing or old: ask the API, fall back to whatever we have
      return fromApi(cache)
        .then(toData)
        .catch(() => stat || (cache && cache.rels ? toData(cache) : Promise.reject(new Error('no data'))));
    });
  }

  window.ghData = { get() { return promise || (promise = load()); } };
})();
