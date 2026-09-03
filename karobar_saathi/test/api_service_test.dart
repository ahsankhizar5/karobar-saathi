import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:karobar_saathi/services/api_service.dart';

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
}
