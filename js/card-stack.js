// A messy stack of screenshots: click the top card to send it to the back
// of the pile, with the rest of the pile shuffling up right away.
(function () {
  const stack = document.getElementById('card-stack');
  if (!stack) return;

  // keep this array in sync with real DOM order at all times, otherwise the
  // depth assigned below drifts from what's actually on top
  let cards = Array.from(stack.querySelectorAll('.card-stack-item'));
  if (cards.length < 2) return;

  // fixed random jitter per card, set once so each card keeps its own messy
  // tilt as it cycles through the pile instead of snapping to a neat fan
  cards.forEach((card) => {
    card.style.setProperty('--jx', (Math.random() * 10 - 5).toFixed(1) + 'px');
    card.style.setProperty('--jy', (Math.random() * 8 - 4).toFixed(1) + 'px');
    card.style.setProperty('--r', (Math.random() * 16 - 8).toFixed(1) + 'deg');
  });

  function layout() {
    cards.forEach((card, i) => { card.style.setProperty('--i', i); });
  }
  layout();

  function sendToBack(card) {
    card.classList.add('is-leaving'); // starts flying off-screen right away

    // reorder immediately so the rest of the pile shifts up in the same
    // instant, instead of waiting for the leaving card's flight to finish
    cards = cards.filter((c) => c !== card);
    cards.push(card);
    cards.forEach((c, i) => { if (c !== card) c.style.setProperty('--i', i); });

    window.setTimeout(() => {
      stack.appendChild(card);
      card.style.setProperty('--i', cards.length - 1); // its final back-of-pile depth

      // no "return" animation: just snap it straight into its back-of-pile
      // spot with transitions off, instead of fading/sliding it back in
      card.classList.add('is-returning'); // transition: none, applied instantly
      card.classList.remove('is-leaving');
      void card.offsetWidth; // force a reflow so the snap actually applies
      card.classList.remove('is-returning');
    }, 380);
  }

  cards.forEach((card) => {
    card.addEventListener('click', () => {
      if (card.style.getPropertyValue('--i') !== '0') return; // only the top card reacts
      sendToBack(card);
    });
  });
})();
