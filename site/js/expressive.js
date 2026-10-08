// M3 Expressive press feedback: keeps the "pressed" shape visible for at least a
// moment so even a quick tap shows the morph (CSS :active alone flashes too fast).
(function () {
  const SEL = '.project-actions a, .project-actions button, .contact-links a, .about-cta, ' +
    '.lang-toggle, .theme-toggle, .nav-logo, .back-link, .help-external-link, .dl-option, .dl-back, .cm-btn, .cm-sha, .feature-chips span, .project-tags span';
  document.addEventListener('pointerdown', (e) => {
    const el = e.target.closest(SEL);
    if (!el) return;
    el.classList.add('is-pressed');
    // release once, then drop all three listeners (a leftover pointerleave
    // listener used to cut short the pressed shape of the next press)
    const events = ['pointerup', 'pointercancel', 'pointerleave'];
    const release = () => {
      events.forEach((ev) => el.removeEventListener(ev, release));
      setTimeout(() => el.classList.remove('is-pressed'), 140);
    };
    events.forEach((ev) => el.addEventListener(ev, release));
  });
})();

