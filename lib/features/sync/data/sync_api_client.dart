import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:alpha/features/sync/data/change_tracker.dart';

/// HTTP client for the sync Lambda endpoints.
class SyncApiClient {
  static const _apiUrl =
      'https://fwd1m22p21.execute-api.us-west-2.amazonaws.com';

  final http.Client _http;

  SyncApiClient({http.Client? client}) : _http = client ?? http.Client();

  /// Push local changes to the server.
  /// Returns (accepted, rejected) counts.
  Future<({int accepted, int rejected, String serverTime})> push({
    required String accessToken,
    required String deviceId,
    required List<SyncChange> changes,
  }) async {
    final response = await _post(
      '/sync/push',
      accessToken: accessToken,
      body: {
        'device_id': deviceId,
        'changes': changes.map((c) => c.toJson()).toList(),
      },
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw SyncApiException(
        'Push failed: ${json['error'] ?? response.statusCode}',
      );
    }

    return (
      accepted: json['accepted'] as int? ?? 0,
      rejected: json['rejected'] as int? ?? 0,
      serverTime: json['server_time'] as String? ?? '',
    );
  }

  /// Pull remote changes since a given timestamp.
  Future<({List<Map<String, dynamic>> changes, String serverTime})> pull({
    required String accessToken,
    required String deviceId,
    String? since,
  }) async {
    final response = await _post(
      '/sync/pull',
      accessToken: accessToken,
      body: {
        'device_id': deviceId,
        'since': since,
      },
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw SyncApiException(
        'Pull failed: ${json['error'] ?? response.statusCode}',
      );
    }

    final rawChanges = json['changes'] as List<dynamic>? ?? [];
    return (
      changes: rawChanges.cast<Map<String, dynamic>>(),
      serverTime: json['server_time'] as String? ?? '',
    );
  }

  /// Get sync status for the authenticated user.
  Future<Map<String, dynamic>> status({
    required String accessToken,
  }) async {
    final response = await _get(
      '/sync/status',
      accessToken: accessToken,
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw SyncApiException(
        'Status failed: ${json['error'] ?? response.statusCode}',
      );
    }

    return json;
  }

  // ── HTTP helpers ────────────────────────────────────

  Future<http.Response> _post(
    String path, {
    required String accessToken,
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('$_apiUrl$path');


    return _http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  Future<http.Response> _get(
    String path, {
    required String accessToken,
  }) async {
    final uri = Uri.parse('$_apiUrl$path');


    return _http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
  }
}

class SyncApiException implements Exception {
  final String message;
  SyncApiException(this.message);

  @override
  String toString() => message;
}
