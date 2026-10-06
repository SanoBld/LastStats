// Table of contents + search for the help and legal pages.
// Sections: [data-toc="h2"], sub-items: [data-toc="h3"]. Titles are read from the first heading.
(function () {
  const main = document.getElementById('toc-main');
  const rail = document.getElementById('toc-rail');
  const inner = document.getElementById('toc-inner');
  const fill = document.getElementById('toc-fill');
  const search = document.getElementById('toc-search');
  const empty = document.getElementById('toc-empty');
  if (!main || !rail) return;

  const t = (k) => (window.i18n ? i18n.t(k) : k);
  let entries = []; // { el, link, level }

  // blocks that the search can hide: cards, FAQ items, legal blocks
  const blocks = () => Array.from(main.querySelectorAll('.help-card, .faq-item, .legal-block'));

  function build() {
    inner.querySelectorAll('.rel-nav-item').forEach((n) => n.remove());
    entries = Array.from(main.querySelectorAll('[data-toc]')).map((el) => {
      const h = el.querySelector('h2, h3');
      const level = el.getAttribute('data-toc');
      const link = document.createElement('a');
      link.className = 'rel-nav-item' + (level === 'h3' ? ' is-sub' : '');
      link.href = '#' + el.id;
      link.textContent = h ? h.textContent.trim() : el.id;
      link.addEventListener('click', (e) => { e.preventDefault(); goTo(el.id); });
      inner.appendChild(link);
      return { el, link, level };
    });
    rail.hidden = !entries.length;
    search.placeholder = t('releases.search');
    filter();
    spy();
  }

  function goTo(id) {
    const el = document.getElementById(id);
    if (!el) return;
    if (el.tagName === 'DETAILS') el.open = true;
    el.scrollIntoView({ behavior: 'smooth', block: 'start' });
    el.classList.remove('is-target');
    void el.offsetWidth;
    el.classList.add('is-target');
    history.replaceState(null, '', '#' + id);
  }

  // search: hide blocks that do not match, then hide empty sections and their rail items
  function filter() {
    const q = search.value.trim().toLowerCase();
    let hits = 0;
    blocks().forEach((b) => {
      const ok = !q || b.textContent.toLowerCase().includes(q);
      b.hidden = !ok;
      if (ok && q && b.tagName === 'DETAILS') b.open = true; // show the answer of a matching FAQ item
    });
    entries.forEach((e) => {
      if (e.level === 'h3') { e.el.hidden = !!q && e.el.hidden; }
    });
    entries.forEach((e) => {
      let ok;
      if (!q) ok = true;
      else if (e.level === 'h3') ok = !e.el.hidden;
      else ok = Array.from(e.el.querySelectorAll('.help-card, .faq-item, .legal-block')).some((b) => !b.hidden) ||
        (!e.el.querySelector('.help-card, .faq-item') && e.el.textContent.toLowerCase().includes(q));
      if (e.level === 'h2') e.el.hidden = !ok;
      e.link.hidden = !ok;
      if (ok && e.level === 'h2') hits++;
    });
    rail.classList.toggle('is-searching', !!q);
    empty.hidden = !q || hits > 0;
  }
  search.addEventListener('input', filter);

  // scroll spy: last visible block above 35% of the viewport is the active one
  let last = -1;
  function spy() {
    let active = -1;
    entries.forEach((e, i) => {
      if (e.el.hidden) return;
      if (e.el.getBoundingClientRect().top < window.innerHeight * 0.35) active = i;
    });
    entries.forEach((e, i) => {
      e.link.classList.toggle('is-active', i === active);
      e.link.classList.toggle('is-passed', i <= active);
    });
    const cur = entries[active];
    if (cur && !cur.link.hidden) {
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
    }
    last = active;
  }
  let ticking = false;
  window.addEventListener('scroll', () => {
    if (ticking) return;
    ticking = true;
    requestAnimationFrame(() => { spy(); ticking = false; });
  }, { passive: true });

  // build after i18n has filled the texts, rebuild when the language changes
  document.addEventListener('DOMContentLoaded', () => {
    build();
    const hash = decodeURIComponent(location.hash.slice(1));
    if (hash) setTimeout(() => goTo(hash), 150);
  });
  if (window.i18n) i18n.onChange(build);
})();
