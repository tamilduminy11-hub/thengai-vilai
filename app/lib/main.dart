import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'calculator.dart';
import 'detail_sheet.dart';
import 'strings.dart';
import 'theme.dart';
import 'widgets.dart';

void main() => runApp(const ThengaiVilaiApp());

class ThengaiVilaiApp extends StatelessWidget {
  const ThengaiVilaiApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'தேங்காய் விலை',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: const HomeScreen(),
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final api = RatesApi();
  SharedPreferences? prefs;
  Lang lang = Lang.ta;
  Unit unit = Unit.kg;
  String area = 'all';

  List<RateItem>? items;
  List<DayRate>? heroSeries;
  DateTime? checked;
  bool failed = false;

  S get s => S(lang);

  @override
  void initState() {
    super.initState();
    _restorePrefs();
    _load();
  }

  Future<void> _restorePrefs() async {
    try {
      final p = await SharedPreferences.getInstance();
      prefs = p;
      if (!mounted) return;
      setState(() {
        lang = p.getString('lang') == 'en' ? Lang.en : Lang.ta;
        unit = Unit.values.firstWhere((u) => u.name == p.getString('unit'), orElse: () => Unit.kg);
        area = p.getString('area') ?? 'all';
      });
    } catch (_) {
      // Preferences are a convenience; the app works without them.
    }
  }

  Future<void> _load() async {
    setState(() => failed = false);
    try {
      final latest = await api.latest();
      DateTime? c;
      try {
        c = await api.lastChecked();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        items = latest;
        checked = c;
      });
      final hero = await api.series('cdb.milling_copra.kangayam', days: 40);
      if (mounted) setState(() => heroSeries = hero);
    } catch (_) {
      if (mounted) setState(() => failed = items == null);
    }
  }

  /// Hide series that stopped reporting: anything more than 10 days behind the newest rate.
  List<RateItem> get fresh {
    final list = items ?? const <RateItem>[];
    if (list.isEmpty) return list;
    final newest = list.map((i) => i.day).reduce((a, b) => a.isAfter(b) ? a : b);
    return list.where((i) => newest.difference(i.day).inDays <= 10).toList();
  }

  void _setLang() {
    setState(() => lang = lang == Lang.ta ? Lang.en : Lang.ta);
    prefs?.setString('lang', lang.name);
  }

  void _setUnit(Unit u) {
    setState(() => unit = u);
    prefs?.setString('unit', u.name);
  }

  void _setArea(String a) {
    setState(() => area = a);
    prefs?.setString('area', a);
  }

  void _open(RateItem i) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.pal.surface,
      constraints: const BoxConstraints(maxWidth: 560),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => DetailSheet(item: i, api: api, s: s, unit: unit),
    );
  }

  void _openCalculator() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.pal.surface,
      constraints: const BoxConstraints(maxWidth: 560),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => CalculatorSheet(items: fresh, s: s),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final hero = items?.where((i) => i.id == 'cdb.milling_copra.kangayam').firstOrNull;
    final freshItems = fresh;
    final presentAreas = {for (final i in freshItems) areaOf[i.market] ?? 'state'};
    final activeArea = area == 'all' || presentAreas.contains(area) ? area : 'all';
    final shown = freshItems.where((i) => activeArea == 'all' || areaOf[i.market] == activeArea).toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Header(s: s, unit: unit, hero: hero, heroSeries: heroSeries, onLang: _setLang),
            ),
            SliverToBoxAdapter(
              child: Column660(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (items != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _openCalculator,
                          icon: const Icon(Icons.calculate_outlined),
                          label: Text(s.calcButton, textAlign: TextAlign.center),
                          style: FilledButton.styleFrom(
                            backgroundColor: p.husk,
                            foregroundColor: p.surface,
                            minimumSize: const Size.fromHeight(54),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    UnitSwitch(s: s, unit: unit, onChanged: _setUnit),
                    const SizedBox(height: 14),
                    AreaChips(
                      s: s,
                      areas: areaOrder.where((a) => a == 'all' || presentAreas.contains(a)).toList(),
                      active: activeArea,
                      onChanged: _setArea,
                    ),
                    const SizedBox(height: 8),
                    Text(s.lagNote, style: TextStyle(fontSize: 14, color: p.ink3, height: 1.45)),
                  ],
                ),
              ),
            ),
            if (failed)
              SliverToBoxAdapter(child: StateMessage(text: s.loadFailed, action: s.retry, onAction: _load))
            else if (items == null)
              const SliverToBoxAdapter(
                child: Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator())),
              )
            else if (shown.isEmpty)
              SliverToBoxAdapter(child: StateMessage(text: s.empty))
            else
              ..._groups(shown),
            SliverToBoxAdapter(child: Footer(s: s, checked: checked)),
          ],
        ),
      ),
    );
  }

  List<Widget> _groups(List<RateItem> shown) {
    final byProduct = <String, List<RateItem>>{};
    for (final i in shown) {
      byProduct.putIfAbsent(i.product, () => []).add(i);
    }
    int rank(String m) {
      final r = marketOrder.indexOf(m);
      return r < 0 ? 999 : r;
    }

    return [
      for (final g in groupOrder)
        if (byProduct[g] != null)
          SliverToBoxAdapter(
            child: RateGroup(
              title: s.group(g),
              items: byProduct[g]!..sort((a, b) => rank(a.market).compareTo(rank(b.market))),
              s: s,
              unit: unit,
              onTap: _open,
            ),
          ),
    ];
  }
}
