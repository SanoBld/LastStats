// Click a screenshot -> see it big. Click it again to zoom in around wherever
// you clicked, click once more (or the backdrop / X / Esc) to close.
(function () {
  const lightbox = document.getElementById('lightbox');
  const stage = document.getElementById('lightbox-stage');
  const img = document.getElementById('lightbox-img');
  const closeBtn = document.getElementById('lightbox-close');
  const hint = document.getElementById('lightbox-hint');
  const triggers = document.querySelectorAll('.lightbox-trigger img');
  if (!lightbox || !triggers.length) return;

  let isZoomed = false;

  function open(src, alt) {
    img.src = src;
    img.alt = alt || '';
    isZoomed = false;
    img.classList.remove('is-zoomed');
    img.style.transformOrigin = 'center center';
    hint.textContent = (window.i18n && i18n.t('lightboxZoomIn')) || 'Clique pour zoomer';
    lightbox.classList.add('is-open');
    document.body.classList.add('lightbox-locked');
  }

  function close() {
    lightbox.classList.remove('is-open');
    document.body.classList.remove('lightbox-locked');
    isZoomed = false;
    img.classList.remove('is-zoomed');
  }

  triggers.forEach((t) => {
    t.addEventListener('click', () => open(t.src, t.alt));
  });

  img.addEventListener('click', (e) => {
    e.stopPropagation();
    if (!isZoomed) {
      // zoom in centered on wherever the click landed
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
})();
