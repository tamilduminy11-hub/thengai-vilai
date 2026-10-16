import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

/// Latest rate for one product at one market (a row of the `latest_rates` view).
class RateItem {
  RateItem({
    required this.id,
    required this.source,
    required this.product,
    required this.productEn,
    required this.productTa,
    required this.market,
    required this.marketEn,
    required this.marketTa,
    required this.day,
    required this.perKg,
    required this.changePerKg,
  });

  final String id;
  final String source;
  final String product;
  final String productEn;
  final String productTa;
  final String market;
  final String marketEn;
  final String marketTa;
  final DateTime day;
  final double perKg;
  final double? changePerKg;

  factory RateItem.fromJson(Map<String, dynamic> j) => RateItem(
        id: j['id'] as String,
        source: j['source'] as String,
        product: j['product'] as String,
        productEn: j['product_en'] as String,
        productTa: j['product_ta'] as String,
        market: j['market'] as String,
        marketEn: j['market_en'] as String,
        marketTa: j['market_ta'] as String,
        day: DateTime.parse(j['day'] as String),
        perKg: (j['per_kg'] as num).toDouble(),
        changePerKg: (j['change_per_kg'] as num?)?.toDouble(),
      );
}

class DayRate {
  DayRate(this.day, this.perKg);
  final DateTime day;
  final double perKg;
}

class RatesApi {
  RatesApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Map<String, String> get _headers => {
        'apikey': supabaseAnonKey,
        'Authorization': 'Bearer $supabaseAnonKey',
      };

  Future<dynamic> _get(String pathAndQuery) async {
    final res = await _client
        .get(Uri.parse('$supabaseUrl/rest/v1/$pathAndQuery'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  Future<List<RateItem>> latest() async {
    final rows = await _get(
        'latest_rates?select=id,source,product,product_en,product_ta,market,market_en,market_ta,day,per_kg,change_per_kg')
        as List;
    return rows.map((r) => RateItem.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Daily history for one series, oldest first.
  Future<List<DayRate>> series(String id, {int days = 400}) async {
    final since = DateTime.now().subtract(Duration(days: days)).toIso8601String().substring(0, 10);
    final rows = await _get(
        'rates?select=day,per_kg&series_id=eq.${Uri.encodeQueryComponent(id)}&day=gte.$since&order=day.asc&limit=1000')
        as List;
    return rows
        .map((r) => DayRate(DateTime.parse(r['day'] as String), (r['per_kg'] as num).toDouble()))
        .toList();
  }

  Future<DateTime?> lastChecked() async {
    final rows = await _get('meta?select=value&key=eq.last_checked') as List;
    if (rows.isEmpty) return null;
    return DateTime.tryParse(rows.first['value'] as String);
  }
}
