import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Thin wrapper around the SafeTrack Cloudflare Workers backend.
class ApiClient {
  String? token;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    return Uri.parse('${ApiConfig.baseUrl}$path').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
    );
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    final res = await http.get(_uri(path, query), headers: _headers);
    return _decode(res);
  }

  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) async {
    final res = await http.post(_uri(path), headers: _headers, body: jsonEncode(body ?? {}));
    return _decode(res);
  }

  Future<Map<String, dynamic>> patch(String path, [Map<String, dynamic>? body]) async {
    final res = await http.patch(_uri(path), headers: _headers, body: jsonEncode(body ?? {}));
    return _decode(res);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final res = await http.delete(_uri(path), headers: _headers);
    return _decode(res);
  }

  Future<Map<String, dynamic>> uploadFile(
    String path, {
    required String fieldName,
    required Uint8List bytes,
    required String filename,
    Map<String, String>? fields,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (fields != null) request.fields.addAll(fields);
    request.files.add(http.MultipartFile.fromBytes(fieldName, bytes, filename: filename));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> data = {};
    if (res.body.isNotEmpty) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    }
    if (res.statusCode >= 400) {
      throw ApiException(
        (data['error'] as String?) ?? 'Request failed (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    return data;
  }
}
