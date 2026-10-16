/// Tamil-first UI strings with English alternates.
enum Lang { ta, en }

enum Unit { kg, quintal, tonne }

extension UnitFactor on Unit {
  double get factor => switch (this) { Unit.kg => 1, Unit.quintal => 100, Unit.tonne => 1000 };
}

class S {
  const S(this.lang);
  final Lang lang;
  bool get ta => lang == Lang.ta;

  String get brand => ta ? 'தேங்காய் விலை' : 'Coconut rates';
  String get switchTo => ta ? 'English' : 'தமிழ்';
  String get heroLabel => ta ? 'காங்கேயம் அரவை கொப்பரை' : 'Kangayam milling copra';
  String get loadFailed => ta
      ? 'விலைகளை ஏற்ற முடியவில்லை. இணைய இணைப்பைச் சரிபார்த்து மீண்டும் முயலுங்கள்.'
      : "Couldn't load rates. Check your internet connection and try again.";
  String get retry => ta ? 'மீண்டும் முயல்க' : 'Try again';
  String get noChange => ta ? 'மாற்றமில்லை' : 'No change';
  String get lagNote => ta
      ? 'அரசு தரவு. சில நாட்களில் ஒரு நாள் தாமதமாக வரலாம்; ஒவ்வொரு விலைக்கும் அதன் தேதி காட்டப்படுகிறது.'
      : 'Government data. On some days it arrives a day late, so every rate shows its own date.';
  String get sourceNote => ta
      ? 'ஆதாரம்: தென்னை வளர்ச்சி வாரியம் (Coconut Development Board), அக்மார்க்நெட் (Agmarknet). விவசாயிகளுக்கு இலவசம்.'
      : 'Source: Coconut Development Board and Agmarknet. Free for farmers.';
  String get lastChecked => ta ? 'கடைசியாகச் சரிபார்த்தது' : 'Last checked';
  String get empty => ta ? 'இந்த நேரத்தில் புதிய விலைகள் இல்லை.' : 'No recent rates right now.';

  String unit(Unit u) => switch (u) {
        Unit.kg => ta ? 'கிலோ' : 'kg',
        Unit.quintal => ta ? 'குவிண்டால்' : 'quintal',
        Unit.tonne => ta ? 'டன்' : 'tonne',
      };
  String per(Unit u) => ta ? 'ஒரு ${unit(u)}' : 'per ${unit(u)}';

  String source(String s) => switch (s) {
        'cdb' => ta ? 'தென்னை வளர்ச்சி வாரியம்' : 'Coconut Development Board',
        'calc' => ta ? 'கரி விலையிலிருந்து கணக்கிட்டது' : 'calculated from charcoal price',
        _ => ta ? 'அக்மார்க்நெட்' : 'Agmarknet',
      };
  String get calculated => ta ? 'கணக்கிட்டது' : 'Calculated';
  String calcExplain(String charcoal, String ratio, String errMed, String errP90, int n) => ta
      ? 'தொட்டி விலை மாதம் ஒருமுறைதான் வெளியாகிறது. ஆனால் தொட்டி கரி விலை தினமும் வருகிறது. கடந்த $n நாள் அரசு தரவில் தொட்டி விலை = கரி விலை × $ratio ஆக இருந்தது. இன்றைய கரி $charcoal × $ratio = இந்த விலை. பழைய நாட்களில் சோதித்தபோது பொதுவாக $errMed%, 10-ல் 9 நாள் $errP90%-க்குள் சரியாக இருந்தது.'
      : 'Shell prices are published only about once a month, but shell charcoal is published daily. Over $n days of government data, shell price = charcoal price × $ratio. Today\'s charcoal $charcoal × $ratio = this price. Tested on past days it was typically within $errMed%, and within $errP90% on 9 days out of 10.';

  static const _monthsTa = ['ஜன', 'பிப்', 'மார்', 'ஏப்', 'மே', 'ஜூன்', 'ஜூலை', 'ஆக', 'செப்', 'அக்', 'நவ', 'டிச'];
  static const _monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  String date(DateTime d) => '${d.day} ${(ta ? _monthsTa : _monthsEn)[d.month - 1]}';
  String asOn(DateTime d) => ta ? '${date(d)} நிலவரம்' : 'As on ${date(d)}';

  String group(String product) => (ta ? _groupsTa : _groupsEn)[product] ?? product;
  static const _groupsTa = {
    'milling_copra': 'அரவை கொப்பரை',
    'ball_copra': 'பந்து கொப்பரை',
    'coconut_black': 'தேங்காய் (கருப்பு)',
    'coconut_green': 'தேங்காய் (பச்சை)',
    'coconut_oil': 'தேங்காய் எண்ணெய்',
    'desiccated_coconut': 'உலர் தேங்காய் துருவல்',
    'shell_calc': 'தொட்டி (ஓடு), கணக்கிட்ட இன்றைய விலை',
    'charcoal': 'தொட்டி கரி',
    'copra': 'கொப்பரை (மாநில சராசரி)',
    'coconut': 'தேங்காய் (மாநில சராசரி)',
    'tender_coconut': 'இளநீர் (மாநில சராசரி)',
  };
  static const _groupsEn = {
    'milling_copra': 'Milling copra',
    'ball_copra': 'Ball copra',
    'coconut_black': 'Coconut (black)',
    'coconut_green': 'Coconut (green)',
    'coconut_oil': 'Coconut oil',
    'desiccated_coconut': 'Desiccated coconut',
    'shell_calc': "Shell, today's calculated price",
    'charcoal': 'Shell charcoal',
    'copra': 'Copra (state average)',
    'coconut': 'Coconut (state average)',
    'tender_coconut': 'Tender coconut (state average)',
  };

  String area(String a) => (ta ? _areasTa : _areasEn)[a] ?? a;
  static const _areasTa = {
    'all': 'அனைத்தும்',
    'kangayam': 'காங்கேயம்',
    'pollachi': 'பொள்ளாச்சி',
    'coimbatore': 'கோவை / உடுமலை',
    'kerala': 'கேரளா',
    'karnataka': 'கர்நாடகா',
    'state': 'மாநில சராசரி',
  };
  static const _areasEn = {
    'all': 'All',
    'kangayam': 'Kangayam',
    'pollachi': 'Pollachi',
    'coimbatore': 'Coimbatore / Udumalpet',
    'kerala': 'Kerala',
    'karnataka': 'Karnataka',
    'state': 'State average',
  };

  String range(int days) => switch (days) {
        20 => ta ? '20 நாள்' : '20D',
        30 => ta ? '1 மாதம்' : '1M',
        90 => ta ? '3 மாதம்' : '3M',
        180 => ta ? '6 மாதம்' : '6M',
        _ => ta ? '1 வருடம்' : '1Y',
      };
}

const groupOrder = [
  'milling_copra', 'ball_copra', 'coconut_black', 'coconut_green', 'coconut_oil',
  'shell_calc', 'charcoal', 'desiccated_coconut', 'copra', 'coconut', 'tender_coconut',
];
const marketOrder = [
  'kangayam', 'kangayam_mkt', 'pollachi', 'pollachi_mkt', 'negamam', 'udumalpet', 'coimbatore',
  'tamil_nadu', 'kochi', 'kozhikode', 'kerala', 'tiptur', 'arisikere',
];
const areaOf = {
  'kangayam': 'kangayam', 'kangayam_mkt': 'kangayam', 'pollachi': 'pollachi', 'pollachi_mkt': 'pollachi',
  'coimbatore': 'coimbatore', 'udumalpet': 'coimbatore', 'kochi': 'kerala', 'kozhikode': 'kerala',
  'tiptur': 'karnataka', 'arisikere': 'karnataka', 'tamil_nadu': 'state', 'kerala': 'state',
  'negamam': 'pollachi',
};
const areaOrder = ['all', 'kangayam', 'pollachi', 'coimbatore', 'kerala', 'karnataka', 'state'];
