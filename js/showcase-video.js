// Plays showcase videos only while visible. Reduced motion: no autoplay, show controls.
(function () {
  const vids = Array.from(document.querySelectorAll('video.showcase-video'));
  if (!vids.length) return;
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    vids.forEach((v) => { v.removeAttribute('autoplay'); v.pause(); v.controls = true; });
    return;
  }
  const io = new IntersectionObserver((entries) => {
    entries.forEach((e) => {
      if (e.isIntersecting) e.target.play().catch(() => {});
      else e.target.pause();
    });
  }, { threshold: 0.35 });
  vids.forEach((v) => io.observe(v));
})();
