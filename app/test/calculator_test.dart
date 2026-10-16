import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thengai_vilai/api.dart';
import 'package:thengai_vilai/calculator.dart';
import 'package:thengai_vilai/strings.dart';
import 'package:thengai_vilai/theme.dart';

RateItem rate(String id, double perKg, {DateTime? day}) {
  final parts = id.split('.');
  return RateItem(
    id: id, source: 'cdb', product: parts[1], productEn: parts[1], productTa: parts[1],
    market: parts[2], marketEn: parts[2], marketTa: parts[2],
    day: day ?? DateTime(2026, 10, 15), perKg: perKg, changePerKg: 0,
  );
}

final fresh = [
  rate('cdb.coconut_black.pollachi_mkt', 54),
  rate('cdb.coconut_green.pollachi_mkt', 50),
  rate('cdb.milling_copra.kangayam', 158),
];
final all = [
  ...fresh,
  rate('cdb.husk_black.pollachi', 2.8, day: DateTime(2026, 8, 31)),
  rate('cdb.husk_green.pollachi', 5.5, day: DateTime(2026, 8, 31)),
  rate('cdb.shell.kangayam_mkt', 37.7, day: DateTime(2026, 8, 31)),
];

Future<void> pumpAt(WidgetTester t, Size size, Brightness b, Lang lang) async {
  t.view.physicalSize = size * 3;
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    theme: buildTheme(b),
    home: Scaffold(body: CalculatorSheet(fresh: fresh, all: all, s: S(lang))),
  ));
  await t.pump();
}

Future<void> scrollTo(WidgetTester t, Finder f) =>
    t.scrollUntilVisible(f, 250, scrollable: find.byType(Scrollable).first);

void main() {
  testWidgets('default: 1000 nuts x 500 g, black-to-green range', (t) async {
    await pumpAt(t, const Size(390, 844), Brightness.light, Lang.en);
    expect(find.text('1,000'), findsWidgets);
    await scrollTo(t, find.text('₹25,000 – ₹27,000'));
    expect(find.text('₹25 – ₹27'), findsWidgets);       // per nut (answer + 500 g ladder row)
    expect(find.text('₹25,000 – ₹27,000'), findsOneWidget);
    await scrollTo(t, find.text('+ ₹2,800'));            // 1000 black husks at ₹2,800 / 1000
    await scrollTo(t, find.text('₹23,700'));             // 150 kg copra x ₹158
    expect(find.text('₹2,828'), findsOneWidget);         // 75 kg shell x ₹37,700 / tonne
    expect(find.text('₹26,528'), findsOneWidget);        // copra + shell
  });

  testWidgets('size ladder: tapping 300 g reprices', (t) async {
    await pumpAt(t, const Size(390, 844), Brightness.light, Lang.en);
    await scrollTo(t, find.text('300 g'));
    await t.tap(find.text('300 g'));
    await t.pump();
    await scrollTo(t, find.text('₹15,000 – ₹16,200'));
    expect(find.text('₹15,000 – ₹16,200'), findsOneWidget);
  });

  testWidgets('count + button and presets', (t) async {
    await pumpAt(t, const Size(390, 844), Brightness.light, Lang.en);
    await t.tap(find.byIcon(Icons.add).first);
    await t.pump();
    expect(find.text('1,100'), findsOneWidget);
    await t.tap(find.text('5,000'));
    await t.pump();
    expect(find.text('5,000'), findsWidgets);
  });

  testWidgets('black only uses black coconut and black husk', (t) async {
    await pumpAt(t, const Size(390, 844), Brightness.light, Lang.en);
    await scrollTo(t, find.text('Black'));
    await t.tap(find.text('Black'));
    await t.pump();
    await scrollTo(t, find.text('₹27,000'));
    expect(find.text('₹27,000'), findsOneWidget);
  });

  for (final size in const [Size(375, 667), Size(390, 844)]) {
    for (final b in Brightness.values) {
      testWidgets('no overflow top to bottom at $size $b (Tamil)', (t) async {
        await pumpAt(t, size, b, Lang.ta);
        await t.drag(find.byType(Scrollable).first, const Offset(0, -3000));
        await t.pump();
        expect(t.takeException(), isNull);
      });
    }
  }
}
