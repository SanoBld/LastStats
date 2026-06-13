// lib/services/image_cache_backend_web.dart
import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

class ImageCacheBackend {
  static const _dbName    = 'laststats_images';
  static const _storeName = 'cache';
  static const _version   = 1;
  static const _metaKey   = '__meta__';

  static web.IDBDatabase?            _db;
  static Completer<web.IDBDatabase>? _opening;

  static Future<web.IDBDatabase> _open() async {
    if (_db != null) return _db!;
    if (_opening != null) return _opening!.future;

    _opening = Completer<web.IDBDatabase>();
    final req = web.window.indexedDB.open(_dbName, _version);

    req.onupgradeneeded = ((web.IDBVersionChangeEvent _) {
      final db = req.result as web.IDBDatabase;
      if (!db.objectStoreNames.contains(_storeName)) {
        db.createObjectStore(_storeName);
      }
    }).toJS;

    req.onsuccess = ((web.Event _) {
      _db = req.result as web.IDBDatabase;
      _opening!.complete(_db!);
    }).toJS;

    req.onerror = ((web.Event _) {
      _opening!.completeError('IDB open failed');
      _opening = null;
    }).toJS;

    return _opening!.future;
  }

  static Future<JSAny?> _await(web.IDBRequest req) {
    final c = Completer<JSAny?>();
    req.onsuccess = ((web.Event _) => c.complete(req.result)).toJS;
    req.onerror   = ((web.Event _) => c.complete(null)).toJS;
    return c.future;
  }

  static Future<void> _txnDone(web.IDBTransaction txn) {
    final c = Completer<void>();
    txn.oncomplete = ((web.Event _) => c.complete()).toJS;
    txn.onerror    = ((web.Event _) => c.complete()).toJS;
    txn.onabort    = ((web.Event _) => c.complete()).toJS;
    return c.future;
  }

  static Future<String?> readMeta() async {
    try {
      final db     = await _open();
      final txn    = db.transaction(_storeName.toJS, 'readonly');
      final store  = txn.objectStore(_storeName);
      final result = await _await(store.get(_metaKey.toJS));
      if (result == null || result.isUndefinedOrNull) return null;
      return (result as JSString).toDart;
    } catch (_) { return null; }
  }

  static Future<void> writeMeta(String json) async {
    try {
      final db    = await _open();
      final txn   = db.transaction(_storeName.toJS, 'readwrite');
      final store = txn.objectStore(_storeName);
      store.put(json.toJS, _metaKey.toJS);
      await _txnDone(txn);
    } catch (_) {}
  }

  // Images are stored as JSUint8Array (binary, no base64 overhead).
  static Future<Uint8List?> read(String key) async {
    try {
      final db     = await _open();
      final txn    = db.transaction(_storeName.toJS, 'readonly');
      final store  = txn.objectStore(_storeName);
      final result = await _await(store.get(key.toJS));
      if (result == null || result.isUndefinedOrNull) return null;
      return (result as JSUint8Array).toDart;
    } catch (_) { return null; }
  }

  static Future<void> write(String key, Uint8List bytes) async {
    try {
      final db    = await _open();
      final txn   = db.transaction(_storeName.toJS, 'readwrite');
      final store = txn.objectStore(_storeName);
      store.put(bytes.toJS, key.toJS);
      await _txnDone(txn);
    } catch (_) {}
  }

  static Future<void> delete(String key) async {
    try {
      final db    = await _open();
      final txn   = db.transaction(_storeName.toJS, 'readwrite');
      final store = txn.objectStore(_storeName);
      store.delete(key.toJS);
      await _txnDone(txn);
    } catch (_) {}
  }

  // Sum all stored byte arrays.
  static Future<int> totalBytes() async {
    try {
      final db     = await _open();
      final txn    = db.transaction(_storeName.toJS, 'readonly');
      final store  = txn.objectStore(_storeName);
      final result = await _await(store.getAll());
      if (result == null || result.isUndefinedOrNull) return 0;
      int total = 0;
      for (final v in (result as JSArray<JSAny?>).toDart) {
        if (v is JSUint8Array) total += v.toDart.length;
        if (v is JSString)     total += v.toDart.length * 2; // meta string
      }
      return total;
    } catch (_) { return 0; }
  }

  static Future<void> clearAll() async {
    try {
      final db    = await _open();
      final txn   = db.transaction(_storeName.toJS, 'readwrite');
      final store = txn.objectStore(_storeName);
      store.clear();
      await _txnDone(txn);
      _db      = null;
      _opening = null;
    } catch (_) {}
  }
}
