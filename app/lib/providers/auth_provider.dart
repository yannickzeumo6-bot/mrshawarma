import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../services/push_service.dart';

/// Un AuthProvider par application : `role` = 'client' ou 'admin' (ou 'livreur' plus tard).
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._api, {required this.role}) {
    _api.onUnauthorized = () {
      if (isLoggedIn) logout(remote: false);
    };
  }

  final ApiClient _api;
  final String role;
  String get _kToken => 'auth_token_$role';
  String get _kUser => 'auth_user_$role';

  String? _token;
  AppUser? _user;

  bool get isLoggedIn => _token != null && _user != null;
  AppUser? get user => _user;

  Future<void> restore() async {
    final p = await SharedPreferences.getInstance();
    final t = p.getString(_kToken);
    final u = p.getString(_kUser);
    if (t != null && u != null) {
      try {
        _user = AppUser.fromJson(jsonDecode(u) as Map<String, dynamic>);
        _token = t;
        _api.token = t;
      } catch (_) {}
    }
  }

  Future<void> login(String email, String password) async {
    final d = await _api.post('/api/auth/login', {'email': email.trim(), 'password': password});
    await _accept(d);
  }

  Future<void> register(String name, String email, String password) async {
    final d = await _api.post('/api/auth/register', {'name': name.trim(), 'email': email.trim(), 'password': password});
    await _accept(d);
  }

  Future<void> _accept(dynamic d) async {
    final user = AppUser.fromJson(d['user'] as Map<String, dynamic>);
    final token = d['token'] as String;
    if (user.role != role) {
      // Compte d'un autre espace : on révoque le jeton qu'on vient de recevoir.
      try {
        _api.token = token;
        await _api.post('/api/auth/logout');
      } catch (_) {}
      _api.token = null;
      final espace = switch (user.role) { 'admin' => "l'espace administrateur", 'livreur' => "l'espace livreur", _ => "l'application client" };
      throw ApiException("Ce compte n'appartient pas à cet espace. Utilise $espace.");
    }
    _token = token;
    _user = user;
    _api.token = token;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kToken, token);
    await p.setString(_kUser, jsonEncode(user.toJson()));
    notifyListeners();
  }

  Future<void> logout({bool remote = true}) async {
    if (remote && _token != null) {
      await PushService.instance.unregisterDevice(_api);
      try {
        await _api.post('/api/auth/logout');
      } catch (_) {}
    }
    _token = null;
    _user = null;
    _api.token = null;
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken);
    await p.remove(_kUser);
    notifyListeners();
  }
}
