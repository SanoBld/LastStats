// M3 Expressive press feedback: keeps the "pressed" shape visible for at least a
// moment so even a quick tap shows the morph (CSS :active alone flashes too fast).
(function () {
  const SEL = '.project-actions a, .project-actions button, .contact-links a, .about-cta, ' +
    '.lang-toggle, .theme-toggle, .nav-logo, .back-link, .help-external-link, .dl-option';
  document.addEventListener('pointerdown', (e) => {
    const el = e.target.closest(SEL);
    if (!el) return;
    el.classList.add('is-pressed');
    const release = () => setTimeout(() => el.classList.remove('is-pressed'), 140);
    ['pointerup', 'pointercancel', 'pointerleave'].forEach((ev) =>
      el.addEventListener(ev, release, { once: true }));
  });
})();
