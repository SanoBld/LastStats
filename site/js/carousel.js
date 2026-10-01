// Material 3 hero carousel for the screenshot gallery.
// Native scroll-snap does the heavy lifting; js only adds the size/opacity
// falloff, mouse dragging, prev/next buttons, dots and keyboard support.
(function () {
  const root = document.getElementById('m3-carousel');
  if (!root) return;
  const track = root.querySelector('.m3-carousel-track');
  const items = Array.from(track.querySelectorAll('.m3-carousel-item'));
  const prevBtn = root.querySelector('[data-carousel="prev"]');
  const nextBtn = root.querySelector('[data-carousel="next"]');
  const dotsBox = root.querySelector('.m3-carousel-dots');
  if (!items.length) return;

  const reduced = window.matchMedia('(prefers-reduced-motion: reduce)');
  let active = 0;
  let frame = 0;
  let dragged = false;

  const dots = items.map((_, i) => {
    const b = document.createElement('button');
    b.type = 'button';
    b.className = 'm3-carousel-dot';
    b.setAttribute('aria-label', (i + 1) + ' / ' + items.length);
    b.addEventListener('click', () => goTo(i));
    dotsBox.appendChild(b);
    return b;
  });

  function targetLeft(i) {
    const it = items[i];
    return it.offsetLeft + it.offsetWidth / 2 - track.clientWidth / 2;
  }

  function goTo(i, instant) {
    i = Math.max(0, Math.min(items.length - 1, i));
    track.scrollTo({ left: targetLeft(i), behavior: instant || reduced.matches ? 'auto' : 'smooth' });
  }

  // size + opacity falloff, only transforms so scrolling never reflows
  function update() {
    frame = 0;
    const mid = track.scrollLeft + track.clientWidth / 2;
    const w = items[0].offsetWidth;
    const gap = parseFloat(getComputedStyle(track).columnGap) || 0;
    const step = w + gap;
    let best = 0;
    let bestDist = Infinity;

    items.forEach((it, i) => {
      const d = (it.offsetLeft + w / 2 - mid) / step; // signed distance in "cards"
      const a = Math.abs(d);
      const near = Math.min(a, 1);
      const far = Math.min(Math.max(a - 1, 0), 1);
      const s = 1 - 0.17 * near - 0.07 * far;
      const shift = -Math.sign(d) * (1 - s) * w * 0.5;
      it.style.transform = 'translate3d(' + shift.toFixed(1) + 'px,0,0) scale(' + s.toFixed(3) + ')';
      it.style.opacity = (1 - 0.5 * near - 0.2 * far).toFixed(3);
      it.style.zIndex = String(100 - Math.round(a * 10));
      if (a < bestDist) { bestDist = a; best = i; }
    });

    if (best !== active || !items[best].classList.contains('is-active')) {
      active = best;
      items.forEach((it, i) => it.classList.toggle('is-active', i === active));
      dots.forEach((d, i) => {
        d.classList.toggle('is-active', i === active);
        if (i === active) d.setAttribute('aria-current', 'true'); else d.removeAttribute('aria-current');
      });
      prevBtn.disabled = active === 0;
      nextBtn.disabled = active === items.length - 1;
    }
  }

  function schedule() {
    if (!frame) frame = requestAnimationFrame(update);
  }

  track.addEventListener('scroll', schedule, { passive: true });
  window.addEventListener('resize', schedule);
  window.addEventListener('load', () => { goTo(active, true); update(); });
  prevBtn.addEventListener('click', () => goTo(active - 1));
  nextBtn.addEventListener('click', () => goTo(active + 1));

  track.addEventListener('keydown', (e) => {
    const map = { ArrowLeft: active - 1, ArrowRight: active + 1, Home: 0, End: items.length - 1 };
    if (!(e.key in map)) return;
    e.preventDefault();
    goTo(map[e.key]);
  });

  // mouse drag (touch and trackpads already scroll natively)
  let startX = 0;
  let startScroll = 0;
  let startIndex = 0;
  let down = false;

  track.addEventListener('pointerdown', (e) => {
    if (e.pointerType !== 'mouse' || e.button !== 0) return;
    down = true;
    dragged = false;
    startX = e.clientX;
    startScroll = track.scrollLeft;
    startIndex = active;
  });

  window.addEventListener('pointermove', (e) => {
    if (!down) return;
    const dx = e.clientX - startX;
    if (!dragged && Math.abs(dx) > 5) {
      dragged = true;
      track.classList.add('is-dragging'); // turns snapping off while dragging
    }
    if (dragged) track.scrollLeft = startScroll - dx;
  });

  function release(e) {
    if (!down) return;
    down = false;
    if (!dragged) return;
    const dx = e.clientX - startX;
    track.classList.remove('is-dragging');
    update();
    let target = active;
    if (target === startIndex && Math.abs(dx) > 40) target = startIndex + (dx < 0 ? 1 : -1);
    goTo(target);
  }
  window.addEventListener('pointerup', release);
  window.addEventListener('pointercancel', release);

  // runs before the lightbox handler on the <img>:
  // - swallow the click that ends a drag
  // - a click on a side card centers it instead of opening the lightbox
  track.addEventListener('click', (e) => {
    if (dragged) {
      e.stopPropagation();
      e.preventDefault();
      dragged = false;
      return;
    }
    const item = e.target.closest('.m3-carousel-item');
    if (!item) return;
    const i = items.indexOf(item);
    if (i !== active) {
      e.stopPropagation();
      goTo(i);
    }
  }, true);

  update();
})();
