import 'dart:convert';
import 'package:http/http.dart' as http;

import '../errors/app_exceptions.dart';

typedef TokenProvider = Future<String?> Function();

/// Thin HTTP client centralizing base URL, JSON encoding/decoding and auth
/// header injection. Repositories layer their business logic on top of this.
class ApiClient {
  ApiClient({required this.baseUrl, this.tokenProvider});

  final String baseUrl;
  final TokenProvider? tokenProvider;

  Future<Map<String, String>> _headers({bool json = true, bool auth = false}) async {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (auth && tokenProvider != null) {
      final token = await tokenProvider!();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<http.Response> get(String path, {bool auth = false}) async {
    return http.get(Uri.parse('$baseUrl$path'), headers: await _headers(auth: auth));
  }

  Future<http.Response> post(String path, {Object? body, bool auth = false}) async {
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<http.Response> put(String path, {Object? body, bool auth = false}) async {
    return http.put(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<http.Response> delete(String path, {bool auth = false}) async {
    return http.delete(Uri.parse('$baseUrl$path'), headers: await _headers(auth: auth));
  }

  Future<http.Response> multipartPost(String path, List<int> fileBytes, String fileName, String fieldName, {bool auth = false}) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri);
    final headers = await _headers(auth: auth, json: false);
    request.headers.addAll(headers);
    request.files.add(http.MultipartFile.fromBytes(fieldName, fileBytes, filename: fileName));
    final streamedResponse = await request.send();
    return http.Response.fromStream(streamedResponse);
  }

  /// Decode JSON body, throwing [ApiException] on non-2xx status.
  static Map<String, dynamic> decodeMap(http.Response res) {
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        (data['message'] ?? 'Request failed').toString(),
        status: res.statusCode,
      );
    }
    return data;
  }

  static List<dynamic> decodeList(http.Response res) {
    if (res.statusCode != 200) throw ApiException('Request failed', status: res.statusCode);
    return jsonDecode(res.body) as List;
  }
}
