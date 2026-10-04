// Web version button: shows a beta warning, then opens the Flutter Web build
// in a new tab. Reuses the .dl-modal look from download-modal.js.
(function () {
  const trigger = document.getElementById('web-trigger');
  if (!trigger) return;

  const webUrl = trigger.getAttribute('data-web-url') || 'https://sanobld.github.io/LastStats/app/';
  let modal = null;

  function t(key, fallback) {
    return (window.i18n && i18n.t(key)) || fallback;
  }

  function render() {
    const box = modal.querySelector('.dl-modal-box');
    box.setAttribute('aria-labelledby', 'web-modal-title');
    box.querySelector('#web-modal-content').innerHTML = `
      <div class="web-warn-icon" aria-hidden="true">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"/><path d="M12 9v4"/><path d="M12 17h.01"/></svg>
      </div>
      <h3 class="dl-modal-title" id="web-modal-title">${t('webWarnTitle', 'Version web (bêta)')}</h3>
      <p class="web-warn-body">${t('webWarnBody', "La version web est expérimentale : elle peut contenir des bugs ou des incompatibilités.")}</p>
      <div class="web-warn-actions">
        <button type="button" class="web-warn-cancel md-ripple" id="web-cancel">${t('webCancel', 'Annuler')}</button>
        <a class="web-warn-open md-ripple" href="${webUrl}" target="_blank" rel="noopener" id="web-open">${t('webOpen', 'Ouvrir la version web')}</a>
      </div>`;
    box.querySelector('#web-cancel').addEventListener('click', close);
    box.querySelector('#web-open').addEventListener('click', () => setTimeout(close, 150));
    box.querySelector('#web-modal-close').setAttribute('aria-label', t('webClose', 'Fermer'));
  }

  function build() {
    const el = document.createElement('div');
    el.className = 'dl-modal';
    el.id = 'web-modal';
    el.setAttribute('aria-hidden', 'true');
    el.innerHTML = `
      <div class="dl-modal-box" role="dialog" aria-modal="true">
        <button type="button" class="dl-modal-close" id="web-modal-close" aria-label="Fermer">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
        </button>
        <div id="web-modal-content"></div>
      </div>`;
    document.body.appendChild(el);
    el.querySelector('#web-modal-close').addEventListener('click', close);
    el.addEventListener('click', (e) => { if (e.target === el) close(); });
    document.addEventListener('keydown', (e) => { if (e.key === 'Escape') close(); });
    return el;
  }

  function open() {
    if (!modal) modal = build();
    render();
    modal.classList.add('is-open');
    modal.removeAttribute('aria-hidden');
  }

  function close() {
    if (!modal) return;
    modal.classList.remove('is-open');
    modal.setAttribute('aria-hidden', 'true');
  }

  trigger.addEventListener('click', open);

  // refresh the text if the language changes while the warning is open
  if (window.i18n) {
    i18n.onChange(() => {
      if (modal && modal.classList.contains('is-open')) render();
    });
  }
})();
