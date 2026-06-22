'use strict';
// Already logged in? skip the form.
if (Auth.isLoggedIn) location.href = 'download.html';

function initLoginForm() {
  const form  = document.getElementById('login-form');
  const errEl = document.getElementById('login-error');
  const btn   = document.getElementById('btn-connect');

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    errEl.textContent = '';

    const username = document.getElementById('input-username').value.trim();
    const apiKey   = document.getElementById('input-apikey').value.trim();
    const imagesKey = document.getElementById('input-imageskey').value.trim();

    if (!username || apiKey.length < 30) { errEl.textContent = t('err_required'); return; }

    btn.disabled = true;
    btn.textContent = t('btn_connecting');
    try {
      const user = await LastFM.testLogin(username, apiKey);
      Auth.save(username, apiKey, imagesKey, pickAvatarUrl(user));
      location.href = 'download.html';
    } catch {
      errEl.textContent = t('err_invalid');
    } finally {
      btn.disabled = false;
      btn.textContent = t('btn_connect');
    }
  });
}

// Last.fm returns an array of avatar sizes; take the largest one that actually has a URL.
function pickAvatarUrl(user) {
  const imgs = user?.image || [];
  for (let i = imgs.length - 1; i >= 0; i--) {
    if (imgs[i]['#text']) return imgs[i]['#text'];
  }
  return '';
}

document.addEventListener('DOMContentLoaded', initLoginForm);
