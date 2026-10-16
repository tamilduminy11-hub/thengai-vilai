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
    this.calc,
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

  /// Set for prices we calculate rather than read from a source (see [CalcInfo]).
  final CalcInfo? calc;

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

/// How a calculated price was made, so the app can explain it in plain words.
class CalcInfo {
  CalcInfo({
    required this.inputId,
    required this.inputPerKg,
    required this.ratio,
    required this.errMedianPct,
    required this.errP90Pct,
    required this.n,
  });
  final String inputId; // e.g. cdb.charcoal.kangayam
  final double inputPerKg;
  final double ratio;
  final double errMedianPct;
  final double errP90Pct;
  final int n;

  /// Typical-error band: 9 out of 10 past days fell inside it.
  double lo(double v) => v * (1 - errP90Pct / 100);
  double hi(double v) => v * (1 + errP90Pct / 100);
}

/// Turns the fetcher's published models into RateItems the UI can list like any other price.
List<RateItem> calculatedItems(Map<String, dynamic> models) {
  final out = <RateItem>[];
  models.forEach((id, raw) {
    final m = raw as Map<String, dynamic>;
    if (m['kind'] != 'shell_from_charcoal') return;
    final input = (m['input_per_kg'] as num).toDouble();
    final ratio = (m['ratio'] as num).toDouble();
    out.add(RateItem(
      id: 'calc.$id',
      source: 'calc',
      product: 'shell_calc',
      productEn: 'Shell (calculated)',
      productTa: 'தொட்டி (கணக்கிட்டது)',
      market: m['market'] as String,
      marketEn: m['market_en'] as String,
      marketTa: m['market_ta'] as String,
      day: DateTime.parse(m['input_day'] as String),
      perKg: double.parse((input * ratio).toStringAsFixed(2)),
      changePerKg: null,
      calc: CalcInfo(
        inputId: m['input'] as String,
        inputPerKg: input,
        ratio: ratio,
        errMedianPct: (m['err_median_pct'] as num).toDouble(),
        errP90Pct: (m['err_p90_pct'] as num).toDouble(),
        n: (m['n'] as num).toInt(),
      ),
    ));
  });
  return out;
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

  Future<Map<String, dynamic>> models() async {
    final rows = await _get('meta?select=value&key=eq.models') as List;
    if (rows.isEmpty) return const {};
    return (rows.first['value'] as Map).cast<String, dynamic>();
  }

  Future<DateTime?> lastChecked() async {
    final rows = await _get('meta?select=value&key=eq.last_checked') as List;
    if (rows.isEmpty) return null;
    return DateTime.tryParse(rows.first['value'] as String);
  }
}
