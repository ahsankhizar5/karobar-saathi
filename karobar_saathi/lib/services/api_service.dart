/// HTTP client for the Karobar Saathi FastAPI backend.
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/models.dart';

/// Base URL of the backend.
///
/// Defaults to the Android emulator's host loopback alias. Override at build
/// time with: `flutter build apk --dart-define=API_BASE_URL=https://host`.
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

/// Thrown for any non-2xx backend response or transport failure.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.detail});

  final String message;
  final int? statusCode;

  /// Decoded `detail` payload, when the backend supplied a structured one.
  final Map<String, dynamic>? detail;

  /// True when the evidence endpoint refused because consent is missing.
  bool get isConsentDenied => statusCode == 403;

  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}

class ApiService {
  ApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? kApiBaseUrl;

  final http.Client _client;
  final String baseUrl;

  static const Duration _timeout = Duration(seconds: 30);
  static const Map<String, String> _jsonHeaders = <String, String>{
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Uri _uri(String path, [Map<String, dynamic>? query]) => Uri.parse('$baseUrl$path')
      .replace(
    queryParameters: query?.map(
      (String key, dynamic value) => MapEntry<String, String>(key, '$value'),
    ),
  );

  void dispose() => _client.close();

  // ---------------------------------------------------------------- dashboard

  /// `GET /api/v1/dashboard/{user_id}`
  Future<Dashboard> fetchDashboard(String userId) async {
    final Map<String, dynamic> json =
        await _getJson('/api/v1/dashboard/$userId') as Map<String, dynamic>;
    return Dashboard.fromJson(json);
  }

  // ------------------------------------------------------------------- ledger

  /// `GET /api/v1/ledger/?user_id=...`
  Future<List<LedgerEntry>> fetchLedger(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final List<dynamic> json = await _getJson(
      '/api/v1/ledger/',
      query: <String, dynamic>{
        'user_id': userId,
        'limit': limit,
        'offset': offset,
      },
    ) as List<dynamic>;
    return json
        .map((dynamic e) => LedgerEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /api/v1/ledger/today?user_id=...`
  Future<List<LedgerEntry>> fetchTodayLedger(String userId) async {
    final List<dynamic> json = await _getJson(
      '/api/v1/ledger/today',
      query: <String, dynamic>{'user_id': userId},
    ) as List<dynamic>;
    return json
        .map((dynamic e) => LedgerEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /api/v1/ledger/batch-confirm` — creates and confirms entries in one
  /// call. Used after the user reviews the AI-parsed drafts.
  Future<List<LedgerEntry>> batchConfirm({
    required String userId,
    required List<ParsedEntry> entries,
    required String rawTranscript,
  }) async {
    final List<dynamic> json = await _sendJson(
      'POST',
      '/api/v1/ledger/batch-confirm',
      body: entries
          .map((ParsedEntry e) =>
              e.toCreateJson(userId: userId, rawTranscript: rawTranscript))
          .toList(),
    ) as List<dynamic>;
    return json
        .map((dynamic e) => LedgerEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `DELETE /api/v1/ledger/{entry_id}`
  Future<void> deleteEntry(int entryId) async {
    await _sendJson('DELETE', '/api/v1/ledger/$entryId');
  }

  // -------------------------------------------------------------------- voice

  /// `POST /api/v1/voice/parse-text` — manual typed entry.
  Future<TranscriptResult> parseText({
    required String userId,
    required String text,
  }) async {
    final Map<String, dynamic> json = await _sendJson(
      'POST',
      '/api/v1/voice/parse-text',
      body: <String, dynamic>{'user_id': userId, 'text': text},
    ) as Map<String, dynamic>;
    return TranscriptResult.fromJson(json);
  }

  /// `POST /api/v1/voice/transcribe` — multipart audio upload.
  ///
  /// [fallbackText] is forwarded so the backend can degrade gracefully when
  /// speech-to-text is unavailable.
  Future<TranscriptResult> transcribeAudio({
    required String userId,
    required String audioFilePath,
    String? fallbackText,
  }) async {
    final http.MultipartRequest request =
        http.MultipartRequest('POST', _uri('/api/v1/voice/transcribe'))
          ..fields['user_id'] = userId;

    if (fallbackText != null && fallbackText.trim().isNotEmpty) {
      request.fields['fallback_text'] = fallbackText.trim();
    }

    final File file = File(audioFilePath);
    if (!await file.exists()) {
      throw ApiException('Recording file was not found on device.');
    }
    request.files.add(await http.MultipartFile.fromPath('audio', audioFilePath));

    try {
      final http.StreamedResponse streamed =
          await _client.send(request).timeout(_timeout);
      final http.Response response = await http.Response.fromStream(streamed);
      final Map<String, dynamic> json =
          _decode(response) as Map<String, dynamic>;
      return TranscriptResult.fromJson(json);
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException('Could not upload the recording: $error');
    }
  }

  // ---------------------------------------------------------------- evidence

  /// `GET /api/v1/evidence-profile/{user_id}` with `X-User-Consent: true`.
  ///
  /// Throws an [ApiException] with `statusCode == 403` when the user has
  /// revoked consent — that refusal is a first-class demo state.
  Future<EvidenceProfile> fetchEvidenceProfile(String userId) async {
    final Map<String, dynamic> json = await _getJson(
      '/api/v1/evidence-profile/$userId',
      headers: <String, String>{'X-User-Consent': 'true'},
    ) as Map<String, dynamic>;
    return EvidenceProfile.fromJson(json);
  }

  /// `PATCH /api/v1/evidence-profile/{user_id}/consent`
  Future<bool> updateConsent({
    required String userId,
    required bool consented,
  }) async {
    final Map<String, dynamic> json = await _sendJson(
      'PATCH',
      '/api/v1/evidence-profile/$userId/consent',
      body: <String, dynamic>{'has_user_consented_to_share': consented},
    ) as Map<String, dynamic>;
    return json['has_user_consented_to_share'] == true;
  }

  // -------------------------------------------------------------------- users

  /// `GET /api/v1/users/{user_id}`
  Future<AppUser> fetchUser(String userId) async {
    final Map<String, dynamic> json =
        await _getJson('/api/v1/users/$userId') as Map<String, dynamic>;
    return AppUser.fromJson(json);
  }

  /// `GET /api/v1/users/`
  Future<List<AppUser>> fetchUsers() async {
    final List<dynamic> json =
        await _getJson('/api/v1/users/') as List<dynamic>;
    return json
        .map((dynamic e) => AppUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ------------------------------------------------------------------ plumbing

  Future<Object?> _getJson(
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) async {
    try {
      final http.Response response = await _client
          .get(_uri(path, query), headers: <String, String>{
        ..._jsonHeaders,
        ...?headers,
      }).timeout(_timeout);
      return _decode(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException(_offlineMessage);
    } catch (error) {
      throw ApiException('Network error: $error');
    }
  }

  Future<Object?> _sendJson(
    String method,
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    try {
      final http.Request request = http.Request(method, _uri(path))
        ..headers.addAll(<String, String>{..._jsonHeaders, ...?headers});
      if (body != null) {
        request.body = jsonEncode(body);
      }
      final http.StreamedResponse streamed =
          await _client.send(request).timeout(_timeout);
      return _decode(await http.Response.fromStream(streamed));
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException(_offlineMessage);
    } catch (error) {
      throw ApiException('Network error: $error');
    }
  }

  static const String _offlineMessage =
      'Cannot reach the Karobar Saathi server. Check that the backend is '
      'running and that API_BASE_URL points at it.';

  /// Decodes a response, converting non-2xx statuses into [ApiException].
  ///
  /// FastAPI's `detail` may be a plain string or (for the consent gate) a
  /// nested object; both shapes are preserved.
  Object? _decode(http.Response response) {
    final int status = response.statusCode;
    final String body = utf8.decode(response.bodyBytes, allowMalformed: true);

    Object? decoded;
    if (body.isNotEmpty) {
      try {
        decoded = jsonDecode(body);
      } catch (_) {
        decoded = null;
      }
    }

    if (status >= 200 && status < 300) {
      return decoded;
    }

    Map<String, dynamic>? detail;
    String message = 'Request failed (HTTP $status).';

    if (decoded is Map<String, dynamic>) {
      final Object? rawDetail = decoded['detail'];
      if (rawDetail is Map<String, dynamic>) {
        detail = rawDetail;
        final Object? detailMessage = rawDetail['message'];
        if (detailMessage is String && detailMessage.isNotEmpty) {
          message = detailMessage;
        }
      } else if (rawDetail is String && rawDetail.isNotEmpty) {
        message = rawDetail;
      } else if (rawDetail is List && rawDetail.isNotEmpty) {
        // FastAPI validation errors.
        message = rawDetail
            .map((dynamic e) =>
                e is Map && e['msg'] != null ? '${e['msg']}' : '$e')
            .join('\n');
      }
    }

    throw ApiException(message, statusCode: status, detail: detail);
  }
}
