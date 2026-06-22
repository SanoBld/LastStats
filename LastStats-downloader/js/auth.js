'use strict';
// Simple credential store. Everything stays in the browser (no backend).
const Auth = {
  get username() { return localStorage.getItem('lsd_username') || ''; },
  get apiKey()   { return localStorage.getItem('lsd_apikey')   || ''; },
  get imagesKey() { return localStorage.getItem('lsd_images_key') || ''; }, // optional, for nicer artist photos
  get avatarUrl() { return localStorage.getItem('lsd_avatar_url') || ''; }, // Last.fm profile picture, if any
  get isLoggedIn() { return !!(this.username && this.apiKey); },
  save(username, apiKey, imagesKey, avatarUrl) {
    localStorage.setItem('lsd_username', username);
    localStorage.setItem('lsd_apikey', apiKey);
    localStorage.setItem('lsd_images_key', imagesKey || '');
    localStorage.setItem('lsd_avatar_url', avatarUrl || '');
  },
  clear() {
    localStorage.removeItem('lsd_username');
    localStorage.removeItem('lsd_apikey');
    localStorage.removeItem('lsd_images_key');
    localStorage.removeItem('lsd_avatar_url');
  },
};
