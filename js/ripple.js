// effet "ripple" Material Design 3 sur les éléments cliquables (.md-ripple)
(function () {
  document.addEventListener('click', (e) => {
    const target = e.target.closest('.md-ripple');
    if (!target) return;

    const rect = target.getBoundingClientRect();
    const size = Math.max(rect.width, rect.height) * 1.6;
    const ink = document.createElement('span');
    ink.className = 'ripple-ink';
    ink.style.width = ink.style.height = `${size}px`;
    ink.style.left = `${e.clientX - rect.left - size / 2}px`;
    ink.style.top = `${e.clientY - rect.top - size / 2}px`;

    target.appendChild(ink);
    ink.addEventListener('animationend', () => ink.remove());
  });
})();
