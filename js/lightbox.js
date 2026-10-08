// Click a screenshot -> see it big. Click it again to zoom in around wherever
// you clicked, click once more (or the backdrop / X / Esc) to close.
// Exposes window.Lightbox.init() so pages that inject images after load
// (like the README-driven about page) can hook new <img> triggers in too.
(function () {
  const lightbox = document.getElementById('lightbox');
  const stage = document.getElementById('lightbox-stage');
  const img = document.getElementById('lightbox-img');
  const closeBtn = document.getElementById('lightbox-close');
  const hint = document.getElementById('lightbox-hint');
  if (!lightbox) return;

  let isZoomed = false;
  let vid = null; // <video> created on first use, shared by every video trigger
  const bound = new WeakSet();

  function open(src, alt) {
    if (vid) { vid.pause(); vid.removeAttribute('src'); vid.hidden = true; }
    img.hidden = false;
    hint.hidden = false;
    img.src = src;
    img.alt = alt || '';
    isZoomed = false;
    img.classList.remove('is-zoomed');
    img.style.transformOrigin = 'center center';
    hint.textContent = (window.i18n && i18n.t('lightboxZoomIn')) || 'Clique pour zoomer';
    lightbox.classList.add('is-open');
    document.body.classList.add('lightbox-locked');
  }

  // videos: same overlay, no zoom, native controls, starts where the page video is
  function openVideo(src, poster, time) {
    if (!vid) {
      vid = document.createElement('video');
      vid.controls = true;
      vid.loop = true;
      vid.muted = true;
      vid.playsInline = true;
      vid.addEventListener('click', (e) => e.stopPropagation());
      stage.appendChild(vid);
    }
    img.hidden = true;
    hint.hidden = true;
    vid.hidden = false;
    vid.poster = poster || '';
    vid.src = src;
    vid.addEventListener('loadedmetadata', function seek() {
      vid.removeEventListener('loadedmetadata', seek);
      if (time && time < vid.duration) vid.currentTime = time;
      vid.play().catch(() => {});
    });
    vid.load();
    lightbox.classList.add('is-open');
    document.body.classList.add('lightbox-locked');
  }

  function close() {
    if (vid) vid.pause();
    lightbox.classList.remove('is-open');
    document.body.classList.remove('lightbox-locked');
    isZoomed = false;
    img.classList.remove('is-zoomed');
  }

  function init(root) {
    const scope = root || document;
    scope.querySelectorAll('.lightbox-trigger img').forEach((t) => {
      if (bound.has(t)) return;
      bound.add(t);
      t.style.cursor = 'zoom-in';
      t.addEventListener('click', () => open(t.src, t.alt));
    });
    scope.querySelectorAll('.lightbox-trigger video').forEach((t) => {
      if (bound.has(t)) return;
      bound.add(t);
      t.style.cursor = 'zoom-in';
      t.addEventListener('click', () => openVideo(t.currentSrc || t.src, t.poster, t.currentTime));
    });
  }

  img.addEventListener('click', (e) => {
    e.stopPropagation();
    if (!isZoomed) {
      const r = img.getBoundingClientRect();
      const originX = ((e.clientX - r.left) / r.width) * 100;
      const originY = ((e.clientY - r.top) / r.height) * 100;
      img.style.transformOrigin = originX + '% ' + originY + '%';
      img.classList.add('is-zoomed');
      hint.textContent = (window.i18n && i18n.t('lightboxZoomOut')) || 'Clique pour dézoomer';
      isZoomed = true;
    } else {
      img.classList.remove('is-zoomed');
      hint.textContent = (window.i18n && i18n.t('lightboxZoomIn')) || 'Clique pour zoomer';
      isZoomed = false;
    }
  });

  closeBtn.addEventListener('click', close);
  stage.addEventListener('click', (e) => { if (e.target === stage) close(); });
  lightbox.addEventListener('click', (e) => { if (e.target === lightbox) close(); });
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && lightbox.classList.contains('is-open')) close();
  });

  window.Lightbox = { init };
  init();
})();
