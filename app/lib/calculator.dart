import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'api.dart';
import 'calc_strings.dart';
import 'strings.dart';
import 'theme.dart';
import 'widgets.dart';

/// Rules of thumb traders use for dehusked coconut.
const copraOutturn = 0.30; // 100 kg nuts -> ~30 kg copra
const shellOutturn = 0.15; // ... and ~15 kg dry shell

const sizeLadder = [200, 300, 400, 500, 600, 700, 800, 900, 1000];
const countPresets = [100, 500, 1000, 2000, 5000, 10000];

enum NutType { black, green, unknown }

/// Formats a whole-rupee count with Indian grouping (1,00,000).
String nf(num n) => money(n.toDouble(), Unit.kg).substring(1);

/// "What is my coconut worth today?" Built for farmers who may not read well:
/// big taps instead of typing, a size ladder with the price on every row,
/// and a button that reads the answer aloud.
class CalculatorSheet extends StatefulWidget {
  const CalculatorSheet({super.key, required this.fresh, required this.all, required this.s});

  /// Rates from the last ~10 days (coconut and copra).
  final List<RateItem> fresh;

  /// Every series' latest rate, including slower ones like husk and shell.
  final List<RateItem> all;
  final S s;

  @override
  State<CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<CalculatorSheet> {
  int count = 1000;
  int grams = 500;
  NutType type = NutType.unknown;
  int? huskPer1000; // null = use the market rate
  int? shellPerTon;
  final tts = FlutterTts();

  S get s => widget.s;

  @override
  void dispose() {
    tts.stop().catchError((_) => null); // no voice plugin (tests, some browsers) is fine
    super.dispose();
  }

  RateItem? _byId(String id) => widget.all.where((i) => i.id == id).firstOrNull;

  List<RateItem> get _nutPool {
    final black = widget.fresh.where((i) => i.product == 'coconut_black').toList();
    final green = widget.fresh.where((i) => i.product == 'coconut_green').toList();
    return switch (type) { NutType.black => black, NutType.green => green, NutType.unknown => [...green, ...black] };
  }

  RateItem? get _huskRate => switch (type) {
        NutType.green => _byId('cdb.husk_green.pollachi'),
        _ => _byId('cdb.husk_black.pollachi'), // black husk is the lower price: safer when unsure
      };

  // Pollachi's shell figure is far off the other markets, so prefer Kangayam / Negamam.
  RateItem? get _shellRate => _byId('cdb.shell.kangayam_mkt') ?? _byId('cdb.shell.negamam');
  RateItem? get _copraRate => _byId('cdb.milling_copra.kangayam');

  int _round100(double v) => (v / 100).round() * 100;

  Future<void> _speak(int lo, int hi, int totLo, int totHi) async {
    final text = s.speech(count: count, grams: grams, lo: lo, hi: hi, totLo: totLo, totHi: totHi);
    try {
      await tts.setLanguage(s.ta ? 'ta-IN' : 'en-IN');
      await tts.setSpeechRate(0.42);
      final ok = await tts.speak(text);
      if (ok != 1 && ok != true && mounted) _toast(s.listenFailed);
    } catch (_) {
      if (mounted) _toast(s.listenFailed);
    }
  }

  void _toast(String m) => ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(m)));

  Future<void> _typeCount() async {
    final ctl = TextEditingController(text: '$count');
    String? err;
    final v = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          scrollable: true,
          title: Text(s.stepCount),
          content: TextField(
            controller: ctl,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            decoration: InputDecoration(labelText: s.typeNumber, suffixText: s.nuts, errorText: err),
            onChanged: (_) => setD(() => err = null),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
            FilledButton(
              onPressed: () {
                final n = int.tryParse(ctl.text);
                if (n == null || n < 1) {
                  setD(() => err = s.countError);
                  return;
                }
                Navigator.pop(ctx, n);
              },
              child: Text(s.ok),
            ),
          ],
        ),
      ),
    );
    ctl.dispose();
    if (v != null) setState(() => count = v);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final pool = _nutPool;
    double? lo, hi;
    DateTime? nutDay;
    if (pool.isNotEmpty) {
      lo = pool.map((i) => i.perKg).reduce((a, b) => a < b ? a : b);
      hi = pool.map((i) => i.perKg).reduce((a, b) => a > b ? a : b);
      nutDay = pool.map((i) => i.day).reduce((a, b) => a.isAfter(b) ? a : b);
    }
    final kgEach = grams / 1000;
    final totalKg = kgEach * count;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.94,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Row(
            children: [
              Expanded(child: Text(s.calcTitle, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800))),
              IconButton.filledTonal(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                tooltip: s.ta ? 'மூடு' : 'Close',
              ),
            ],
          ),
          if (pool.isEmpty) ...[
            const SizedBox(height: 24),
            Text(s.noRates, style: TextStyle(fontSize: 16, color: p.ink2)),
          ] else ...[
            // 1. How many
            _Step(n: 1, title: s.stepCount),
            _CountPicker(count: count, s: s, onChanged: (v) => setState(() => count = v), onType: _typeCount),
            // 2. How big
            _Step(n: 2, title: s.stepSize),
            Text(s.sizeHint, style: TextStyle(fontSize: 14, color: p.ink3, height: 1.45)),
            const SizedBox(height: 8),
            for (final g in sizeLadder)
              _SizeRow(
                grams: g,
                selected: g == grams,
                price: (g / 1000 * lo!, g / 1000 * hi!),
                s: s,
                onTap: () => setState(() => grams = g),
              ),
            // 3. Which type
            _Step(n: 3, title: s.stepType),
            _TypePicker(type: type, s: s, onChanged: (t) => setState(() => type = t)),
            const SizedBox(height: 18),
            // Answer
            _Answer(
              s: s,
              perNut: (kgEach * lo!, kgEach * hi!),
              total: (totalKg * lo, totalKg * hi),
              count: count,
              weight: s.kgText(totalKg),
              perTonne: '${money(lo, Unit.tonne)} – ${money(hi, Unit.tonne)}',
              onListen: () => _speak((kgEach * lo!).round(), (kgEach * hi!).round(), (totalKg * lo).round(), (totalKg * hi).round()),
            ),
            const SizedBox(height: 6),
            Text(s.rateAsOn(nutDay!, s.coconutRate), style: TextStyle(fontSize: 13, color: p.ink3)),
            ..._husk(p),
            ..._copra(p, totalKg),
            const SizedBox(height: 16),
            Text(s.disclaimer, style: TextStyle(fontSize: 13, color: p.ink3, height: 1.45)),
          ],
        ],
      ),
    );
  }

  List<Widget> _husk(Palette p) {
    final r = _huskRate;
    if (r == null) return const [];
    final price = huskPer1000 ?? _round100(r.perKg * 1000);
    final extra = count * price / 1000;
    return [
      const SizedBox(height: 20),
      _Card(
        title: s.huskTitle,
        children: [
          _Stepper(
            label: s.huskPriceLabel,
            value: price,
            step: 100,
            onChanged: (v) => setState(() => huskPer1000 = v),
          ),
          _Line(label: s.huskCount(nf(count)), value: '+ ${money(extra, Unit.kg)}', strong: true),
          _RateNote(text: s.rateAsOn(r.day, s.huskRate), old: huskPer1000 == null && _isOld(r.day), s: s),
        ],
      ),
    ];
  }

  List<Widget> _copra(Palette p, double totalKg) {
    final c = _copraRate;
    final sh = _shellRate;
    if (c == null) return const [];
    final shellPrice = shellPerTon ?? (sh == null ? 0 : _round100(sh.perKg * 1000));
    final copraKg = totalKg * copraOutturn;
    final shellKg = totalKg * shellOutturn;
    final copraVal = copraKg * c.perKg;
    final shellVal = shellKg * shellPrice / 1000;
    final total = copraVal + shellVal;
    return [
      const SizedBox(height: 14),
      _Card(
        title: s.copraTitle,
        children: [
          _Line(label: s.copraLine(s.kgText(copraKg)), value: money(copraVal.roundToDouble(), Unit.kg)),
          _Line(label: s.shellLine(s.kgText(shellKg)), value: money(shellVal.roundToDouble(), Unit.kg)),
          if (sh != null || shellPerTon != null)
            _Stepper(
              label: s.shellPriceLabel,
              value: shellPrice,
              step: 1000,
              onChanged: (v) => setState(() => shellPerTon = v),
            ),
          Divider(color: p.line),
          _Line(label: s.copraTotal, value: money(total.roundToDouble(), Unit.kg), strong: true),
          _Line(label: s.copraPerKg(money(totalKg == 0 ? 0 : total / totalKg, Unit.kg)), value: ''),
          _RateNote(text: s.rateAsOn(c.day, s.copraRate), old: false, s: s),
          if (sh != null) _RateNote(text: s.rateAsOn(sh.day, s.shellRate), old: shellPerTon == null && _isOld(sh.day), s: s),
          const SizedBox(height: 4),
          Text(s.copraNote, style: TextStyle(fontSize: 13, color: p.ink3, height: 1.45)),
        ],
      ),
    ];
  }

  bool _isOld(DateTime d) => DateTime.now().difference(d).inDays > 10;
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.title});
  final int n;
  final String title;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: p.husk,
            child: Text('$n', style: TextStyle(color: p.surface, fontWeight: FontWeight.w800, fontSize: 16)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

class _CountPicker extends StatelessWidget {
  const _CountPicker({required this.count, required this.s, required this.onChanged, required this.onType});
  final int count;
  final S s;
  final ValueChanged<int> onChanged;
  final VoidCallback onType;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final step = count >= 1000 ? 100 : (count >= 100 ? 50 : 10);
    Widget big(IconData icon, String tip, VoidCallback? onTap) => IconButton.filled(
          onPressed: onTap,
          icon: Icon(icon, size: 30),
          tooltip: tip,
          style: IconButton.styleFrom(backgroundColor: p.leaf, foregroundColor: p.leafInk, minimumSize: const Size(60, 60)),
        );
    return Column(
      children: [
        Row(
          children: [
            big(Icons.remove, '−$step', count > step ? () => onChanged(count - step) : null),
            Expanded(
              child: InkWell(
                onTap: onType,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      FittedBox(
                        child: Text(nf(count), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, height: 1.1)),
                      ),
                      Text(s.nuts, style: TextStyle(fontSize: 15, color: p.ink2)),
                    ],
                  ),
                ),
              ),
            ),
            big(Icons.add, '+$step', () => onChanged(count + step)),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final c in countPresets)
              ChoiceChip(
                label: Text(nf(c), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                selected: c == count,
                showCheckmark: false,
                onSelected: (_) => onChanged(c),
                selectedColor: p.husk,
                labelStyle: TextStyle(color: c == count ? p.surface : p.ink),
              ),
          ],
        ),
      ],
    );
  }
}

class _SizeRow extends StatelessWidget {
  const _SizeRow({required this.grams, required this.selected, required this.price, required this.s, required this.onTap});
  final int grams;
  final bool selected;
  final (double, double) price;
  final S s;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    // Coconut drawn bigger for heavier nuts so the row can be picked by eye.
    final d = 18.0 + (grams - 200) / 800 * 30;
    final (lo, hi) = price;
    final priceText = (hi - lo).abs() < 0.5 ? '₹${lo.round()}' : '₹${lo.round()} – ₹${hi.round()}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? p.husk.withValues(alpha: 0.12) : p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: selected ? p.husk : p.line, width: selected ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: Center(
                    child: Container(
                      width: d,
                      height: d * 1.08,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8A5A2B),
                        borderRadius: BorderRadius.circular(d),
                        border: Border.all(color: const Color(0xFF5E3B1A), width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.grams(grams), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      Text(s.sizeName(grams), style: TextStyle(fontSize: 13.5, color: p.ink3)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(priceText, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.husk)),
                    Text(s.perNut, style: TextStyle(fontSize: 12.5, color: p.ink3)),
                  ],
                ),
                const SizedBox(width: 6),
                Icon(selected ? Icons.check_circle : Icons.circle_outlined, color: selected ? p.husk : p.line),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypePicker extends StatelessWidget {
  const _TypePicker({required this.type, required this.s, required this.onChanged});
  final NutType type;
  final S s;
  final ValueChanged<NutType> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    Widget tile(NutType t, String label, Color? dot) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: t == type ? p.husk.withValues(alpha: 0.12) : p.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: t == type ? p.husk : p.line, width: t == type ? 2 : 1),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onChanged(t),
                child: SizedBox(
                  height: 78,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      dot == null
                          ? Icon(Icons.help_outline, size: 26, color: p.ink3)
                          : Container(width: 24, height: 24, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                      const SizedBox(height: 6),
                      Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
    return Row(
      children: [
        tile(NutType.black, s.black, const Color(0xFF3B2A1A)),
        tile(NutType.green, s.green, const Color(0xFF4E8A2E)),
        tile(NutType.unknown, s.notSure, null),
      ],
    );
  }
}

class _Answer extends StatelessWidget {
  const _Answer({
    required this.s,
    required this.perNut,
    required this.total,
    required this.count,
    required this.weight,
    required this.perTonne,
    required this.onListen,
  });
  final S s;
  final (double, double) perNut;
  final (double, double) total;
  final int count;
  final String weight;
  final String perTonne;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final (lo, hi) = perNut;
    final (tlo, thi) = total;
    String r(double a, double b) =>
        (b - a).abs() < 0.5 ? '₹${nf(a.round())}' : '₹${nf(a.round())} – ₹${nf(b.round())}';
    final dim = p.leafInk.withValues(alpha: 0.88);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: p.leaf, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.resPerNut, style: TextStyle(fontSize: 16, color: dim)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(r(lo, hi), style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800, height: 1.1, color: p.leafInk)),
          ),
          const SizedBox(height: 12),
          Text(s.resTotal(nf(count)), style: TextStyle(fontSize: 16, color: dim)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(r(tlo, thi), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: p.leafInk)),
          ),
          const SizedBox(height: 8),
          Text(s.resWeight(weight, perTonne), style: TextStyle(fontSize: 14, color: dim)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onListen,
              icon: const Icon(Icons.volume_up, size: 26),
              label: Text(s.listen, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              style: FilledButton.styleFrom(
                backgroundColor: p.leafInk,
                foregroundColor: p.leaf,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(color: p.surface, border: Border.all(color: p.line), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.husk)),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.value, required this.step, required this.onChanged});
  final String label;
  final int value;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 15, color: p.ink2))),
          IconButton.outlined(
            onPressed: value > step ? () => onChanged(value - step) : null,
            icon: const Icon(Icons.remove),
            tooltip: '−$step',
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 84),
            child: Text('₹${nf(value)}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ),
          IconButton.outlined(onPressed: () => onChanged(value + step), icon: const Icon(Icons.add), tooltip: '+$step'),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.strong = false});
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 15, color: strong ? context.pal.ink : context.pal.ink2, fontWeight: strong ? FontWeight.w700 : FontWeight.w400)),
            ),
            const SizedBox(width: 12),
            Text(value, textAlign: TextAlign.right, style: TextStyle(fontSize: strong ? 19 : 16, fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

class _RateNote extends StatelessWidget {
  const _RateNote({required this.text, required this.old, required this.s});
  final String text;
  final bool old;
  final S s;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        old ? '$text. ${s.oldRate}' : text,
        style: TextStyle(fontSize: 13, color: old ? p.down : p.ink3, height: 1.4),
      ),
    );
  }
}
