'use strict';
// Simple credential store. Everything stays in the browser (no backend).
const Auth = {
  get username() { return localStorage.getItem('lsd_username') || ''; },
  get apiKey()   { return localStorage.getItem('lsd_apikey')   || ''; },
  get isLoggedIn() { return !!(this.username && this.apiKey); },
  save(username, apiKey) {
    localStorage.setItem('lsd_username', username);
    localStorage.setItem('lsd_apikey', apiKey);
  },
  clear() {
    localStorage.removeItem('lsd_username');
    localStorage.removeItem('lsd_apikey');
  },
};
