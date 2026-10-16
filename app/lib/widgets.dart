import 'package:flutter/material.dart';

import 'api.dart';
import 'strings.dart';
import 'theme.dart';

/// Indian-grouped rupee amount, e.g. ₹1,58,000 or ₹216.67.
String money(double perKg, Unit unit) {
  final v = perKg * unit.factor;
  final whole = (v - v.truncate()).abs() < 0.005;
  final fixed = whole ? v.round().toString() : v.toStringAsFixed(2);
  final parts = fixed.split('.');
  var intPart = parts[0];
  if (intPart.length > 3) {
    final last3 = intPart.substring(intPart.length - 3);
    var rest = intPart.substring(0, intPart.length - 3);
    final groups = <String>[];
    while (rest.length > 2) {
      groups.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) groups.insert(0, rest);
    intPart = '${groups.join(',')},$last3';
  }
  return '₹$intPart${parts.length > 1 ? '.${parts[1]}' : ''}';
}

/// Centres content at phone-friendly width on tablets and desktop browsers.
class Column660 extends StatelessWidget {
  const Column660({super.key, required this.child, this.padding = EdgeInsets.zero});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(padding: padding, child: child),
        ),
      );
}

class ChangePill extends StatelessWidget {
  const ChangePill({super.key, required this.change, required this.unit, required this.s, this.onDark = false});
  final double? change;
  final Unit unit;
  final S s;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final c = change;
    if (c == null) return const SizedBox.shrink();
    final p = context.pal;
    final flat = c.abs() < 0.005;
    final up = c > 0;
    final fg = flat ? p.ink3 : (up ? p.up : p.down);
    final bg = flat ? p.flatBg : (up ? p.upBg : p.downBg);
    final style = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: fg);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: flat
          ? Text(s.noChange, style: style)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Catamaran has no ▲/▼ glyphs, so draw the arrow as an icon.
                Icon(up ? Icons.arrow_upward : Icons.arrow_downward, size: 13, color: fg),
                const SizedBox(width: 2),
                Text(money(c.abs(), unit), style: style),
              ],
            ),
    );
  }
}

class Header extends StatelessWidget {
  const Header({super.key, required this.s, required this.unit, this.hero, this.heroSeries, required this.onLang});
  final S s;
  final Unit unit;
  final RateItem? hero;
  final List<DayRate>? heroSeries;
  final VoidCallback onLang;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final h = hero;
    return Container(
      color: p.leaf,
      child: SafeArea(
        bottom: false,
        child: Column660(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: p.leafInk),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(s.brand,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: p.leafInk)),
                    ),
                    OutlinedButton(
                      onPressed: onLang,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: p.leafInk,
                        side: BorderSide(color: p.leafInk.withValues(alpha: 0.55), width: 1.5),
                        shape: const StadiumBorder(),
                        minimumSize: const Size(48, 40),
                      ),
                      child: Text(s.switchTo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ],
                ),
                if (h != null) ...[
                  const SizedBox(height: 14),
                  Text(s.heroLabel, style: TextStyle(fontSize: 16, color: p.leafInk.withValues(alpha: 0.9))),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      Text(money(h.perKg, unit),
                          style: TextStyle(
                              fontSize: 60, fontWeight: FontWeight.w800, height: 1.05, color: p.leafInk)),
                      Text(s.per(unit), style: TextStyle(fontSize: 18, color: p.leafInk.withValues(alpha: 0.85))),
                      ChangePill(change: h.changePerKg, unit: unit, s: s),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('${s.asOn(h.day)}, ${s.source(h.source)}',
                      style: TextStyle(fontSize: 15, color: p.leafInk.withValues(alpha: 0.85))),
                  if ((heroSeries?.length ?? 0) > 1) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 44,
                      width: double.infinity,
                      child: CustomPaint(painter: _Spark(heroSeries!.reversed.take(20).toList().reversed.toList(),
                          p.leafInk.withValues(alpha: 0.8))),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Spark extends CustomPainter {
  _Spark(this.pts, this.color);
  final List<DayRate> pts;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final vals = pts.map((e) => e.perKg).toList();
    final lo = vals.reduce((a, b) => a < b ? a : b);
    final hi = vals.reduce((a, b) => a > b ? a : b);
    final span = (hi - lo) == 0 ? 1 : hi - lo;
    Offset at(int i) => Offset(
          2 + i / (pts.length - 1) * (size.width - 6),
          size.height - 4 - (vals[i] - lo) / span * (size.height - 8),
        );
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(at(pts.length - 1), 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _Spark old) => old.pts != pts || old.color != color;
}

class UnitSwitch extends StatelessWidget {
  const UnitSwitch({super.key, required this.s, required this.unit, required this.onChanged});
  final S s;
  final Unit unit;
  final ValueChanged<Unit> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final u in Unit.values)
            Expanded(
              child: Semantics(
                selected: u == unit,
                button: true,
                label: '₹ / ${s.unit(u)}',
                child: Material(
                  color: u == unit ? p.husk : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () => onChanged(u),
                    child: SizedBox(
                      height: 40,
                      child: Center(
                        child: Text(
                          s.unit(u),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: u == unit ? p.surface : p.ink2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AreaChips extends StatelessWidget {
  const AreaChips({super.key, required this.s, required this.areas, required this.active, required this.onChanged});
  final S s;
  final List<String> areas;
  final String active;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final a in areas)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: OutlinedButton(
                onPressed: () => onChanged(a),
                style: OutlinedButton.styleFrom(
                  backgroundColor: p.surface,
                  foregroundColor: a == active ? p.husk : p.ink2,
                  side: BorderSide(color: a == active ? p.husk : p.line, width: 1.5),
                  shape: const StadiumBorder(),
                  minimumSize: const Size(48, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: Text(s.area(a), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}

class RateGroup extends StatelessWidget {
  const RateGroup({
    super.key,
    required this.title,
    required this.items,
    required this.s,
    required this.unit,
    required this.onTap,
  });
  final String title;
  final List<RateItem> items;
  final S s;
  final Unit unit;
  final ValueChanged<RateItem> onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column660(
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: p.husk)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: p.surface,
              border: Border.all(color: p.line),
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var k = 0; k < items.length; k++) ...[
                  if (k > 0) Divider(height: 1, thickness: 1, color: p.line),
                  _RateRow(item: items[k], s: s, unit: unit, onTap: () => onTap(items[k])),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  const _RateRow({required this.item, required this.s, required this.unit, required this.onTap});
  final RateItem item;
  final S s;
  final Unit unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.ta ? item.marketTa : item.marketEn,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    Text(s.asOn(item.day), style: TextStyle(fontSize: 13.5, color: p.ink3)),
                    if (item.calc != null) CalcBadge(s: s),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(money(item.perKg, unit), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  if (item.calc != null)
                    Text('${money(item.calc!.lo(item.perKg), unit)} – ${money(item.calc!.hi(item.perKg), unit)}',
                        style: TextStyle(fontSize: 13, color: p.ink3))
                  else
                    ChangePill(change: item.changePerKg, unit: unit, s: s),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Marks a price we calculated (not read from a source) so nobody mistakes it for a quote.
class CalcBadge extends StatelessWidget {
  const CalcBadge({super.key, required this.s});
  final S s;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calculate_outlined, size: 14, color: p.husk),
          const SizedBox(width: 3),
          Text(s.calculated, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.husk)),
        ],
      ),
    );
  }
}

class StateMessage extends StatelessWidget {
  const StateMessage({super.key, required this.text, this.action, this.onAction});
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Column660(
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
        child: Column(
          children: [
            Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: context.pal.ink2)),
            if (action != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onAction, child: Text(action!)),
            ],
          ],
        ),
      );
}

class Footer extends StatelessWidget {
  const Footer({super.key, required this.s, this.checked});
  final S s;
  final DateTime? checked;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final c = checked?.toUtc().add(const Duration(hours: 5, minutes: 30));
    String two(int n) => n.toString().padLeft(2, '0');
    final time = c == null
        ? null
        : '${s.date(c)}, ${c.hour % 12 == 0 ? 12 : c.hour % 12}:${two(c.minute)} ${c.hour < 12 ? 'AM' : 'PM'}';
    return Column660(
      padding: const EdgeInsets.fromLTRB(16, 34, 16, 40),
      child: DefaultTextStyle.merge(
        style: TextStyle(fontSize: 14, color: p.ink3, height: 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.sourceNote),
            const SizedBox(height: 6),
            const Text('coconutboard.in · agmarknet.gov.in'),
            if (time != null) ...[const SizedBox(height: 6), Text('${s.lastChecked}: $time')],
          ],
        ),
      ),
    );
  }
}
