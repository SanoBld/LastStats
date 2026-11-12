// GSAP motion system: one set of tokens for the whole site. Colors stay 100% Material You (CSS).
(function () {
  var R = document.documentElement;
  if (matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  if (!window.gsap) { R.classList.remove('pre-anim', 'show-loader'); return; }
  gsap.registerPlugin(ScrollTrigger, SplitText);
  document.documentElement.classList.add('gsap-on');

  // ---- motion tokens: subtle by default, direction depends on the element's role ----
  var SPRING = 'back.out(1.2)', SOFT = 'power3.out', DECEL = 'expo.out', DUR = .6, STAG = .045;

  function rise(els, o) {
    o = o || {};
    els = gsap.utils.toArray(els);
    if (!els.length) return;
    gsap.from(els, {
      y: o.y == null ? 16 : o.y, x: o.x || 0, scale: o.scale == null ? 1 : o.scale, opacity: 0,
      duration: o.duration || DUR, ease: o.ease || SOFT, stagger: o.stagger == null ? STAG : o.stagger,
      delay: o.delay || 0,
      onStart: function () {
        els.forEach(function (e) { e.style.transition = 'none'; if (e.classList.contains('reveal')) e.classList.add('in-view'); });
      },
      onComplete: function () {
        els.forEach(function (e) { gsap.set(e, { clearProps: 'transform,opacity,transition' }); });
      }
    });
  }

  // Interactive elements (buttons, chips, links): opacity ONLY, so hover/press shape morphs stay intact.
  function fade(els, o) {
    o = o || {};
    els = gsap.utils.toArray(els);
    if (!els.length) return;
    els.forEach(function (e) { // stop CSS from smoothing opacity (keeps other transitions untouched)
      var cs = getComputedStyle(e), pr = cs.transitionProperty;
      if (/opacity/.test(pr)) e.style.transitionProperty = pr.replace(/opacity/g, 'visibility');
      else if (/^all$/.test(pr.trim())) e.style.transitionProperty = 'transform,border-radius,background-color,color,box-shadow,border-color';
      if (e.classList.contains('reveal')) e.classList.add('in-view');
    });
    gsap.from(els, {
      opacity: 0, duration: o.duration || DUR, ease: SOFT, stagger: o.stagger == null ? STAG : o.stagger, delay: o.delay || 0,
      onComplete: function () { els.forEach(function (e) { gsap.set(e, { clearProps: 'opacity' }); e.style.transitionProperty = ''; }); }
    });
  }

  var titles = document.querySelectorAll('.project-page-header h1, .project-page-title');
  gsap.set(titles, { visibility: 'hidden' });

  function splitTitle(h, delay) {
    var s = new SplitText(h, { type: 'chars,words', mask: 'words' });
    gsap.set(h, { visibility: 'visible' });
    gsap.from(s.chars, {
      yPercent: 70, opacity: 0, duration: .8, ease: DECEL, stagger: .022, delay: delay,
      onComplete: function () { s.revert(); }
    });
  }

  function init() {
    R.classList.remove('pre-anim'); // hero is revealed and animated in the same frame
    var q = function (s) { return document.querySelectorAll(s); };
    var batch = function (sel, o) {
      ScrollTrigger.batch(sel, { start: 'top 92%', once: true, onEnter: function (els) { rise(els, o); } });
    };

    // Nav: slides down gently
    gsap.from('.nav', { yPercent: -60, opacity: 0, duration: .7, ease: SOFT, clearProps: 'transform,opacity' });

    // Hero: logo > title > text > chips > buttons (each role has its own direction)
    var t = .1;
    rise(q('.project-logo'), { y: 0, scale: .88, ease: SPRING, duration: .8, delay: t });
    fade(q('.back-link'), { delay: t });
    titles.forEach(function (h) { splitTitle(h, t + .1); });
    rise(q('.project-page-desc'), { delay: t + .4, y: 12 });
    fade(q('.feature-chips span, .project-tags span'), { delay: t + .5, stagger: .03 });
    rise(q('.project-actions'), { delay: t + .6, y: 14 }); // CTA row comes from below
    rise(q('.gh-stats'), { delay: t + .7, y: 10 });

    // Hero background: very light parallax
    var hdr = q('.project-page-header')[0];
    if (hdr) {
      var st = { trigger: hdr, start: 'top top', end: 'bottom top', scrub: true };
      q('.project-hero-bg').length && gsap.to('.project-hero-bg', { yPercent: 12, ease: 'none', scrollTrigger: st });
      q('.project-hero-grid').length && gsap.to('.project-hero-grid', { yPercent: 6, ease: 'none', scrollTrigger: st });
    }

    // Section headings: same mask language as titles, softer
    q('.gallery-section-title, .rel-rail-title, .help-hub-title, .cm-day-title').forEach(function (h) {
      var s = new SplitText(h, { type: 'words', mask: 'words' });
      gsap.from(s.words, {
        yPercent: 60, opacity: 0, duration: .7, ease: DECEL, stagger: .05,
        scrollTrigger: { trigger: h, start: 'top 90%', once: true },
        onComplete: function () { s.revert(); }
      });
    });

    // Content: motion follows the role of the element
    batch('.help-card, .about-app, .about-status', { y: 18 });                 // cards: rise
    batch('.help-block, .legal-block', { y: 10, stagger: .03 });               // long text: barely moves
    batch('.faq-item', { y: 8, stagger: .03, duration: .5 });                  // list rows: quick and light
    batch('.rel-toolbar', { y: 0, x: -14 });                                   // toolbars/filters: from the left
    ScrollTrigger.batch('.rel-filter-btn', { start: 'top 92%', once: true, onEnter: function (els) { fade(els, { stagger: .04 }); } });
    batch('.m3-carousel-controls', { y: 8 });
    batch('.showcase-media', { y: 0, scale: .96, duration: .7 });              // screenshots: gentle zoom, row slide stays CSS
    batch('.showcase-text > *', { y: 10, stagger: .05 });
    batch('.footer-links', { y: 12 });                                         // footer button row: from below

    // Gallery: track slides in, screenshots zoom out of a soft blur one after another
    var car = q('.m3-carousel')[0];
    if (car) {
      var track = car.querySelector('.m3-carousel-track');
      var imgs = Array.prototype.slice.call(car.querySelectorAll('.m3-carousel-item img, .m3-carousel-item video')).slice(0, 6);
      ScrollTrigger.create({ trigger: car, start: 'top 85%', once: true, onEnter: function () {
        gsap.from(track, { x: 56, opacity: 0, duration: .9, ease: DECEL, clearProps: 'transform,opacity' });
        gsap.from(imgs, { scale: 1.14, opacity: 0, duration: .9, ease: DECEL, stagger: .08, clearProps: 'transform,opacity' });
      } });
    }

    // Versions page: platform file lists open/close smoothly (details/summary)
    document.addEventListener('click', function (e) {
      var sum = e.target.closest && e.target.closest('summary.rel-plat-sum');
      if (!sum) return;
      var d = sum.parentNode, box = d.querySelector('.rel-plat-files');
      if (!box || gsap.isTweening(box)) { e.preventDefault(); return; }
      e.preventDefault();
      if (d.open) {
        gsap.to(box, { height: 0, opacity: 0, duration: .35, ease: 'power2.inOut', onComplete: function () { d.open = false; gsap.set(box, { clearProps: 'height,opacity' }); } });
      } else {
        d.open = true;
        gsap.from(box, { height: 0, opacity: 0, duration: .45, ease: DECEL, clearProps: 'height,opacity', onStart: function () { box.style.overflow = 'hidden'; }, onComplete: function () { box.style.overflow = ''; } });
      }
    }, true);

    // Content generated later: releases = rise, commits = from the left (timeline feel), search = fade
    var pending = [], timer;
    var mo = new MutationObserver(function (muts) {
      muts.forEach(function (m) { m.addedNodes.forEach(function (n) { if (n.nodeType === 1 && !n.classList.contains('rel-spinner')) pending.push({ n: n, c: m.target }); }); });
      clearTimeout(timer);
      timer = setTimeout(function () {
        var items = pending.splice(0).slice(0, 14);
        items.forEach(function (it, i) {
          var c = it.c.classList;
          if (it.n.matches('a, button')) { fade(it.n, { delay: i * .03 }); return; }
          rise(it.n, c.contains('cm-rows') ? { y: 0, x: -12, delay: i * .03 } : c.contains('help-hub-results') ? { y: 0, delay: i * .02 } : { y: 12, delay: i * .04 });
        });
        ScrollTrigger.refresh();
      }, 30);
    });
    q('.rel-main, .rel-rail-inner, .cm-rows, .help-hub-results, .help-hub-grid').forEach(function (c) { mo.observe(c, { childList: true }); });
  }

  // Start: wait for DOM + fonts. First visit only: loader (kept until the page is loaded, min 900ms).
  function start() {
    var first = R.classList.contains('show-loader');
    var fonts = document.fonts && document.fonts.ready ? document.fonts.ready : Promise.resolve();
    var loaded = first && document.readyState !== 'complete' ? new Promise(function (r) { addEventListener('load', r); }) : Promise.resolve();
    var min = new Promise(function (r) { setTimeout(r, first ? 900 : 0); });
    Promise.all([fonts, loaded, min]).then(function () {
      if (first) {
        R.classList.add('loader-out');
        try { localStorage.setItem('ls_intro', '1'); } catch (e) {}
        setTimeout(function () { R.classList.remove('show-loader', 'loader-out'); }, 500);
        setTimeout(init, 150);
      } else init();
    });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', function () { setTimeout(start, 0); });
  else start();
})();
