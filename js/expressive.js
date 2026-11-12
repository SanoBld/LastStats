// M3 Expressive press feedback: keeps the "pressed" shape visible for at least a
// moment so even a quick tap shows the morph (CSS :active alone flashes too fast).
(function () {
  const SEL = '.project-actions a, .project-actions button, .contact-links a, .about-cta, ' +
    '.lang-toggle, .theme-toggle, .nav-logo, .back-link, .help-external-link, .dl-option, .dl-back, .cm-btn, .cm-sha, .feature-chips span, .project-tags span, ' +
    '.footer .footer-links.footer-buttons a, .rel-filter-btn, .rel-gh, .rel-more, .rel-toggle, .rel-asset, .rel-plat-sum, .cm-tr-btn, .color-random, .m3-carousel-btn';
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


// Hero grid vibration: tiny buzz while the pointer moves over the header, a thump on press.
(function () {
  var grid = document.querySelector('.project-hero-grid');
  var head = grid && grid.parentElement;
  if (!head || matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  var idle;
  head.addEventListener('pointermove', function (e) {
    var r = grid.getBoundingClientRect();
    grid.style.setProperty('--mx', (e.clientX - r.left) + 'px');
    grid.style.setProperty('--my', (e.clientY - r.top) + 'px');
    if (grid.classList.contains('is-press')) return;
    grid.classList.add('is-hover');
    clearTimeout(idle);
    idle = setTimeout(function () { grid.classList.remove('is-hover'); }, 180);
  });
  head.addEventListener('pointerleave', function () { clearTimeout(idle); grid.classList.remove('is-hover'); });
  head.addEventListener('pointerdown', function (e) {
    var r = grid.getBoundingClientRect();
    grid.style.setProperty('--mx', (e.clientX - r.left) + 'px');
    grid.style.setProperty('--my', (e.clientY - r.top) + 'px');
    grid.classList.remove('is-hover', 'is-press');
    void grid.offsetWidth;
    grid.classList.add('is-press');
  });
  grid.addEventListener('animationend', function (e) { if (e.animationName === 'grid-thump') grid.classList.remove('is-press'); });
})();
