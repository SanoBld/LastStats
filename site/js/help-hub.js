// Help page: first a grid of theme tiles; clicking a tile shows only that theme
// (its full step-by-step content) with a "all themes" button to go back.
// The content stays in help.html (translated by i18n.js as before). Without JS
// the page simply shows everything, like it used to.
// Links: #theme opens a theme, #card-id opens the theme that contains the card
// and scrolls to it (only plain #name hashes, so the links can be shared).
(function () {
  const root = document.getElementById('toc-main');
  const hub = document.getElementById('help-hub');
  if (!root || !hub) return;

  const grid = document.getElementById('help-hub-grid');
  const results = document.getElementById('help-hub-results');
  const emptyMsg = document.getElementById('help-hub-empty');
  const search = document.getElementById('help-search');
  const bar = document.getElementById('help-topic-bar');
  const layout = document.getElementById('help-layout');
  const rail = document.getElementById('toc-rail');
  const inner = document.getElementById('toc-inner');
  const fill = document.getElementById('toc-fill');

  const t = (k) => (window.i18n ? i18n.t(k) : k);

  // order of the tiles + icon (Material Symbols Rounded) + description key
  const THEMES = [
    { id: 'start', icon: 'flag', desc: 'hp.hub.d.start' },
    { id: 'understand', icon: 'school', desc: 'hp.hub.d.understand' },
    { id: 'scrobblers', icon: 'headphones', desc: 'hp.hub.d.scrobblers' },
    { id: 'app', icon: 'smartphone', desc: 'hp.hub.d.app' },
    { id: 'trouble', icon: 'healing', desc: 'hp.hub.d.trouble' },
    { id: 'faq', icon: 'live_help', desc: 'hp.hub.d.faq' },
    { id: 'sources', icon: 'article', desc: 'hp.hub.d.sources' },
  ].filter((th) => document.getElementById(th.id));

  // FAQ items have no id in the html: give them one so they can be linked
  root.querySelectorAll('.faq-item').forEach((d, i) => { if (!d.id) d.id = 'faq-' + (i + 1); });

  const sec = (id) => document.getElementById(id);
  const titleOf = (section) => {
    const h = section.querySelector('h2');
    return h ? h.textContent.trim() : section.id;
  };
  const cardTitle = (el) => {
    const h = el.querySelector('h3') || el.querySelector('summary span');
    return h ? h.textContent.trim() : el.id;
  };

  let current = null; // id of the open theme, null = hub

  /* ---------------- hub (tiles) ---------------- */
  function countLabel(section, id) {
    if (id === 'faq') return t('hp.hub.questions').replace('{n}', section.querySelectorAll('.faq-item').length);
    const n = section.querySelectorAll('.help-card').length;
    return n > 1 ? t('hp.hub.guides').replace('{n}', n) : '';
  }

  function buildHub() {
    grid.textContent = '';
    THEMES.forEach((th) => {
      const section = sec(th.id);
      const a = document.createElement('a');
      a.className = 'help-tile md-ripple';
      a.href = '#' + th.id;
      const count = countLabel(section, th.id);
      a.innerHTML =
        '<span class="help-tile-icon"><span class="ms" aria-hidden="true">' + th.icon + '</span></span>' +
        '<span class="help-tile-body">' +
          '<span class="help-tile-title"></span>' +
          '<span class="help-tile-desc"></span>' +
          (count ? '<span class="help-tile-count"></span>' : '') +
        '</span>' +
        '<span class="ms help-tile-arrow" aria-hidden="true">chevron_right</span>';
      a.querySelector('.help-tile-title').textContent = titleOf(section);
      a.querySelector('.help-tile-desc').textContent = t(th.desc);
      if (count) a.querySelector('.help-tile-count').textContent = count;
      grid.appendChild(a);
    });
    search.placeholder = t('hp.hub.search');
    runSearch();
  }

  /* ---------------- search across every card / question ---------------- */
  function runSearch() {
    const q = search.value.trim().toLowerCase();
    results.textContent = '';
    if (!q) {
      grid.hidden = false; results.hidden = true; emptyMsg.hidden = true;
      return;
    }
    let hits = 0;
    THEMES.forEach((th) => {
      const section = sec(th.id);
      section.querySelectorAll('.help-card, .faq-item').forEach((el) => {
        if (!el.textContent.toLowerCase().includes(q)) return;
        hits++;
        const a = document.createElement('a');
        a.className = 'help-result md-ripple';
        a.href = '#' + el.id;
        const ti = document.createElement('span');
        ti.className = 'help-result-title';
        ti.textContent = cardTitle(el);
        const th2 = document.createElement('span');
        th2.className = 'help-result-theme';
        th2.textContent = titleOf(section);
        a.append(ti, th2);
        results.appendChild(a);
      });
    });
    grid.hidden = true;
    results.hidden = !hits;
    emptyMsg.hidden = hits > 0;
  }
  search.addEventListener('input', runSearch);

  /* ---------------- side rail: the cards of the open theme ---------------- */
  let entries = [];
  function buildRail(section) {
    inner.querySelectorAll('.rel-nav-item').forEach((n) => n.remove());
    entries = [];
    const cards = section ? Array.from(section.querySelectorAll('.help-card[data-toc]')) : [];
    rail.hidden = cards.length < 2; // one card (or the FAQ list) does not need a side menu
    if (rail.hidden) return;
    cards.forEach((el) => {
      const link = document.createElement('a');
      link.className = 'rel-nav-item';
      link.href = '#' + el.id;
      link.textContent = cardTitle(el);
      link.addEventListener('click', (e) => {
        e.preventDefault();
        scrollToEl(el);
        history.replaceState(null, '', '#' + el.id);
      });
      inner.appendChild(link);
      entries.push({ el, link });
    });
    spy();
  }

  let last = -1;
  function spy() {
    if (!entries.length) return;
    let active = -1;
    entries.forEach((e, i) => { if (e.el.getBoundingClientRect().top < window.innerHeight * 0.35) active = i; });
    entries.forEach((e, i) => {
      e.link.classList.toggle('is-active', i === active);
      e.link.classList.toggle('is-passed', i <= active);
    });
    const cur = entries[active];
    if (cur) {
      fill.style.height = (cur.link.offsetTop + cur.link.offsetHeight / 2) + 'px';
      if (active !== last) {
        const sc = inner.parentElement;
        if (window.matchMedia('(max-width: 900px)').matches) {
          sc.scrollTo({ left: Math.max(0, cur.link.offsetLeft - (sc.clientWidth - cur.link.offsetWidth) / 2), behavior: 'smooth' });
        } else {
          const top = cur.link.offsetTop, h = cur.link.offsetHeight;
          if (top < sc.scrollTop) sc.scrollTop = top - 8;
          else if (top + h > sc.scrollTop + sc.clientHeight) sc.scrollTop = top + h - sc.clientHeight + 8;
        }
      }
    } else {
      fill.style.height = '0px';
    }
    last = active;
  }
  let ticking = false;
  window.addEventListener('scroll', () => {
    if (ticking || current === null) return;
    ticking = true;
    requestAnimationFrame(() => { spy(); ticking = false; });
  }, { passive: true });

  /* ---------------- views ---------------- */
  function scrollToEl(el) {
    el.scrollIntoView({ behavior: 'smooth', block: 'start' });
    el.classList.remove('is-target');
    void el.offsetWidth;
    el.classList.add('is-target');
  }

  function showHub(scroll) {
    current = null;
    document.querySelectorAll('.help-block').forEach((s) => s.classList.remove('is-current'));
    hub.hidden = false;
    bar.hidden = true;
    layout.hidden = true;
    buildRail(null);
    if (scroll) hub.scrollIntoView({ block: 'start' });
  }

  function showTopic(id, targetId) {
    const section = sec(id);
    if (!section) return showHub(false);
    const changed = current !== id;
    current = id;
    document.querySelectorAll('.help-block').forEach((s) => s.classList.toggle('is-current', s === section));
    // the reveal animation only fires for elements that were visible at load
    section.querySelectorAll('.reveal').forEach((el) => el.classList.add('in-view'));
    hub.hidden = true;
    bar.hidden = false;
    layout.hidden = false;
    search.value = '';
    runSearch();
    buildRail(section);
    const target = targetId && targetId !== id ? document.getElementById(targetId) : null;
    if (target) {
      if (target.tagName === 'DETAILS') target.open = true;
      setTimeout(() => scrollToEl(target), 60);
    } else if (changed) {
      window.scrollTo({ top: 0 });
      bar.scrollIntoView({ block: 'start' });
    }
  }

  function render(scroll) {
    const h = decodeURIComponent(location.hash.slice(1));
    if (!h) return showHub(scroll);
    if (THEMES.some((th) => th.id === h)) return showTopic(h);
    const el = document.getElementById(h);
    const section = el && el.closest('.help-block');
    if (section && THEMES.some((th) => th.id === section.id)) return showTopic(section.id, h);
    showHub(false);
  }

  function navigate(id) {
    history.pushState(null, '', id ? '#' + id : location.pathname + location.search);
    render(true);
  }

  // every in-page link (tiles, search results, "back", links written inside the guides)
  document.addEventListener('click', (e) => {
    const a = e.target.closest('a[href^="#"]');
    if (!a || !a.closest('#help-hub, #help-topic-bar, #toc-main')) return;
    const id = decodeURIComponent(a.getAttribute('href').slice(1));
    if (id && !document.getElementById(id)) return;
    e.preventDefault();
    navigate(id);
  });
  window.addEventListener('popstate', () => render(false));

  document.addEventListener('DOMContentLoaded', () => {
    buildHub();
    render(false);
  });
  if (window.i18n) i18n.onChange(() => {
    buildHub();
    if (current) buildRail(sec(current));
  });
})();
