import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thengai_vilai/api.dart';
import 'package:thengai_vilai/calculator.dart';
import 'package:thengai_vilai/strings.dart';
import 'package:thengai_vilai/theme.dart';

RateItem rate(String id, String product, String market, double perKg) => RateItem(
      id: id, source: 'cdb', product: product, productEn: product, productTa: product,
      market: market, marketEn: market, marketTa: market,
      day: DateTime(2026, 10, 15), perKg: perKg, changePerKg: 0,
    );

final items = [
  rate('cdb.coconut_black.pollachi_mkt', 'coconut_black', 'Pollachi', 54),
  rate('cdb.coconut_green.pollachi_mkt', 'coconut_green', 'Pollachi', 50),
  rate('cdb.milling_copra.kangayam', 'milling_copra', 'Kangayam', 158),
];

Future<void> pumpAt(WidgetTester t, Size size, Brightness b, Lang lang) async {
  t.view.physicalSize = size * 3;
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    theme: buildTheme(b),
    home: Scaffold(body: CalculatorSheet(items: items, s: S(lang))),
  ));
  await t.pump();
}

void main() {
  testWidgets('1000 nuts x 500 g priced from black/green range', (t) async {
    await pumpAt(t, const Size(390, 844), Brightness.light, Lang.en);
    expect(find.text('₹25 – ₹27'), findsOneWidget);          // per coconut: 0.5 kg x ₹50..₹54
    expect(find.text('₹25,000 – ₹27,000'), findsOneWidget);  // total
    expect(find.text('₹50,000 – ₹54,000'), findsOneWidget);  // per tonne
    await t.scrollUntilVisible(find.text('₹47.40'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('₹47.40'), findsOneWidget);             // copra only: 30% x ₹158
  });

  testWidgets('black only narrows to the black rate', (t) async {
    await pumpAt(t, const Size(390, 844), Brightness.light, Lang.en);
    await t.tap(find.text('Black'));
    await t.pump();
    expect(find.text('₹27'), findsOneWidget);
  });

  testWidgets('invalid weight shows an error and no price', (t) async {
    await pumpAt(t, const Size(390, 844), Brightness.light, Lang.en);
    await t.enterText(find.byType(TextField).last, '20');
    await t.pump();
    expect(find.text('Enter between 50 and 3000 grams'), findsOneWidget);
    expect(find.text('₹25 – ₹27'), findsNothing);
  });

  for (final size in const [Size(375, 667), Size(390, 844)]) {
    for (final b in Brightness.values) {
      testWidgets('renders without overflow at $size $b (Tamil)', (t) async {
        await pumpAt(t, size, b, Lang.ta);
        expect(t.takeException(), isNull);
      });
    }
  }
}
