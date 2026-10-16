import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api.dart';
import 'strings.dart';
import 'theme.dart';
import 'widgets.dart';

/// Rule of thumb traders use: 100 kg dehusked coconut dries to about 30 kg copra.
const copraOutturn = 0.30;

enum NutType { black, green, unknown }

/// "What is my coconut worth today?" Farmer enters the count and the weight of one nut;
/// we price it with today's black/green market rates and cross-check with copra.
class CalculatorSheet extends StatefulWidget {
  const CalculatorSheet({super.key, required this.items, required this.s});
  final List<RateItem> items;
  final S s;

  @override
  State<CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<CalculatorSheet> {
  final countCtl = TextEditingController(text: '1000');
  final gramsCtl = TextEditingController(text: '500');
  NutType type = NutType.unknown;

  @override
  void dispose() {
    countCtl.dispose();
    gramsCtl.dispose();
    super.dispose();
  }

  List<RateItem> _rates(String product) => widget.items.where((i) => i.product == product).toList();

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = widget.s;
    final count = int.tryParse(countCtl.text.trim());
    final grams = double.tryParse(gramsCtl.text.trim());
    final countErr = countCtl.text.isNotEmpty && (count == null || count <= 0) ? s.calcCountError : null;
    final gramsErr = gramsCtl.text.isNotEmpty && (grams == null || grams < 50 || grams > 3000) ? s.calcGramsError : null;

    final black = _rates('coconut_black');
    final green = _rates('coconut_green');
    final pool = switch (type) { NutType.black => black, NutType.green => green, NutType.unknown => [...green, ...black] };
    final copra = widget.items.where((i) => i.id == 'cdb.milling_copra.kangayam').firstOrNull;

    final valid = count != null && count > 0 && grams != null && grams >= 50 && grams <= 3000;
    final kgEach = valid ? grams / 1000 : 0.0;
    final totalKg = valid ? kgEach * count : 0.0;
    double? lo, hi;
    if (pool.isNotEmpty) {
      lo = pool.map((i) => i.perKg).reduce((a, b) => a < b ? a : b);
      hi = pool.map((i) => i.perKg).reduce((a, b) => a > b ? a : b);
    }
    final rateDay = pool.isEmpty ? null : pool.map((i) => i.day).reduce((a, b) => a.isAfter(b) ? a : b);

    String range(double a, double b) => (a - b).abs() < 0.005 ? money(a, Unit.kg) : '${money(a, Unit.kg)} – ${money(b, Unit.kg)}';
    String rupees(double v) => money((v * 100).roundToDouble() / 100, Unit.kg);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: EdgeInsets.fromLTRB(16, 12, 16, 28 + MediaQuery.of(context).viewInsets.bottom),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(s.calcTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.3)),
              ),
              IconButton.filledTonal(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                tooltip: s.ta ? 'மூடு' : 'Close',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Field(label: s.calcCount, controller: countCtl, error: countErr, suffix: s.calcPieces, onChanged: () => setState(() {})),
          const SizedBox(height: 12),
          _Field(label: s.calcGrams, controller: gramsCtl, error: gramsErr, suffix: s.calcGramUnit, onChanged: () => setState(() {})),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: Text(s.calcGramsHint, style: TextStyle(fontSize: 13, color: p.ink3)),
          ),
          const SizedBox(height: 14),
          Text(s.calcType, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.ink2)),
          const SizedBox(height: 6),
          SegmentedButton<NutType>(
            segments: [
              ButtonSegment(value: NutType.black, label: Text(s.calcBlack)),
              ButtonSegment(value: NutType.green, label: Text(s.calcGreen)),
              ButtonSegment(value: NutType.unknown, label: Text(s.calcUnknown)),
            ],
            selected: {type},
            showSelectedIcon: false,
            onSelectionChanged: (v) => setState(() => type = v.first),
          ),
          const SizedBox(height: 18),
          if (pool.isEmpty)
            Text(s.calcNoRates, style: TextStyle(color: p.ink2))
          else if (!valid)
            Text(s.calcEnter, style: TextStyle(color: p.ink2))
          else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: p.leaf, borderRadius: BorderRadius.circular(14)),
              child: DefaultTextStyle.merge(
                style: TextStyle(color: p.leafInk),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.calcPerPiece, style: TextStyle(fontSize: 15, color: p.leafInk.withValues(alpha: 0.9))),
                    Text(range(kgEach * lo!, kgEach * hi!),
                        style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, height: 1.15, color: p.leafInk)),
                    const SizedBox(height: 10),
                    Text(s.calcTotal(count), style: TextStyle(fontSize: 15, color: p.leafInk.withValues(alpha: 0.9))),
                    Text('${rupees(totalKg * lo)} – ${rupees(totalKg * hi)}',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: p.leafInk)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _Line(label: s.calcWeight, value: s.calcWeightValue(totalKg)),
            _Line(label: s.calcPerTonne, value: '${money(lo, Unit.tonne)} – ${money(hi, Unit.tonne)}'),
            _Line(label: s.calcPerKg, value: range(lo, hi)),
            const SizedBox(height: 6),
            Text(
              s.calcBasis(rateDay!, pool.map((i) => s.ta ? i.marketTa : i.marketEn).toSet().join(', ')),
              style: TextStyle(fontSize: 13, color: p.ink3, height: 1.45),
            ),
            if (copra != null) ...[
              const SizedBox(height: 18),
              Text(s.calcCopraTitle, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.husk)),
              const SizedBox(height: 6),
              _Line(label: s.calcCopraKg, value: s.calcKg(totalKg * copraOutturn)),
              _Line(label: s.calcCopraValue(copra.perKg), value: rupees(totalKg * copraOutturn * copra.perKg)),
              _Line(label: s.calcCopraPerKg, value: money(copraOutturn * copra.perKg, Unit.kg)),
              const SizedBox(height: 6),
              Text(s.calcCopraNote, style: TextStyle(fontSize: 13, color: p.ink3, height: 1.45)),
            ],
            const SizedBox(height: 14),
            Text(s.calcDisclaimer, style: TextStyle(fontSize: 13, color: p.ink3, height: 1.45)),
          ],
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.controller, required this.suffix, required this.onChanged, this.error});
  final String label;
  final TextEditingController controller;
  final String suffix;
  final String? error;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: false),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)],
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          errorText: error,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => onChanged(),
      );
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(label, style: TextStyle(fontSize: 15, color: context.pal.ink2))),
            const SizedBox(width: 12),
            Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
