// Material 3 hero carousel for the screenshot gallery (endless loop).
// Native scroll-snap does the heavy lifting. The track holds 3 copies of the items
// (clones, original, clones). When scrolling settles outside the middle copy,
// we jump back by exactly one copy width, so the loop never ends and the jump is invisible.
// Videos only play while their card is the centered one.
(function () {
  const root = document.getElementById('m3-carousel');
  if (!root) return;
  const track = root.querySelector('.m3-carousel-track');
  const originals = Array.from(track.querySelectorAll('.m3-carousel-item'));
  const prevBtn = root.querySelector('[data-carousel="prev"]');
  const nextBtn = root.querySelector('[data-carousel="next"]');
  const dotsBox = root.querySelector('.m3-carousel-dots');
  const N = originals.length;
  if (!N) return;

  function clone(it) {
    const c = it.cloneNode(true);
    c.classList.add('is-clone');
    c.setAttribute('aria-hidden', 'true');
    return c;
  }
  const head = document.createDocumentFragment();
  originals.forEach((it) => head.appendChild(clone(it)));
  track.insertBefore(head, originals[0]);
  originals.forEach((it) => track.appendChild(clone(it)));
  const items = Array.from(track.querySelectorAll('.m3-carousel-item'));
  if (window.Lightbox && window.Lightbox.init) window.Lightbox.init(track);

  const reduced = window.matchMedia('(prefers-reduced-motion: reduce)');
  let active = N;
  let frame = 0;
  let dragged = false;
  let down = false;
  let touching = false;
  let visible = true;
  let settleTimer = 0;

  const dots = originals.map((_, i) => {
    const b = document.createElement('button');
    b.type = 'button';
    b.className = 'm3-carousel-dot';
    b.setAttribute('aria-label', (i + 1) + ' / ' + N);
    b.addEventListener('click', () => {
      // pick the copy of this item that is closest to the current one
      let best = N + i;
      [i, N + i, 2 * N + i].forEach((c) => { if (Math.abs(c - active) < Math.abs(best - active)) best = c; });
      goTo(best);
    });
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

  function syncVideos() {
    items.forEach((it, i) => {
      const v = it.querySelector('video');
      if (!v) return;
      if (i === active && visible && !reduced.matches) v.play().catch(() => {});
      else v.pause();
    });
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
      const logical = active % N;
      dots.forEach((d, i) => {
        d.classList.toggle('is-active', i === logical);
        if (i === logical) d.setAttribute('aria-current', 'true'); else d.removeAttribute('aria-current');
      });
      syncVideos();
    }
  }

  function schedule() {
    if (!frame) frame = requestAnimationFrame(update);
  }

  // jump back to the middle copy once scrolling has settled
  function recenter() {
    if (down || touching) return;
    let shift = 0;
    const setW = items[N].offsetLeft - items[0].offsetLeft;
    if (active < N) shift = setW;
    else if (active >= 2 * N) shift = -setW;
    if (!shift) return;
    track.classList.add('is-dragging'); // snapping + smooth scrolling off during the jump
    track.scrollLeft += shift;
    void track.offsetWidth;
    track.classList.remove('is-dragging');
    update();
  }

  function onScroll() {
    schedule();
    clearTimeout(settleTimer);
    settleTimer = setTimeout(recenter, 150);
  }

  track.addEventListener('scroll', onScroll, { passive: true });
  track.addEventListener('touchstart', () => { touching = true; }, { passive: true });
  const touchEnd = () => { touching = false; clearTimeout(settleTimer); settleTimer = setTimeout(recenter, 150); };
  track.addEventListener('touchend', touchEnd, { passive: true });
  track.addEventListener('touchcancel', touchEnd, { passive: true });
  window.addEventListener('resize', () => requestAnimationFrame(() => { goTo(active, true); update(); }));
  window.addEventListener('load', () => { goTo(active, true); update(); });
  prevBtn.addEventListener('click', () => goTo(active - 1));
  nextBtn.addEventListener('click', () => goTo(active + 1));

  if ('IntersectionObserver' in window) {
    new IntersectionObserver((entries) => {
      visible = entries[0].isIntersecting;
      syncVideos();
    }, { threshold: 0.2 }).observe(root);
  }

  track.addEventListener('keydown', (e) => {
    const map = { ArrowLeft: active - 1, ArrowRight: active + 1, Home: N, End: 2 * N - 1 };
    if (!(e.key in map)) return;
    e.preventDefault();
    goTo(map[e.key]);
  });

  // mouse drag (touch and trackpads already scroll natively)
  let startX = 0;
  let startScroll = 0;
  let startIndex = 0;

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

  goTo(active, true);
  update();
})();
