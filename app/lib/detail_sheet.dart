import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'api.dart';
import 'strings.dart';
import 'theme.dart';
import 'widgets.dart';

/// Bottom sheet for one market: price in all three units, trend chart, day list.
class DetailSheet extends StatefulWidget {
  const DetailSheet({super.key, required this.item, required this.api, required this.s, required this.unit});
  final RateItem item;
  final RatesApi api;
  final S s;
  final Unit unit;

  @override
  State<DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<DetailSheet> {
  static const ranges = [20, 30, 90, 180, 365];
  int range = 20;
  List<DayRate>? rows;
  bool failed = false;

  @override
  void initState() {
    super.initState();
    widget.api.series(widget.item.id).then((r) {
      if (mounted) setState(() => rows = r);
    }).catchError((_) {
      if (mounted) setState(() => failed = true);
    });
  }

  List<DayRate> get windowed {
    final r = rows ?? const <DayRate>[];
    if (r.isEmpty) return r;
    final newest = r.last.day;
    return r.where((d) => newest.difference(d.day).inDays < range).toList();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = widget.s;
    final i = widget.item;
    final u = widget.unit;
    final pts = windowed;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${s.group(i.product)}, ${s.ta ? i.marketTa : i.marketEn}',
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, height: 1.3)),
                    Text('${s.asOn(i.day)}, ${s.source(i.source)}', style: TextStyle(fontSize: 14, color: p.ink3)),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                tooltip: s.ta ? 'மூடு' : 'Close',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            children: [
              Text(money(i.perKg, u), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, height: 1.1)),
              Text(s.per(u)),
              ChangePill(change: i.changePerKg, unit: u, s: s),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            Unit.values.where((x) => x != u).map((x) => '${money(i.perKg, x)} / ${s.unit(x)}').join('     '),
            style: TextStyle(fontSize: 14, color: p.ink2),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final r in ranges)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: OutlinedButton(
                      onPressed: () => setState(() => range = r),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: r == range ? p.husk : p.ink2,
                        side: BorderSide(color: r == range ? p.husk : p.line, width: 1.5),
                        shape: const StadiumBorder(),
                        minimumSize: const Size(48, 38),
                      ),
                      child: Text(s.range(r), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 220,
            child: failed
                ? Center(child: Text(s.loadFailed, textAlign: TextAlign.center))
                : rows == null
                    ? const Center(child: CircularProgressIndicator())
                    : pts.length < 2
                        ? const SizedBox.shrink()
                        : _Chart(pts: pts, unit: u, s: s),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: p.line),
          for (var k = pts.length - 1, n = 0; k >= 0 && n < 30; k--, n++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
              child: Row(
                children: [
                  Expanded(child: Text(s.date(pts[k].day), style: const TextStyle(fontSize: 15.5))),
                  Text(money(pts[k].perKg, u), style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  ChangePill(change: k > 0 ? pts[k].perKg - pts[k - 1].perKg : null, unit: u, s: s),
                ],
              ),
            ),
            Divider(height: 1, color: p.line),
          ],
        ],
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.pts, required this.unit, required this.s});
  final List<DayRate> pts;
  final Unit unit;
  final S s;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final spots = [for (var k = 0; k < pts.length; k++) FlSpot(k.toDouble(), pts[k].perKg * unit.factor)];
    final step = (pts.length / 5).ceil().clamp(1, 1000);
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: p.grid, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 64,
              getTitlesWidget: (v, meta) => SideTitleWidget(
                meta: meta,
                child: Text(money(v / unit.factor, unit), style: TextStyle(fontSize: 11, color: p.ink3)),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: step.toDouble(),
              reservedSize: 26,
              getTitlesWidget: (v, meta) {
                final k = v.round();
                if (k < 0 || k >= pts.length || v != k.toDouble()) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(s.date(pts[k].day), style: TextStyle(fontSize: 11, color: p.ink3)),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => p.ink,
            getTooltipItems: (spots) => [
              for (final t in spots)
                LineTooltipItem(
                  '${s.date(pts[t.spotIndex].day)}\n${money(pts[t.spotIndex].perKg, unit)}',
                  TextStyle(color: p.surface, fontWeight: FontWeight.w700),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: p.husk,
            barWidth: 2.5,
            isCurved: true,
            curveSmoothness: 0.2,
            preventCurveOverShooting: true,
            dotData: FlDotData(show: pts.length <= 40),
          ),
        ],
      ),
      duration: Duration.zero,
    );
  }
}
