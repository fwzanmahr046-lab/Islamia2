import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:adhan/adhan.dart' as adhan_lib;

// ==========================================
// 1. ADVANCED TRANSLATION & GEOLOCATION MAPPING
// ==========================================

class LocationService {
  // Bi-directional dictionary for Arabic/English names
  static const Map<String, String> _arabicToEnglish = {
    'بغداد': 'Baghdad',
    'العراق': 'Iraq',
    'النجف': 'Najaf',
    'كربلاء': 'Karbala',
    'أربيل': 'Erbil',
    'البصرة': 'Basra',
    'الموصل': 'Mosul',
    'السليمانية': 'Sulaymaniyah',
    'كركوك': 'Kirkuk',
    'مكة': 'Makkah',
    'مكة المكرمة': 'Makkah',
    'المدينة': 'Medina',
    'المدينة المنورة': 'Medina',
    'الرياض': 'Riyadh',
    'جدة': 'Jeddah',
    'السعودية': 'Saudi Arabia',
    'المملكة العربية السعودية': 'Saudi Arabia',
    'القاهرة': 'Cairo',
    'مصر': 'Egypt',
    'دمشق': 'Damascus',
    'سوريا': 'Syria',
    'عمان': 'Amman',
    'الأردن': 'Jordan',
    'بيروت': 'Beirut',
    'لبنان': 'Lebanon',
    'الكويت': 'Kuwait',
    'الدوحة': 'Doha',
    'قطر': 'Qatar',
    'مسقط': 'Muscat',
    'عمان السلطنة': 'Oman',
    'المنامة': 'Manama',
    'البحرين': 'Bahrain',
    'دبي': 'Dubai',
    'الإمارات': 'United Arab Emirates',
    'إسطنبول': 'Istanbul',
    'تركيا': 'Turkey',
  };

  static const Map<String, String> _englishToArabic = {
    'baghdad': 'بغداد',
    'iraq': 'العراق',
    'najaf': 'النجف',
    'karbala': 'كربلاء',
    'erbil': 'أربيل',
    'basra': 'البصرة',
    'mosul': 'الموصل',
    'makkah': 'مكة المكرمة',
    'mecca': 'مكة المكرمة',
    'medina': 'المدينة المنورة',
    'riyadh': 'الرياض',
    'saudi arabia': 'السعودية',
    'cairo': 'القاهرة',
    'egypt': 'مصر',
    'damascus': 'دمشق',
    'syria': 'سوريا',
    'amman': 'عمان',
    'jordan': 'الأردن',
    'beirut': 'بيروت',
    'lebanon': 'لبنان',
    'kuwait': 'الكويت',
    'doha': 'الدوحة',
    'qatar': 'قطر',
    'dubai': 'دبي',
    'united arab emirates': 'الإمارات',
    'uae': 'الإمارات',
    'istanbul': 'إسطنبول',
    'turkey': 'تركيا',
  };

  // Known city coordinates fallback map
  static const Map<String, adhan_lib.Coordinates> _cityCoordinates = {
    'baghdad': adhan_lib.Coordinates(33.3152, 44.3661),
    'najaf': adhan_lib.Coordinates(32.0259, 44.3463),
    'karbala': adhan_lib.Coordinates(32.6160, 44.0249),
    'erbil': adhan_lib.Coordinates(36.1901, 44.0091),
    'basra': adhan_lib.Coordinates(30.5081, 47.7835),
    'mosul': adhan_lib.Coordinates(36.3400, 43.1300),
    'makkah': adhan_lib.Coordinates(21.4225, 39.8262),
    'mecca': adhan_lib.Coordinates(21.4225, 39.8262),
    'medina': adhan_lib.Coordinates(24.5247, 39.5692),
    'riyadh': adhan_lib.Coordinates(24.7136, 46.6753),
    'cairo': adhan_lib.Coordinates(30.0444, 31.2357),
    'damascus': adhan_lib.Coordinates(33.5138, 36.2765),
    'amman': adhan_lib.Coordinates(31.9454, 35.9284),
  };

  static String toEnglish(String input) {
    final clean = input.trim();
    if (_arabicToEnglish.containsKey(clean)) {
      return _arabicToEnglish[clean]!;
    }
    return clean;
  }

  static String toArabic(String input) {
    final clean = input.trim().toLowerCase();
    if (_englishToArabic.containsKey(clean)) {
      return _englishToArabic[clean]!;
    }
    return input;
  }

  static adhan_lib.Coordinates getCoordinates(String city) {
    final clean = toEnglish(city).toLowerCase();
    return _cityCoordinates[clean] ?? const adhan_lib.Coordinates(33.3152, 44.3661);
  }

  static String formatArabicDate(DateTime date) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} م';
  }
}

// ==========================================
// 2. HIGH-PRECISION PRAYER MODELS
// ==========================================

class PrayerTimesData {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String date;

  const PrayerTimesData({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.date,
  });

  factory PrayerTimesData.fromAdhanLib(adhan_lib.PrayerTimes times) {
    return PrayerTimesData(
      fajr: _formatTime(times.fajr),
      sunrise: _formatTime(times.sunrise),
      dhuhr: _formatTime(times.dhuhr),
      asr: _formatTime(times.asr),
      maghrib: _formatTime(times.maghrib),
      isha: _formatTime(times.isha),
      date: LocationService.formatArabicDate(DateTime.now()),
    );
  }

  factory PrayerTimesData.fromJson(Map<String, dynamic> json) {
    final timings = json['data']['timings'];
    return PrayerTimesData(
      fajr: _formatTo12Hour(timings['Fajr'] ?? ''),
      sunrise: _formatTo12Hour(timings['Sunrise'] ?? ''),
      dhuhr: _formatTo12Hour(timings['Dhuhr'] ?? ''),
      asr: _formatTo12Hour(timings['Asr'] ?? ''),
      maghrib: _formatTo12Hour(timings['Maghrib'] ?? ''),
      isha: _formatTo12Hour(timings['Isha'] ?? ''),
      date: LocationService.formatArabicDate(DateTime.now()),
    );
  }

  static String _formatTime(DateTime dt) {
    final localDt = dt.toLocal();
    final hour = localDt.hour % 12 == 0 ? 12 : localDt.hour % 12;
    final min = localDt.minute.toString().padLeft(2, '0');
    final period = localDt.hour >= 12 ? 'م' : 'ص';
    return '$hour:$min $period';
  }

  static String _formatTo12Hour(String rawTime) {
    if (rawTime.isEmpty) return '';
    final cleanTime = rawTime.split(' ').first;
    final parts = cleanTime.split(':');
    if (parts.length < 2) return rawTime;

    int hour = int.tryParse(parts[0]) ?? 0;
    int minute = int.tryParse(parts[1]) ?? 0;

    final period = hour >= 12 ? 'م' : 'ص';
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }

    final minStr = minute.toString().padLeft(2, '0');
    return '$hour:$minStr $period';
  }
}

// ==========================================
// 3. ATHKAR & DUA MODELS & VERIFIED DATA
// ==========================================

class ThikrData {
  final String text;
  final String reference;
  final int targetCount;
  int currentCount;

  ThikrData({
    required this.text,
    required this.reference,
    required this.targetCount,
    this.currentCount = 0,
  });
}

class ThikrCategory {
  final String title;
  final IconData icon;
  final List<ThikrData> athkar;

  ThikrCategory({
    required this.title,
    required this.icon,
    required this.athkar,
  });
}

// ==========================================
// 4. PERFORMANCE & REPOSITORY MANAGEMENT
// ==========================================

class AppRepository extends ChangeNotifier {
  PrayerTimesData? prayerTimes;
  bool isLoading = false;
  String errorMessage = '';

  String currentCity = 'Baghdad';
  String currentCountry = 'Iraq';

  String get currentCityArabic => LocationService.toArabic(currentCity);
  String get currentCountryArabic => LocationService.toArabic(currentCountry);

  int calculationMethod = 4; // Default: Umm Al-Qura / standard
  int asrJurisprudence = 0;  // 0: Standard/Shafi, 1: Hanafi

  // Fast In-Memory Cache for Zero Delay
  final Map<String, PrayerTimesData> _prayerCache = {};

  final ValueNotifier<int> tasbeehCounterNotifier = ValueNotifier<int>(0);
  int selectedTasbeehIndex = 0;

  final List<String> tasbeehPhrases = const [
    'سبحان الله',
    'الحمد لله',
    'الله أكبر',
    'لا إله إلا الله',
    'أستغفر الله وأتوب إليه',
    'لا حول ولا قوة إلا بالله',
    'اللهم صلِّ وسلم على نبينا محمد',
    'سبحان الله وبحمده، سبحان الله العظيم',
  ];

  // 26 FULLY VERIFIED ATHKAR AND DUAS (صحيحة وموثقة 100%)
  final List<ThikrCategory> athkarCategories = [
    ThikrCategory(
      title: 'أذكار الصباح',
      icon: Icons.wb_sunny_rounded,
      athkar: [
        ThikrData(
          text: 'آية الكرسي: ﴿اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ...﴾',
          reference: 'سورة البقرة - آية 255 (من قالها حين يصبح أُجير من الجن حتى يمسي)',
          targetCount: 1,
        ),
        ThikrData(
          text: 'قراءة سورة الإخلاص، وسورة الفلق، وسورة الناس.',
          reference: 'سنن أبي داود والترمذي (تكفيك من كل شيء)',
          targetCount: 3,
        ),
        ThikrData(
          text: 'أصبحنا وأصبح الملك لله، والحمد لله، لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير.',
          reference: 'صحيح مسلم',
          targetCount: 1,
        ),
        ThikrData(
          text: 'اللهم بك أصبحنا، وبك أمسينا، وبك نحيا، وبك نموت، وإليك النشور.',
          reference: 'سنن الترمذي',
          targetCount: 1,
        ),
        ThikrData(
          text: 'اللهم أنت ربي لا إله إلا أنت، خلقتني وأنا عبدك، وأنا على عهدك ووعدك ما استطعت، أعوذ بك من شر ما صنعت، أبوء لك بنعمتك علي، وأبوء بذنبي فاغفر لي فإنه لا يغفر الذنوب إلا أنت.',
          reference: 'سيد الاستغفار - صحيح البخاري',
          targetCount: 1,
        ),
        ThikrData(
          text: 'بسم الله الذي لا يضر مع اسمه شيء في الأرض ولا في السماء وهو السميع العليم.',
          reference: 'سنن أبي داود والترمذي (لم يضره شيء)',
          targetCount: 3,
        ),
        ThikrData(
          text: 'رضيت بالله رباً، وبالإسلام ديناً، وبمحمد صلى الله عليه وسلم نبياً.',
          reference: 'مسند أحمد وسنن أبي داود',
          targetCount: 3,
        ),
        ThikrData(
          text: 'يا حي يا قيوم برحمتك أستغيث، أصلح لي شأني كله ولا تكلني إلى نفسي طرفة عين.',
          reference: 'السنن الكبرى للنسائي - صحيح',
          targetCount: 1,
        ),
        ThikrData(
          text: 'حسبي الله لا إله إلا هو عليه توكلت وهو رب العرش العظيم.',
          reference: 'سنن أبي داود (كفاه الله ما أهمه)',
          targetCount: 7,
        ),
        ThikrData(
          text: 'سبحان الله وبحمده: عدد خلقه، ورضا نفسه، وزنة عرشه، ومداد كلماته.',
          reference: 'صحيح مسلم',
          targetCount: 3,
        ),
        ThikrData(
          text: 'سبحان الله وبحمده.',
          reference: 'صحيح مسلم (حُطّت خطاياه وإن كانت مثل زبد البحر)',
          targetCount: 100,
        ),
      ],
    ),
    ThikrCategory(
      title: 'أذكار المساء',
      icon: Icons.nights_stay_rounded,
      athkar: [
        ThikrData(
          text: 'أمسينا وأمسى الملك لله والحمد لله، لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير.',
          reference: 'صحيح مسلم',
          targetCount: 1,
        ),
        ThikrData(
          text: 'اللهم بك أمسينا، وبك أصبحنا، وبك نحيا، وبك نموت وإليك المصير.',
          reference: 'سنن الترمذي',
          targetCount: 1,
        ),
        ThikrData(
          text: 'أعوذ بكلمات الله التامات من شر ما خلق.',
          reference: 'صحيح مسلم (لم تضره حمة/شيء في تلك الليلة)',
          targetCount: 3,
        ),
        ThikrData(
          text: 'اللهم إني أسألك العفو والعافية في الدنيا والآخرة، اللهم إني أسألك العفو والعافية في ديني ودنياي وأهلي ومالي.',
          reference: 'سنن أبي داود وابن ماجه',
          targetCount: 1,
        ),
        ThikrData(
          text: 'أستغفر الله وأتوب إليه.',
          reference: 'صحيح البخاري ومسلم',
          targetCount: 100,
        ),
      ],
    ),
    ThikrCategory(
      title: 'أذكار دبر الصلاة',
      icon: Icons.mosque_rounded,
      athkar: [
        ThikrData(
          text: 'أستغفر الله، أستغفر الله، أستغفر الله. اللهم أنت السلام ومنك السلام، تباركت يا ذا الجلال والإكرام.',
          reference: 'صحيح مسلم',
          targetCount: 1,
        ),
        ThikrData(
          text: 'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير، اللهم لا مانع لما أعطيت، ولا معطي لما منعت، ولا ينفع ذا الجد منك الجد.',
          reference: 'صحيح البخاري ومسلم',
          targetCount: 1,
        ),
        ThikrData(
          text: 'التسبيح والتحميد والتكبير: سبحان الله (33)، الحمد لله (33)، الله أكبر (33)، وختامها: لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير.',
          reference: 'صحيح مسلم (غُفرت خطاياه وإن كانت مثل زبد البحر)',
          targetCount: 1,
        ),
      ],
    ),
    ThikrCategory(
      title: 'أذكار النوم والاستيقاظ',
      icon: Icons.bed_rounded,
      athkar: [
        ThikrData(
          text: 'باسمك ربي وضعت جنبي وبك أرفعه، إن ألمسكت نفسي فارحمها، وإن أرسلتها فاحفظها بما تحفظ به عبادك الصالحين.',
          reference: 'صحيح البخاري ومسلم',
          targetCount: 1,
        ),
        ThikrData(
          text: 'اللهم قني عذابك يوم تبعث عبادك.',
          reference: 'سنن أبي داود والترمذي',
          targetCount: 3,
        ),
        ThikrData(
          text: 'الحمد لله الذي أحيانا بعد ما أماتنا وإليه النشور.',
          reference: 'عند الاستيقاظ - صحيح البخاري',
          targetCount: 1,
        ),
      ],
    ),
    ThikrCategory(
      title: 'أدعية نبوية وقرآنية',
      icon: Icons.menu_book_rounded,
      athkar: [
        ThikrData(
          text: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ.',
          reference: 'سورة البقرة / جامع دعاء النبي ﷺ',
          targetCount: 1,
        ),
        ThikrData(
          text: 'اللهم إني أسألك الهدى والتُقى والعَفاف والغِنى.',
          reference: 'صحيح مسلم',
          targetCount: 1,
        ),
        ThikrData(
          text: 'لا إله إلا أنت سبحانك إني كنت من الظالمين.',
          reference: 'دعاء ذي النون - سنن الترمذي (لم يدعُ بها رجل مسلم في شيء قط إلا استجاب الله له)',
          targetCount: 1,
        ),
        ThikrData(
          text: 'يا مقلّب القلوب ثبّت قلبي على دينك.',
          reference: 'سنن الترمذي',
          targetCount: 1,
        ),
      ],
    ),
  ];

  AppRepository() {
    loadPrayerTimes(currentCity, currentCountry);
  }

  Future<void> loadPrayerTimes(String city, String country) async {
    final cityEng = LocationService.toEnglish(city);
    final countryEng = LocationService.toEnglish(country);
    final cacheKey = '$cityEng-$countryEng-$calculationMethod-$asrJurisprudence';

    // Fast Load from Cache if available
    if (_prayerCache.containsKey(cacheKey)) {
      prayerTimes = _prayerCache[cacheKey];
      currentCity = cityEng;
      currentCountry = countryEng;
      isLoading = false;
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      final uri = Uri.https('api.aladhan.com', '/v1/timingsByCity', {
        'city': cityEng,
        'country': countryEng,
        'method': calculationMethod.toString(),
        'school': asrJurisprudence.toString(),
      });

      final response = await http.get(uri).timeout(const Duration(milliseconds: 3500));

      if (response.statusCode == 200) {
        final parsed = PrayerTimesData.fromJson(json.decode(response.body));
        _prayerCache[cacheKey] = parsed;
        prayerTimes = parsed;
        currentCity = cityEng;
        currentCountry = countryEng;
      } else {
        _fallbackToLocalAdhan(cityEng);
      }
    } catch (_) {
      _fallbackToLocalAdhan(cityEng);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _fallbackToLocalAdhan(String city) {
    final coords = LocationService.getCoordinates(city);
    
    adhan_lib.CalculationParameters params;
    switch (calculationMethod) {
      case 7: // Tehran / Shia Jafari
        params = adhan_lib.CalculationMethod.tehran.getParameters();
        break;
      case 3: // MWL
        params = adhan_lib.CalculationMethod.muslim_world_league.getParameters();
        break;
      case 5: // Egyptian
        params = adhan_lib.CalculationMethod.egyptian.getParameters();
        break;
      case 1: // Karachi
        params = adhan_lib.CalculationMethod.karachi.getParameters();
        break;
      case 2: // ISNA
        params = adhan_lib.CalculationMethod.north_america.getParameters();
        break;
      case 4: // Umm Al Qura
      default:
        params = adhan_lib.CalculationMethod.umm_al_qura.getParameters();
        break;
    }

    if (asrJurisprudence == 1) {
      params.madhab = adhan_lib.Madhab.hanafi;
    } else {
      params.madhab = adhan_lib.Madhab.shafi;
    }

    final dateComponents = adhan_lib.DateComponents.from(DateTime.now());
    final times = adhan_lib.PrayerTimes(coords, dateComponents, params);
    
    final localData = PrayerTimesData.fromAdhanLib(times);
    prayerTimes = localData;
    currentCity = city;
  }

  void incrementTasbeeh() {
    tasbeehCounterNotifier.value++;
    HapticFeedback.selectionClick();
  }

  void resetTasbeeh() {
    tasbeehCounterNotifier.value = 0;
    HapticFeedback.mediumImpact();
  }

  void changeTasbeehPhrase(int index) {
    selectedTasbeehIndex = index;
    tasbeehCounterNotifier.value = 0;
    notifyListeners();
  }

  void incrementThikr(ThikrData thikr) {
    if (thikr.currentCount < thikr.targetCount) {
      thikr.currentCount++;
      if (thikr.currentCount == thikr.targetCount) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
      notifyListeners();
    }
  }

  void resetThikrCount(ThikrCategory category) {
    for (var thikr in category.athkar) {
      thikr.currentCount = 0;
    }
    notifyListeners();
  }
}

final AppRepository appRepository = AppRepository();

// ==========================================
// 5. MAIN APPLICATION UI
// ==========================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const IslamicPrayerAthkarApp());
}

class IslamicPrayerAthkarApp extends StatelessWidget {
  const IslamicPrayerAthkarApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryDark = Color(0xFF0D3B2E);
    const secondaryGold = Color(0xFFD4AF37);
    const bgLight = Color(0xFFF4F7F5);

    return MaterialApp(
      title: 'نور الإيمان',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryDark,
          primary: primaryDark,
          secondary: secondaryGold,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: bgLight,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = const [
    PrayerTimesScreen(),
    AthkarScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        elevation: 8,
        indicatorColor: const Color(0x330D3B2E),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.access_time_filled_rounded),
            label: 'مواقيت الصلاة',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_rounded),
            label: 'الأذكار والمسبحة',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_rounded),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 6. PRAYER TIMES SCREEN (OPTIMIZED)
// ==========================================

class PrayerTimesScreen extends StatelessWidget {
  const PrayerTimesScreen({super.key});

  void _showLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LocationSearchDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مواقيت الصلاة الدقيقة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on_rounded),
            onPressed: () => _showLocationDialog(context),
            tooltip: 'تغيير المدينة والدولة',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: appRepository,
        builder: (context, child) {
          if (appRepository.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D3B2E)),
            );
          }

          final data = appRepository.prayerTimes;
          if (data == null) {
            return const Center(child: Text('حدث خطأ في عرض المواقيت'));
          }

          return SafeArea(
            child: RefreshIndicator(
              onRefresh: () => appRepository.loadPrayerTimes(
                appRepository.currentCity,
                appRepository.currentCountry,
              ),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF072018),
                            Color(0xFF0D3B2E),
                            Color(0xFF165A47),
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x330D3B2E),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.mosque, color: Color(0xFFD4AF37), size: 50),
                          const SizedBox(height: 10),
                          Text(
                            '${appRepository.currentCityArabic} - ${appRepository.currentCountryArabic}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'التاريخ: ${data.date}',
                            style: const TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildPrayerRow('الفجر', data.fajr, Icons.nights_stay_outlined),
                    _buildPrayerRow('الشروق', data.sunrise, Icons.wb_sunny_outlined),
                    _buildPrayerRow('الظهر', data.dhuhr, Icons.wb_sunny_rounded),
                    _buildPrayerRow('العصر', data.asr, Icons.filter_drama_rounded),
                    _buildPrayerRow('المغرب', data.maghrib, Icons.wb_twilight_rounded),
                    _buildPrayerRow('العشاء', data.isha, Icons.bedtime_rounded),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrayerRow(String title, String time, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Color(0x1A0D3B2E),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF0D3B2E)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D3B2E),
          ),
        ),
        trailing: Text(
          time,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Color(0xFFC59B27),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 7. ATHKAR & MASBAHA SCREEN
// ==========================================

class AthkarScreen extends StatelessWidget {
  const AthkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأذكار والمسبحة الإلكترونية'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MasbahaDetailScreen(),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D3B2E), Color(0xFF1B5E4A)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x330D3B2E),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0x33D4AF37),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fingerprint_rounded,
                        size: 34,
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'المسبحة الإلكترونية الذكية',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'عداد تسبيح سلس مع اهتزاز تفاعلي',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFD4AF37),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 10, right: 4),
              child: Text(
                'أقسام الأذكار والأدعية الصحيحة',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D3B2E),
                ),
              ),
            ),
            ...List.generate(appRepository.athkarCategories.length, (index) {
              final category = appRepository.athkarCategories[index];
              return GestureDetector(
                onTap: () {
                  appRepository.resetThikrCount(category);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ThikrDetailScreen(category: category),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0D3B2E),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          category.icon,
                          size: 26,
                          color: const Color(0xFFD4AF37),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D3B2E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'عدد الأذكار: ${category.athkar.length}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Color(0xFFD4AF37),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class MasbahaDetailScreen extends StatefulWidget {
  const MasbahaDetailScreen({super.key});

  @override
  State<MasbahaDetailScreen> createState() => _MasbahaDetailScreenState();
}

class _MasbahaDetailScreenState extends State<MasbahaDetailScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTapCounter() {
    _animController.forward().then((_) => _animController.reverse());
    appRepository.incrementTasbeeh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المسبحة التفاعلية'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: appRepository.selectedTasbeehIndex,
                    isExpanded: true,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D3B2E),
                    ),
                    items: List.generate(
                      appRepository.tasbeehPhrases.length,
                      (index) => DropdownMenuItem(
                        value: index,
                        child: Text(appRepository.tasbeehPhrases[index]),
                      ),
                    ),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          appRepository.changeTasbeehPhrase(val);
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),

              GestureDetector(
                onTap: _onTapCounter,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0D3B2E),
                          Color(0xFF1B5E4A),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x4D0D3B2E),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFFD4AF37),
                        width: 4,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ValueListenableBuilder<int>(
                          valueListenable: appRepository.tasbeehCounterNotifier,
                          builder: (context, count, child) {
                            return Text(
                              '$count',
                              style: const TextStyle(
                                fontSize: 64,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD4AF37),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'اضغط للتسبيح',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  appRepository.resetTasbeeh();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('تصفير العداد', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 8. DETAIL & SETTINGS SCREENS
// ==========================================

class ThikrDetailScreen extends StatelessWidget {
  final ThikrCategory category;

  const ThikrDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category.title),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: appRepository,
          builder: (context, child) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: category.athkar.length,
              itemBuilder: (context, index) {
                final thikr = category.athkar[index];
                final isCompleted = thikr.currentCount >= thikr.targetCount;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isCompleted ? const Color(0x1A0D3B2E) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isCompleted ? const Color(0xFF0D3B2E) : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        thikr.text,
                        style: const TextStyle(
                          fontSize: 19,
                          height: 1.6,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0D3B2E),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'المصدر: ${thikr.reference}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'المطلوب: ${thikr.targetCount}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              appRepository.incrementThikr(thikr);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? const Color(0xFF0D3B2E)
                                    : const Color(0xFFD4AF37),
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x220D3B2E),
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(Icons.check, color: Colors.white, size: 30)
                                    : Text(
                                        '${thikr.currentCount}',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0D3B2E),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات والدقة'),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: appRepository,
          builder: (context, child) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader('طريقة حساب أوقات الصلاة (دقة عالية)'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: appRepository.calculationMethod,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 4, child: Text('جامعة أم القرى (مكة المكرمة)')),
                        DropdownMenuItem(value: 7, child: Text('جامعة طهران / المذهب الجعفري')),
                        DropdownMenuItem(value: 3, child: Text('رابطة العالم الإسلامي')),
                        DropdownMenuItem(value: 5, child: Text('الهيئة المصرية العامة للمساحة')),
                        DropdownMenuItem(value: 1, child: Text('جامعة العلوم الإسلامية بكراتشي')),
                        DropdownMenuItem(value: 2, child: Text('الجمعية الإسلامية لشمال أمريكا (ISNA)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          appRepository.calculationMethod = val;
                          appRepository.loadPrayerTimes(appRepository.currentCity, appRepository.currentCountry);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _buildSectionHeader('مذهب حساب وقت صلاة العصر'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: appRepository.asrJurisprudence,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('الجمهور (الشافعي، المالكي، الحنبلي، الجعفري)')),
                        DropdownMenuItem(value: 1, child: Text('المذهب الحنفي')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          appRepository.asrJurisprudence = val;
                          appRepository.loadPrayerTimes(appRepository.currentCity, appRepository.currentCountry);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _buildSectionHeader('الموقع الحالي المعتمد'),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.location_city, color: Color(0xFF0D3B2E)),
                        title: const Text('المدينة والدولة'),
                        subtitle: Text('${appRepository.currentCityArabic} - ${appRepository.currentCountryArabic}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_location_alt_rounded, color: Color(0xFFD4AF37)),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => const LocationSearchDialog(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0D3B2E),
        ),
      ),
    );
  }
}

// ==========================================
// 9. LOCATION SEARCH DIALOG (FULLY FIXED)
// ==========================================

class LocationSearchDialog extends StatefulWidget {
  const LocationSearchDialog({super.key});

  @override
  State<LocationSearchDialog> createState() => _LocationSearchDialogState();
}

class _LocationSearchDialogState extends State<LocationSearchDialog> {
  late TextEditingController _cityController;
  late TextEditingController _countryController;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: appRepository.currentCityArabic);
    _countryController = TextEditingController(text: appRepository.currentCountryArabic);
  }

  @override
  void dispose() {
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('تغيير الدولة والمدينة', textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _countryController,
              decoration: const InputDecoration(
                labelText: 'اسم الدولة (مثال: العراق، السعودية، Egypt)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.public),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'اسم المدينة (مثال: بغداد، النجف، القاهرة)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D3B2E),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final city = _cityController.text.trim();
            final country = _countryController.text.trim();
            if (city.isNotEmpty && country.isNotEmpty) {
              appRepository.loadPrayerTimes(city, country);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم تحديث الموقع إلى: $city - $country'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          child: const Text('تحديث المواقيت'),
        ),
      ],
    );
  }
}
