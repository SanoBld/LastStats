// Hide the nav bar when scrolling down, bring it back when scrolling up.
(function () {
  const nav = document.querySelector('.nav');
  if (!nav) return;

  let lastY = window.scrollY;
  let ticking = false;

  function onScroll() {
    const y = window.scrollY;
    // ignore tiny jitters and stay visible near the very top
    if (y < 80) {
      nav.classList.remove('nav-hidden');
    } else if (y > lastY + 4) {
      nav.classList.add('nav-hidden'); // scrolling down
    } else if (y < lastY - 4) {
      nav.classList.remove('nav-hidden'); // scrolling up
    }
    lastY = y;
    // lets sticky elements (versions rail) follow the nav: below it when shown, at the top when hidden
    document.body.classList.toggle('nav-is-hidden', nav.classList.contains('nav-hidden'));
    ticking = false;
  }

  window.addEventListener('scroll', () => {
    if (!ticking) {
      requestAnimationFrame(onScroll);
      ticking = true;
    }
  }, { passive: true });
})();
