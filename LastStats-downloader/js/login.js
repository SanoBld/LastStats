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

    if (!username || apiKey.length < 30) { errEl.textContent = t('err_required'); return; }

    btn.disabled = true;
    btn.textContent = t('btn_connecting');
    try {
      await LastFM.testLogin(username, apiKey);
      Auth.save(username, apiKey);
      location.href = 'download.html';
    } catch {
      errEl.textContent = t('err_invalid');
    } finally {
      btn.disabled = false;
      btn.textContent = t('btn_connect');
    }
  });
}

document.addEventListener('DOMContentLoaded', initLoginForm);
