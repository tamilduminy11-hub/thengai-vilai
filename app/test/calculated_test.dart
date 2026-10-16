import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thengai_vilai/api.dart';
import 'package:thengai_vilai/calculator.dart';
import 'package:thengai_vilai/strings.dart';
import 'package:thengai_vilai/theme.dart';

final models = {
  'shell_kangayam': {
    'kind': 'shell_from_charcoal', 'market': 'kangayam', 'market_en': 'Kangayam', 'market_ta': 'காங்கேயம்',
    'input': 'cdb.charcoal.kangayam', 'input_day': '2026-10-15', 'input_per_kg': 95.0,
    'ratio': 0.3563, 'ratio_p10': 0.3523, 'ratio_p90': 0.3652, 'n': 320,
    'err_median_pct': 1.0, 'err_p90_pct': 3.3,
  },
};

RateItem rate(String id, double perKg, DateTime day) {
  final p = id.split('.');
  return RateItem(id: id, source: 'cdb', product: p[1], productEn: p[1], productTa: p[1], market: p[2],
      marketEn: p[2], marketTa: p[2], day: day, perKg: perKg, changePerKg: 0);
}

void main() {
  test('shell from charcoal: ₹95,000/t x 0.3563 = ₹33.85/kg, ±3.3% band', () {
    final items = calculatedItems(models);
    expect(items, hasLength(1));
    final i = items.single;
    expect(i.id, 'calc.shell_kangayam');
    expect(i.perKg, 33.85);
    expect(i.calc!.lo(i.perKg), closeTo(32.73, 0.01));
    expect(i.calc!.hi(i.perKg), closeTo(34.97, 0.01));
  });

  testWidgets('calculator uses calculated shell when the published one is old', (t) async {
    final fresh = [
      rate('cdb.coconut_black.pollachi_mkt', 54, DateTime.now()),
      rate('cdb.coconut_green.pollachi_mkt', 50, DateTime.now()),
      rate('cdb.milling_copra.kangayam', 158, DateTime.now()),
    ];
    final all = [...fresh, rate('cdb.shell.kangayam_mkt', 37.7, DateTime(2026, 8, 31)), ...calculatedItems(models)];
    t.view.physicalSize = const Size(390, 844) * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Scaffold(body: CalculatorSheet(fresh: fresh, all: all, s: const S(Lang.en))),
    ));
    // 33.85/kg = ₹33,850/t, shown rounded to ₹33,900; 75 kg shell x ₹33,900/t = ₹2,542.5 -> ₹2,543
    await t.scrollUntilVisible(find.text('₹33,900'), 250, scrollable: find.byType(Scrollable).first);
    expect(find.text('₹2,543'), findsOneWidget);
    expect(find.text('₹37,700'), findsNothing); // never the August figure
  });
}
