// M3 Expressive press feedback: keeps the "pressed" shape visible for at least a
// moment so even a quick tap shows the morph (CSS :active alone flashes too fast).
(function () {
  const SEL = '.project-actions a, .project-actions button, .contact-links a, .about-cta, ' +
    '.lang-toggle, .theme-toggle, .nav-logo, .back-link, .help-external-link, .dl-option, .dl-back, .feature-chips span, .project-tags span';
  document.addEventListener('pointerdown', (e) => {
    const el = e.target.closest(SEL);
    if (!el) return;
    el.classList.add('is-pressed');
    const release = () => setTimeout(() => el.classList.remove('is-pressed'), 140);
    ['pointerup', 'pointercancel', 'pointerleave'].forEach((ev) =>
      el.addEventListener(ev, release, { once: true }));
  });
})();

// Info chips: each one keeps morphing between shapes (rectangle, pill, oval, leaf,
// arch, cookie, burst, star, clover...) on its own, and on every tap/click.
(function () {
  const chips = Array.from(document.querySelectorAll('.feature-chips span, .project-tags span'));
  if (!chips.length) return;
  const COUNT = 12;
  const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const next = (el, step) => {
    const cur = parseInt(el.dataset.shape, 10) || 0;
    el.dataset.shape = String((cur + (step || 1)) % COUNT);
    el.classList.remove('shape-pop');
    void el.offsetWidth; // restart the pop animation
    el.classList.add('shape-pop');
  };
  chips.forEach((el, i) => {
    el.dataset.shape = String((i * 5) % COUNT); // different start shape for each chip
    el.addEventListener('click', () => next(el, 1));
  });
  if (reduce) return;
  // one random chip changes shape every ~1.4 s (only while the tab is visible)
  setInterval(() => {
    if (document.hidden) return;
    next(chips[Math.floor(Math.random() * chips.length)], 1 + Math.floor(Math.random() * 3));
  }, 1400);
})();
