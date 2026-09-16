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
    ticking = false;
  }

  window.addEventListener('scroll', () => {
    if (!ticking) {
      requestAnimationFrame(onScroll);
      ticking = true;
    }
  }, { passive: true });
})();
