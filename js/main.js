// simple reveal-on-scroll, nothing fancy, just IntersectionObserver
(function () {
  const items = document.querySelectorAll('.reveal, .reveal-fade, .reveal-x');

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add('in-view');
          observer.unobserve(entry.target); // reveal once, no need to redo it
        }
      });
    },
    { threshold: 0.15 }
  );

  items.forEach((el) => observer.observe(el));
})();
