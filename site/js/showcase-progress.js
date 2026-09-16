// Side rail next to the LastStats "app en detail" walkthrough — fills in as
// you scroll through it, with a tick lighting up for each screenshot passed.
(function () {
  const showcase = document.getElementById('showcase');
  const fill = document.getElementById('showcase-progress-fill');
  const ticksBox = document.getElementById('showcase-progress-ticks');
  if (!showcase || !fill || !ticksBox) return;

  const rows = Array.from(showcase.querySelectorAll('.showcase-row'));
  if (!rows.length) return;

  const ticks = rows.map(() => {
    const tick = document.createElement('span');
    tick.className = 'tick';
    ticksBox.appendChild(tick);
    return tick;
  });

  // rows aren't all the same height, so an evenly-spaced set of ticks used
  // to drift out of sync with the fill (which tracks real scroll distance).
  // Place each tick at its row's actual proportional position instead.
  function positionTicks() {
    const showcaseRect = showcase.getBoundingClientRect();
    const total = showcaseRect.height || 1;
    rows.forEach((row, i) => {
      const rowRect = row.getBoundingClientRect();
      const center = rowRect.top - showcaseRect.top + rowRect.height / 2;
      ticks[i].style.top = Math.min(100, Math.max(0, (center / total) * 100)) + '%';
    });
  }

  function update() {
    const rect = showcase.getBoundingClientRect();
    const viewportMid = window.innerHeight / 2;
    // 0 at the top of the first row, 1 once the last row has passed the middle
    const progress = (viewportMid - rect.top) / (rect.height || 1);
    const clamped = Math.min(1, Math.max(0, progress));
    fill.style.height = (clamped * 100) + '%';

    rows.forEach((row, i) => {
      const rowRect = row.getBoundingClientRect();
      const passed = rowRect.top < viewportMid;
      ticks[i].classList.toggle('is-active', passed);
    });
  }

  let ticking = false;
  window.addEventListener('scroll', () => {
    if (ticking) return;
    ticking = true;
    requestAnimationFrame(() => { update(); ticking = false; });
  }, { passive: true });
  window.addEventListener('resize', () => { positionTicks(); update(); });
  // screenshots loading in can shift row heights after our first measurement
  window.addEventListener('load', () => { positionTicks(); update(); });

  positionTicks();
  update();
})();
