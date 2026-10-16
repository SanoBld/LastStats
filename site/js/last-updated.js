// Shows the real "last updated" date on the legal page.
// The date comes from data/meta.json, generated at deploy time from git history.
(function () {
  const el = document.getElementById('legal-updated');
  if (!el) return;
  fetch('data/meta.json', { cache: 'no-cache' })
    .then((r) => (r.ok ? r.json() : Promise.reject()))
    .then((m) => {
      const d = new Date(m.legal);
      if (isNaN(d)) return;
      function render() {
        const lang = document.documentElement.lang || 'fr';
        let s;
        try { s = new Intl.DateTimeFormat(lang, { day: 'numeric', month: 'long', year: 'numeric' }).format(d); }
        catch (e) { s = d.toLocaleDateString(); }
        const tpl = (window.i18n && i18n.t('legal.last_updated')) || 'Last updated: {date}.';
        el.textContent = tpl.replace('{date}', s);
        el.hidden = false;
      }
      render();
      if (window.i18n) i18n.onChange(render);
    })
    .catch(() => {});
})();
