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

  String source(String s) => s == 'cdb'
      ? (ta ? 'தென்னை வளர்ச்சி வாரியம்' : 'Coconut Development Board')
      : (ta ? 'அக்மார்க்நெட்' : 'Agmarknet');

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

  // Coconut value calculator
  String get calcButton => ta ? 'என் தேங்காய்க்கு என்ன விலை? கணக்கிடு' : 'What is my coconut worth? Calculate';
  String get calcTitle => ta ? 'என் தேங்காய் விலை கணக்கீடு' : 'My coconut price';
  String get calcCount => ta ? 'தேங்காய் எண்ணிக்கை' : 'Number of coconuts';
  String get calcPieces => ta ? 'காய்' : 'nuts';
  String get calcGrams => ta ? 'ஒரு தேங்காயின் எடை' : 'Weight of one coconut';
  String get calcGramUnit => ta ? 'கிராம்' : 'grams';
  String get calcGramsHint => ta
      ? 'உரித்த தேங்காய். சாதாரணமாக 400–700 கிராம். 10 காய் எடைபோட்டு 10-ஆல் வகுத்தால் சரியான சராசரி கிடைக்கும்.'
      : 'Dehusked nut, usually 400–700 g. Weigh 10 nuts and divide by 10 for a good average.';
  String get calcType => ta ? 'தேங்காய் வகை' : 'Coconut type';
  String get calcBlack => ta ? 'கருப்பு' : 'Black';
  String get calcGreen => ta ? 'பச்சை' : 'Green';
  String get calcUnknown => ta ? 'தெரியவில்லை' : 'Not sure';
  String get calcCountError => ta ? 'எண்ணிக்கையை உள்ளிடுங்கள் (1 அல்லது அதற்கு மேல்)' : 'Enter a number of 1 or more';
  String get calcGramsError => ta ? '50 முதல் 3000 கிராம் வரை உள்ளிடுங்கள்' : 'Enter between 50 and 3000 grams';
  String get calcEnter => ta ? 'எண்ணிக்கையும் எடையும் உள்ளிட்டால் விலை தெரியும்.' : 'Enter the count and weight to see the price.';
  String get calcNoRates => ta ? 'இன்று தேங்காய் சந்தை விலை கிடைக்கவில்லை.' : "No coconut market rate available right now.";
  String get calcPerPiece => ta ? 'ஒரு தேங்காய்க்கு' : 'Per coconut';
  String calcTotal(int n) => ta ? '$n தேங்காய்க்கு மொத்தம்' : 'Total for $n coconuts';
  String get calcWeight => ta ? 'மொத்த எடை' : 'Total weight';
  String calcKg(double kg) => kg >= 1000
      ? '${(kg / 1000).toStringAsFixed(2)} ${ta ? 'டன்' : 'tonne'}'
      : '${kg.toStringAsFixed(kg < 10 ? 1 : 0)} ${ta ? 'கிலோ' : 'kg'}';
  String calcWeightValue(double kg) => calcKg(kg);
  String get calcPerTonne => ta ? 'ஒரு டன் சந்தை விலை' : 'Market price per tonne';
  String get calcPerKg => ta ? 'ஒரு கிலோ சந்தை விலை' : 'Market price per kg';
  String calcBasis(DateTime d, String markets) => ta
      ? '${date(d)} சந்தை விலை ($markets), தென்னை வளர்ச்சி வாரியம்.'
      : 'Market rate as on ${date(d)} ($markets), Coconut Development Board.';
  String get calcCopraTitle => ta ? 'கொப்பரை கணக்கில் சரிபார்ப்பு' : 'Copra cross-check';
  String get calcCopraKg => ta ? 'கிடைக்கும் கொப்பரை (30%)' : 'Copra you would get (30%)';
  String calcCopraValue(double perKg) => ta
      ? 'கொப்பரை மதிப்பு (காங்கேயம் ₹${perKg.toStringAsFixed(0)}/கிலோ)'
      : 'Copra value (Kangayam ₹${perKg.toStringAsFixed(0)}/kg)';
  String get calcCopraPerKg => ta ? 'தேங்காய் ஒரு கிலோவுக்கு (கொப்பரை மட்டும்)' : 'Per kg coconut (copra only)';
  String get calcCopraNote => ta
      ? '100 கிலோ உரித்த தேங்காய் ≈ 30 கிலோ கொப்பரை + சுமார் 15 கிலோ தொட்டி (ஓடு). தொட்டி விற்பனை சேர்த்தால் மதிப்பு கொஞ்சம் கூடும்; உலர்த்தும் கூலி கழிந்தால் குறையும்.'
      : '100 kg dehusked coconut ≈ 30 kg copra + about 15 kg shell. Selling the shell adds a little; drying and labour costs take a little away.';
  String get calcDisclaimer => ta
      ? 'இது இன்றைய அரசு சந்தை விலையின் அடிப்படையில் தோராயக் கணக்கு. காயின் தரம், உலர்வு, வியாபாரி பொறுத்து விலை மாறும்.'
      : "An estimate from today's government market rate. Actual price depends on nut quality, dryness and the buyer.";

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
  'desiccated_coconut', 'copra', 'coconut', 'tender_coconut',
];
const marketOrder = [
  'kangayam', 'kangayam_mkt', 'pollachi', 'pollachi_mkt', 'udumalpet', 'coimbatore',
  'tamil_nadu', 'kochi', 'kozhikode', 'kerala', 'tiptur', 'arisikere',
];
const areaOf = {
  'kangayam': 'kangayam', 'kangayam_mkt': 'kangayam', 'pollachi': 'pollachi', 'pollachi_mkt': 'pollachi',
  'coimbatore': 'coimbatore', 'udumalpet': 'coimbatore', 'kochi': 'kerala', 'kozhikode': 'kerala',
  'tiptur': 'karnataka', 'arisikere': 'karnataka', 'tamil_nadu': 'state', 'kerala': 'state',
};
const areaOrder = ['all', 'kangayam', 'pollachi', 'coimbatore', 'kerala', 'karnataka', 'state'];
