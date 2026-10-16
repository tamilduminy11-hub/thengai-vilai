import 'strings.dart';

/// Calculator wording. Short sentences, everyday Tamil words (காய், மட்டை, தொட்டி).
extension CalcStrings on S {
  String get calcButton => ta ? 'என் தேங்காய்க்கு என்ன விலை?' : 'What is my coconut worth?';
  String get calcTitle => ta ? 'என் தேங்காய் விலை' : 'My coconut price';
  String get listen => ta ? 'கேளுங்கள்' : 'Listen';
  String get listenFailed => ta ? 'இந்த போனில் தமிழ் குரல் இல்லை.' : 'Voice is not available on this phone.';

  String get stepCount => ta ? 'எத்தனை தேங்காய்?' : 'How many coconuts?';
  String get nuts => ta ? 'காய்' : 'nuts';
  String get typeNumber => ta ? 'எண்ணிக்கை' : 'Number';
  String get ok => ta ? 'சரி' : 'OK';
  String get cancel => ta ? 'வேண்டாம்' : 'Cancel';
  String get countError => ta ? '1 அல்லது அதற்கு மேல் உள்ளிடுங்கள்' : 'Enter 1 or more';

  String get stepSize => ta ? 'ஒரு காய் எவ்வளவு பெரியது?' : 'How big is one coconut?';
  String get sizeHint => ta
      ? 'உரித்த காய் எடை. உங்கள் காய் போன்ற வரிசையைத் தொடுங்கள். சரியாகத் தெரிய: 10 காய் எடைபோட்டு 10-ஆல் வகுங்கள்.'
      : 'Weight of a dehusked nut. Tap the row that looks like yours. For accuracy, weigh 10 nuts and divide by 10.';
  String grams(int g) => g >= 1000 ? (ta ? '1 கிலோ' : '1 kg') : (ta ? '$g கிராம்' : '$g g');
  String sizeName(int g) => switch (g) {
        <= 200 => ta ? 'மிகச் சிறியது' : 'Very small',
        <= 300 => ta ? 'சிறியது' : 'Small',
        <= 500 => ta ? 'நடுத்தரம்' : 'Medium',
        <= 700 => ta ? 'பெரியது' : 'Big',
        _ => ta ? 'மிகப் பெரியது' : 'Very big',
      };
  String get perNut => ta ? 'ஒரு காய்' : 'per nut';

  String get stepType => ta ? 'என்ன வகை?' : 'Which type?';
  String get black => ta ? 'கருப்பு' : 'Black';
  String get green => ta ? 'பச்சை' : 'Green';
  String get notSure => ta ? 'தெரியாது' : 'Not sure';

  String get resPerNut => ta ? 'ஒரு காய்க்கு' : 'Per coconut';
  String resTotal(String n) => ta ? '$n காய்க்கு மொத்தம்' : 'Total for $n coconuts';
  String resWeight(String w, String perTonne) => ta ? 'மொத்த எடை $w · ஒரு டன் $perTonne' : 'Total weight $w · per tonne $perTonne';
  String kgText(double kg) => kg >= 1000
      ? '${(kg / 1000).toStringAsFixed(2)} ${ta ? 'டன்' : 'tonne'}'
      : '${kg.toStringAsFixed(kg < 10 ? 1 : 0)} ${ta ? 'கிலோ' : 'kg'}';

  String get huskTitle => ta ? 'மட்டையும் விற்றால் கூடுதல்' : 'Extra if you also sell the husks';
  String get huskPriceLabel => ta ? '1000 மட்டை விலை' : 'Price for 1000 husks';
  String huskCount(String n) => ta ? '$n மட்டை' : '$n husks';

  String get copraTitle => ta ? 'கொப்பரை ஆக்கி விற்றால்' : 'If you make copra instead';
  String copraLine(String kg) => ta ? 'கொப்பரை $kg (30%)' : 'Copra $kg (30%)';
  String shellLine(String kg) => ta ? 'தொட்டி (ஓடு) $kg (15%)' : 'Shell $kg (15%)';
  String get shellPriceLabel => ta ? 'தொட்டி விலை (ஒரு டன்)' : 'Shell price (per tonne)';
  String get copraTotal => ta ? 'கொப்பரை + தொட்டி மொத்தம்' : 'Copra + shell total';
  String copraPerKg(String v) => ta ? 'தேங்காய் ஒரு கிலோவுக்கு $v' : '$v per kg of coconut';
  String get copraNote => ta
      ? '100 கிலோ உரித்த காய் ≈ 30 கிலோ கொப்பரை + 15 கிலோ தொட்டி. உலர்த்தும் கூலி, வேலை செலவு இதில் கழிக்கப்படவில்லை.'
      : '100 kg dehusked coconut ≈ 30 kg copra + 15 kg shell. Drying and labour costs are not subtracted.';

  String rateAsOn(DateTime d, String what) => ta ? '$what: ${date(d)} நிலவரம்' : '$what: as on ${date(d)}';
  String get enterTodayHusk => ta
      ? 'இன்றைய மட்டை விலை அரசு தளத்தில் இல்லை. உங்களுக்குச் சொன்ன விலையை + அழுத்தி வையுங்கள்.'
      : "Today's husk price isn't published. Press + to set the price you were quoted.";
  String get enterTodayShell => ta
      ? 'இன்றைய தொட்டி விலை அரசு தளத்தில் இல்லை. உங்களுக்குச் சொன்ன விலையை + அழுத்தி வையுங்கள்.'
      : "Today's shell price isn't published. Press + to set the price you were quoted.";
  String get yourPrice => ta ? 'நீங்கள் வைத்த விலை' : 'Price you set';
  String get oldRate => ta ? 'பழைய விலை. இன்றைய விலை தெரிந்தால் + / − அழுத்தி மாற்றுங்கள்.' : 'Older rate. If you know today\'s price, change it with + / −.';
  String get coconutRate => ta ? 'தேங்காய் விலை' : 'Coconut rate';
  String get huskRate => ta ? 'மட்டை விலை' : 'Husk rate';
  String get shellRate => ta ? 'தொட்டி விலை' : 'Shell rate';
  String get copraRate => ta ? 'கொப்பரை விலை' : 'Copra rate';
  String get noRates => ta ? 'இன்று தேங்காய் சந்தை விலை கிடைக்கவில்லை.' : 'No coconut market rate available right now.';
  String get disclaimer => ta
      ? 'இது அரசு சந்தை விலையை வைத்துப் போட்ட தோராயக் கணக்கு. காயின் தரம், உலர்வு, வியாபாரி பொறுத்து விலை மாறும்.'
      : 'An estimate from the government market rate. The real price depends on nut quality, dryness and the buyer.';

  /// Sentence read aloud. Digits only (no ₹ or commas) so phone voices say them cleanly.
  String speech({required int count, required int grams, required int lo, required int hi, required int totLo, required int totHi}) =>
      ta
          ? '$count தேங்காய். ஒரு காய் $grams கிராம். ஒரு காய்க்கு $lo முதல் $hi ரூபாய் வரை கிடைக்கும். மொத்தம் $totLo முதல் $totHi ரூபாய்.'
          : '$count coconuts. Each $grams grams. You can get $lo to $hi rupees per coconut. Total $totLo to $totHi rupees.';
}
