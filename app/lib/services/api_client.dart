import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

class ApiClient {
  String? token;
  void Function()? onUnauthorized;

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBase}$path');
  Map<String, String> get _auth => {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(String path) => _json('GET', path);
  Future<dynamic> post(String path, [Map<String, dynamic>? body]) => _json('POST', path, body);
  Future<dynamic> put(String path, [Map<String, dynamic>? body]) => _json('PUT', path, body);
  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) => _json('PATCH', path, body);
  Future<dynamic> delete(String path, [Map<String, dynamic>? body]) => _json('DELETE', path, body);

  Future<dynamic> _json(String method, String path, [Map<String, dynamic>? body]) {
    final req = http.Request(method, _uri(path))
      ..headers.addAll({..._auth, 'Content-Type': 'application/json'});
    if (body != null) req.body = jsonEncode(body);
    return _run(req, const Duration(seconds: 20));
  }

  /// Envoi multipart (champs texte + photo optionnelle).
  Future<dynamic> postMultipart(String path, Map<String, String> fields,
      {String? filePath, String fileField = 'image'}) async {
    final req = http.MultipartRequest('POST', _uri(path))
      ..headers.addAll(_auth)
      ..fields.addAll(fields);
    if (filePath != null) req.files.add(await http.MultipartFile.fromPath(fileField, filePath));
    return _run(req, const Duration(seconds: 60));
  }

  Future<dynamic> _run(http.BaseRequest req, Duration timeout) async {
    http.Response res;
    try {
      res = await http.Response.fromStream(await req.send().timeout(timeout));
    } on TimeoutException {
      throw ApiException('Le serveur met trop de temps à répondre.');
    } catch (_) {
      throw ApiException('Connexion impossible. Vérifie ton réseau.');
    }
    dynamic data;
    if (res.body.isNotEmpty) {
      try {
        data = jsonDecode(res.body);
      } catch (_) {}
    }
    if (res.statusCode == 401) {
      onUnauthorized?.call();
      throw ApiException((data is Map ? data['error'] : null)?.toString() ?? 'Session expirée.', 401);
    }
    if (res.statusCode >= 400) {
      throw ApiException(_message(data, res.statusCode), res.statusCode);
    }
    return data;
  }

  String _message(dynamic data, int status) {
    if (data is Map) {
      if (data['error'] != null) return data['error'].toString();
      final errs = data['errors'];
      if (errs is Map && errs.isNotEmpty) {
        final first = errs.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
      if (data['message'] != null) return data['message'].toString();
    }
    return 'Erreur serveur ($status).';
  }
}
