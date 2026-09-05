import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:karobar_saathi/models/models.dart';
import 'package:karobar_saathi/services/api_service.dart';

Map<String, dynamic> _transcriptBody() => <String, dynamic>{
      'parsed_entries': <Map<String, dynamic>>[
        <String, dynamic>{
          'entry_type': 'sale',
          'amount': 4500.0,
          'note': 'Tea sales',
          'category': 'tea',
        },
      ],
      'raw_transcript': 'aaj 4500 ki sale hui',
    };

void main() {
  test('fetchDashboard requests and decodes the dashboard response', () async {
    final http.Client client = MockClient((http.Request request) async {
      expect(request.method, 'GET');
      expect(
        request.url,
        Uri.parse('https://api.example.test/api/v1/dashboard/shop_001'),
      );

      return http.Response(
        jsonEncode(<String, dynamic>{
          'today_profit': 900.0,
          'today_sales': 1500.0,
          'today_expenses': 600.0,
          'weekly_trend': <Map<String, dynamic>>[
            <String, dynamic>{
              'day': 'Fri',
              'date': '2026-09-04',
              'sales': 1500.0,
              'expenses': 600.0,
              'profit': 900.0,
            },
          ],
          'cash_position': 900.0,
          'killer_insight': 'Keep recording daily transactions.',
          'total_entries_today': 3,
          'top_category': 'tea',
          'top_category_margin': 73.33,
        }),
        200,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });
    final ApiService service = ApiService(
      client: client,
      baseUrl: 'https://api.example.test',
    );
    addTearDown(service.dispose);

    final dashboard = await service.fetchDashboard('shop_001');

    expect(dashboard.todaySales, 1500.0);
    expect(dashboard.todayExpenses, 600.0);
    expect(dashboard.todayProfit, 900.0);
    expect(dashboard.cashPosition, 900.0);
    expect(dashboard.totalEntriesToday, 3);
    expect(dashboard.weeklyTrend, hasLength(1));
    expect(dashboard.topCategory, 'tea');
  });

  test('parseText posts to parse-text and decodes the result', () async {
    final http.Client client = MockClient((http.Request request) async {
      expect(request.method, 'POST');
      expect(
        request.url,
        Uri.parse('https://api.example.test/api/v1/voice/parse-text'),
      );
      expect(
        jsonDecode(request.body) as Map<String, dynamic>,
        <String, dynamic>{
          'user_id': 'shop_001',
          'text': 'aaj 4500 ki sale hui',
        },
      );
      return http.Response(
        jsonEncode(_transcriptBody()),
        200,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });
    final ApiService service = ApiService(
      client: client,
      baseUrl: 'https://api.example.test',
    );
    addTearDown(service.dispose);

    final TranscriptResult result = await service.parseText(
      userId: 'shop_001',
      text: 'aaj 4500 ki sale hui',
    );

    expect(result.rawTranscript, 'aaj 4500 ki sale hui');
    expect(result.parsedEntries, hasLength(1));
    expect(result.parsedEntries.single.amount, 4500.0);
  });

  test('parseText flags a timed-out request as isTimeout', () async {
    final Completer<http.Response> never = Completer<http.Response>();
    final http.Client client = MockClient(
      (http.Request request) => never.future,
    );
    final ApiService service = ApiService(
      client: client,
      baseUrl: 'https://api.example.test',
      llmTimeout: const Duration(milliseconds: 20),
    );
    addTearDown(service.dispose);

    await expectLater(
      service.parseText(userId: 'shop_001', text: 'aaj 4500 ki sale hui'),
      throwsA(
        isA<ApiException>().having(
          (ApiException error) => error.isTimeout,
          'isTimeout',
          isTrue,
        ),
      ),
    );
  });

  test('transcribeAudio uploads multipart audio with user id and fallback',
      () async {
    final Directory tmp =
        await Directory.systemTemp.createTemp('karobar_test');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final File audio = File('${tmp.path}${Platform.pathSeparator}clip.m4a')
      ..writeAsBytesSync(<int>[1, 2, 3, 4]);

    final http.Client client = MockClient.streaming(
      (http.BaseRequest request, http.ByteStream body) async {
        expect(request, isA<http.MultipartRequest>());
        final http.MultipartRequest multipart =
            request as http.MultipartRequest;
        expect(multipart.url.path, '/api/v1/voice/transcribe');
        expect(multipart.fields['user_id'], 'shop_001');
        expect(multipart.fields['fallback_text'], 'aaj 4500 ki sale hui');
        expect(multipart.files, hasLength(1));
        expect(multipart.files.single.field, 'audio');
        return http.StreamedResponse(
          Stream<List<int>>.value(utf8.encode(jsonEncode(_transcriptBody()))),
          200,
          contentLength: null,
        );
      },
    );
    final ApiService service = ApiService(
      client: client,
      baseUrl: 'https://api.example.test',
    );
    addTearDown(service.dispose);

    final TranscriptResult result = await service.transcribeAudio(
      userId: 'shop_001',
      audioFilePath: audio.path,
      fallbackText: 'aaj 4500 ki sale hui',
    );

    expect(result.parsedEntries.single.amount, 4500.0);
  });

  test('transcribeAudio flags a timed-out upload as isTimeout', () async {
    final Directory tmp =
        await Directory.systemTemp.createTemp('karobar_test');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final File audio = File('${tmp.path}${Platform.pathSeparator}clip.m4a')
      ..writeAsBytesSync(<int>[1, 2, 3, 4]);

    final http.Client client = MockClient.streaming(
      (http.BaseRequest request, http.ByteStream body) =>
          Completer<http.StreamedResponse>().future,
    );
    final ApiService service = ApiService(
      client: client,
      baseUrl: 'https://api.example.test',
      llmTimeout: const Duration(milliseconds: 20),
    );
    addTearDown(service.dispose);

    await expectLater(
      service.transcribeAudio(
        userId: 'shop_001',
        audioFilePath: audio.path,
      ),
      throwsA(
        isA<ApiException>().having(
          (ApiException error) => error.isTimeout,
          'isTimeout',
          isTrue,
        ),
      ),
    );
  });

  test('warmUp swallows transport errors and slow responses', () async {
    final http.Client client = MockClient((http.Request request) {
      throw const SocketException('unreachable');
    });
    final ApiService service = ApiService(
      client: client,
      baseUrl: 'https://api.example.test',
    );
    addTearDown(service.dispose);

    // Completing without throwing is the contract — warm-up is best-effort.
    await service.warmUp(timeout: const Duration(milliseconds: 20));
  });
}
