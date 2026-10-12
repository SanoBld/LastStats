// Random Material 3 palette on every page load.
// Same structure as the app (tonal roles, same lightness/saturation steps as
// css/style.css, which is built from a teal-blue seed) but the hue changes at
// each refresh. To keep a fixed color family, e.g. blues only:
//   const hue = 190 + Math.random() * 60;
(function () {
  const hue = Math.floor(Math.random() * 360);
  const h2 = (hue + 60) % 360; // tertiary hue, like the app (shifted hue)
  const c = (h, s, l) => `hsl(${Math.round(h)}, ${s}%, ${l}%)`;

  const light = {
    'primary': c(hue, 60, 30), 'on-primary': '#FFFFFF',
    'primary-container': c(hue, 100, 87), 'on-primary-container': c(hue, 100, 10),
    'secondary': c(hue, 18, 35), 'on-secondary': '#FFFFFF',
    'secondary-container': c(hue, 35, 87), 'on-secondary-container': c(hue, 45, 10),
    'tertiary': c(h2, 18, 42), 'on-tertiary': '#FFFFFF',
    'tertiary-container': c(h2, 100, 93), 'on-tertiary-container': c(h2, 40, 16),
    'background': c(hue, 30, 97), 'on-background': c(hue, 12, 10),
    'on-surface': c(hue, 12, 10), 'on-surface-variant': c(hue, 10, 27),
    'outline-variant': c(hue, 12, 78),
    'surface-container-low': c(hue, 25, 95), 'surface-container': c(hue, 22, 93),
    'surface-container-high': c(hue, 20, 91), 'surface-container-highest': c(hue, 15, 89),
  };
  const dark = {
    'primary': c(hue, 70, 75), 'on-primary': c(hue, 100, 15),
    'primary-container': c(hue, 100, 19), 'on-primary-container': c(hue, 100, 87),
    'secondary': c(hue, 25, 76), 'on-secondary': c(hue, 30, 18),
    'secondary-container': c(hue, 22, 25), 'on-secondary-container': c(hue, 35, 87),
    'tertiary': c(h2, 50, 82), 'on-tertiary': c(h2, 30, 22),
    'tertiary-container': c(h2, 20, 30), 'on-tertiary-container': c(h2, 100, 93),
    'background': c(hue, 22, 7), 'on-background': c(hue, 10, 88),
    'on-surface': c(hue, 10, 88), 'on-surface-variant': c(hue, 10, 77),
    'outline-variant': c(hue, 10, 27),
    'surface-container-low': c(hue, 15, 10), 'surface-container': c(hue, 15, 12),
    'surface-container-high': c(hue, 12, 15), 'surface-container-highest': c(hue, 10, 19),
  };
  const block = (o) => Object.keys(o).map((k) => `--md-${k}:${o[k]}`).join(';');

  // higher specificity than style.css, whatever the load order
  const st = document.createElement('style');
  st.textContent = `html:root{${block(light)}}html[data-theme="dark"]{${block(dark)}}`;
  document.head.appendChild(st);

  const meta = document.querySelector('meta[name="theme-color"]');
  if (meta) meta.setAttribute('content', light.primary);
})();
