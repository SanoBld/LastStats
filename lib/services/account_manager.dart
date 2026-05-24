// lib/services/account_manager.dart
// ══════════════════════════════════════════════════════════════════════════
//  AccountManager — gestion de comptes multiples (max 3)
//
//  Stockage SharedPreferences :
//    ls_accounts        → JSON [{"username":"…","apiKey":"…"}, …]
//    ls_active_account  → index int du compte actif
//
//  Rétrocompatibilité :
//    Si ls_accounts est absent, migre automatiquement ls_username /
//    ls_apikey existants vers un compte unique.
//
//  Règles :
//    • Maximum 3 comptes simultanés.
//    • Pas de doublon de username (insensible à la casse).
//    • ls_username / ls_apikey sont toujours synchronisés avec le compte
//      actif (compatibilité avec le reste de l'app).
// ══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ── Modèle ────────────────────────────────────────────────────────────────────

class AccountEntry {
  final String username;
  final String apiKey;

  const AccountEntry({required this.username, required this.apiKey});

  bool get isValid => username.isNotEmpty && apiKey.isNotEmpty;

  Map<String, dynamic> toJson() => {'username': username, 'apiKey': apiKey};

  factory AccountEntry.fromJson(Map<String, dynamic> j) => AccountEntry(
        username: (j['username'] as String?) ?? '',
        apiKey:   (j['apiKey']   as String?) ?? '',
      );
}

// ── Service ───────────────────────────────────────────────────────────────────

class AccountManager {
  AccountManager._();

  static const _kAccounts = 'ls_accounts';
  static const _kActive   = 'ls_active_account';
  static const maxAccounts = 3;

  // ── Lecture ──────────────────────────────────────────────────────────────

  /// Retourne la liste de tous les comptes enregistrés.
  /// Migre automatiquement depuis ls_username / ls_apikey si nécessaire.
  static Future<List<AccountEntry>> getAll() async {
    final p   = await SharedPreferences.getInstance();
    final raw = p.getString(_kAccounts);

    if (raw == null || raw.isEmpty) {
      return _migrate(p);
    }
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => AccountEntry.fromJson(e as Map<String, dynamic>))
          .where((e) => e.isValid)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Retourne l'index du compte actif (0 si non défini).
  static Future<int> getActiveIndex() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kActive) ?? 0;
  }

  /// Retourne le compte actif, ou null si aucun compte.
  static Future<AccountEntry?> getActive() async {
    final accounts = await getAll();
    if (accounts.isEmpty) return null;
    final idx = await getActiveIndex();
    return accounts[idx.clamp(0, accounts.length - 1)];
  }

  // ── Écriture ─────────────────────────────────────────────────────────────

  /// Ajoute un nouveau compte. Retourne false si la liste est pleine
  /// ou si le username est déjà présent.
  static Future<bool> add(AccountEntry entry) async {
    if (!entry.isValid) return false;
    final accounts = await getAll();
    if (accounts.length >= maxAccounts) return false;
    if (accounts.any(
        (e) => e.username.toLowerCase() == entry.username.toLowerCase())) {
      return false;
    }
    accounts.add(entry);
    await _save(accounts);
    return true;
  }

  /// Supprime le compte à [index].
  /// Le compte principal (index 0 avec un seul compte) ne peut pas être
  /// supprimé via cette méthode — utiliser le flux de déconnexion globale.
  /// Si le compte supprimé était actif, bascule sur l'index 0.
  static Future<void> remove(int index) async {
    final accounts = await getAll();
    if (index < 0 || index >= accounts.length || accounts.length <= 1) return;

    final p         = await SharedPreferences.getInstance();
    final wasActive = (p.getInt(_kActive) ?? 0) == index;

    accounts.removeAt(index);
    await _save(accounts);

    final newActive = wasActive ? 0 : (p.getInt(_kActive) ?? 0);
    final clamped   = newActive.clamp(0, accounts.length - 1);
    await p.setInt(_kActive, clamped);
    await _syncPrefs(p, accounts[clamped]);
  }

  /// Active le compte à [index] et synchronise ls_username / ls_apikey.
  static Future<void> switchTo(int index) async {
    final accounts = await getAll();
    if (index < 0 || index >= accounts.length) return;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kActive, index);
    await _syncPrefs(p, accounts[index]);
  }

  // ── Helpers privés ────────────────────────────────────────────────────────

  /// Migre depuis ls_username / ls_apikey (ancienne version mono-compte).
  static Future<List<AccountEntry>> _migrate(SharedPreferences p) async {
    final u = p.getString('ls_username') ?? '';
    final k = p.getString('ls_apikey')   ?? '';
    if (u.isEmpty || k.isEmpty) return [];
    final entry = AccountEntry(username: u, apiKey: k);
    await _save([entry]);
    await p.setInt(_kActive, 0);
    return [entry];
  }

  static Future<void> _save(List<AccountEntry> accounts) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _kAccounts, jsonEncode(accounts.map((e) => e.toJson()).toList()));
  }

  /// Synchronise ls_username / ls_apikey avec le compte donné.
  static Future<void> _syncPrefs(
      SharedPreferences p, AccountEntry acc) async {
    await p.setString('ls_username', acc.username);
    await p.setString('ls_apikey',   acc.apiKey);
  }
}