'use strict';
// Simple credential store. Everything stays in the browser (no backend).
const Auth = {
  get username() { return localStorage.getItem('lsd_username') || ''; },
  get apiKey()   { return localStorage.getItem('lsd_apikey')   || ''; },
  get imagesKey() { return localStorage.getItem('lsd_images_key') || ''; }, // optional, for nicer artist photos
  get isLoggedIn() { return !!(this.username && this.apiKey); },
  save(username, apiKey, imagesKey) {
    localStorage.setItem('lsd_username', username);
    localStorage.setItem('lsd_apikey', apiKey);
    localStorage.setItem('lsd_images_key', imagesKey || '');
  },
  clear() {
    localStorage.removeItem('lsd_username');
    localStorage.removeItem('lsd_apikey');
    localStorage.removeItem('lsd_images_key');
  },
};
