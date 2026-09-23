import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:adhan/adhan.dart' as adhan_lib;

// ==========================================
// 1. ARABIC TRANSLATION & LOCALE UTILS
// ==========================================

class ArabicTranslationService {
  static const Map<String, String> _translations = {
    'baghdad': 'بغداد',
    'iraq': 'العراق',
    'mecca': 'مكة المكرمة',
    'makkah': 'مكة المكرمة',
    'saudi arabia': 'المملكة العربية السعودية',
    'medina': 'المدينة المنورة',
    'cairo': 'القاهرة',
    'egypt': 'مصر',
    'riyadh': 'الرياض',
    'jeddah': 'جدة',
    'dubai': 'دبي',
    'uae': 'الإمارات العربية المتحدة',
    'united arab emirates': 'الإمارات العربية المتحدة',
    'damascus': 'دمشق',
    'syria': 'سوريا',
    'amman': 'عمان',
    'jordan': 'الأردن',
    'beirut': 'بيروت',
    'lebanon': 'لبنان',
    'kuwait': 'الكويت',
    'doha': 'الدوحة',
    'qatar': 'قطر',
    'muscat': 'مسقط',
    'oman': 'عُمان',
    'manama': 'المنامة',
    'bahrain': 'البحرين',
    'rabat': 'الرباط',
    'morocco': 'المغرب',
    'algiers': 'الجزائر',
    'tunis': 'تونس',
    'tripoli': 'طرابلس',
    'libya': 'ليبيا',
    'khartoum': 'الخرطوم',
    'sudan': 'السودان',
    'istanbul': 'إسطنبول',
    'turkey': 'تركيا',
  };

  static String toArabic(String text) {
    if (text.isEmpty) return text;
    final clean = text.trim().toLowerCase();
    return _translations[clean] ?? text;
  }

  static String formatArabicDate(DateTime date) {
    final months = [
      'يناير / كانون الثاني',
      'فبراير / شباط',
      'مارس / آذار',
      'أبريل / نيسان',
      'مايو / أيار',
      'يونيو / حزيران',
      'يوليو / تموز',
      'أغسطس / آب',
      'سبتمبر / أيلول',
      'أكتوبر / تشرين الأول',
      'نوفمبر / تشرين الثاني',
      'ديسمبر / كانون الأول'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} م';
  }
}

// ==========================================
// 2. DATA MODELS
// ==========================================

class PrayerTimesData {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String date;

  PrayerTimesData({
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
      date: ArabicTranslationService.formatArabicDate(DateTime.now()),
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
      date: ArabicTranslationService.formatArabicDate(DateTime.now()),
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

class ThikrData {
  final String text;
  final int targetCount;
  int currentCount;

  ThikrData({
    required this.text,
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
// 3. AUDIO & SOUND SERVICE
// ==========================================

class AudioService {
  static Future<void> playClickSound() async {
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }
}

// ==========================================
// 4. REPOSITORY STATE MANAGEMENT
// ==========================================

class AppRepository extends ChangeNotifier {
  PrayerTimesData? prayerTimes;
  bool isLoading = true;
  String errorMessage = '';

  String currentCity = 'Baghdad';
  String currentCountry = 'Iraq';

  String get currentCityArabic => ArabicTranslationService.toArabic(currentCity);
  String get currentCountryArabic => ArabicTranslationService.toArabic(currentCountry);

  int calculationMethod = 4;

  final ValueNotifier<int> tasbeehCounterNotifier = ValueNotifier<int>(0);
  int selectedTasbeehIndex = 0;

  final List<String> tasbeehPhrases = [
    'سبحان الله',
    'الحمد لله',
    'الله أكبر',
    'لا إله إلا الله',
    'أستغفر الله وأتوب إليه',
    'لا حول ولا قوة إلا بالله',
    'اللهم صلِّ وسلم على نبينا محمد',
  ];

  final List<ThikrCategory> athkarCategories = [
    ThikrCategory(
      title: 'أذكار الصباح',
      icon: Icons.wb_sunny_rounded,
      athkar: [
        ThikrData(text: 'أصبحنا وأصبح الملك لله، والحمد لله، لا إله إلا الله وحده لا شريك له.', targetCount: 1),
        ThikrData(text: 'اللهم بك أصبحنا، وبك أمسينا، وبك نحيا، وبك نموت، وإليك النشور.', targetCount: 1),
        ThikrData(text: 'آية الكرسي: اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ...', targetCount: 1),
        ThikrData(text: 'سورة الإخلاص والمعوذتين.', targetCount: 3),
        ThikrData(text: 'رضيت بالله رباً، وبالإسلام ديناً، وبمحمد صلى الله عليه وسلم نبياً.', targetCount: 3),
        ThikrData(text: 'حسبي الله لا إله إلا هو عليه توكلت وهو رب العرش العظيم.', targetCount: 7),
        ThikrData(text: 'سبحان الله وبحمده.', targetCount: 100),
      ],
    ),
    ThikrCategory(
      title: 'أذكار المساء',
      icon: Icons.nights_stay_rounded,
      athkar: [
        ThikrData(text: 'أمسينـا وأمسـى المـلك لله والحمد لله، لا إله إلاّ اللّه وحدَه لا شريك له.', targetCount: 1),
        ThikrData(text: 'اللهم بك أمسينا، وبك أصبحنا، وبك نحيا، وبك نموت، وإليك المصير.', targetCount: 1),
        ThikrData(text: 'آية الكرسي: اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ...', targetCount: 1),
        ThikrData(text: 'سورة الإخلاص والمعوذتين.', targetCount: 3),
        ThikrData(text: 'أعوذ بكلمات الله التامات من شر ما خلق.', targetCount: 3),
        ThikrData(text: 'أستغفر الله وأتوب إليه.', targetCount: 100),
      ],
    ),
    ThikrCategory(
      title: 'أذكار الصلاة',
      icon: Icons.mosque_rounded,
      athkar: [
        ThikrData(text: 'أستغفر الله، أستغفر الله، أستغفر الله.', targetCount: 1),
        ThikrData(text: 'اللهم أنت السلام ومنك السلام، تباركت يا ذا الجلال والإكرام.', targetCount: 1),
        ThikrData(text: 'سبحان الله (33)، الحمد لله (33)، الله أكبر (33).', targetCount: 99),
      ],
    ),
  ];

  AppRepository() {
    loadPrayerTimes(currentCity, currentCountry);
  }

  Future<void> loadPrayerTimes(String city, String country) async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      final uri = Uri.parse('https://api.aladhan.com/v1/timingsByCity?city=$city&country=$country&method=$calculationMethod');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        prayerTimes = PrayerTimesData.fromJson(json.decode(response.body));
      } else {
        _fallbackToLocalAdhan();
      }
      currentCity = city;
      currentCountry = country;
    } catch (_) {
      _fallbackToLocalAdhan();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _fallbackToLocalAdhan() {
    final coordinates = adhan_lib.Coordinates(33.3152, 44.3661);
    final params = adhan_lib.CalculationMethod.muslim_world_league.getParameters();
    final dateComponents = adhan_lib.DateComponents.from(DateTime.now());
    final times = adhan_lib.PrayerTimes(coordinates, dateComponents, params);
    prayerTimes = PrayerTimesData.fromAdhanLib(times);
  }

  void incrementTasbeeh() {
    tasbeehCounterNotifier.value++;
    AudioService.playClickSound();
    HapticFeedback.lightImpact();
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
      AudioService.playClickSound();
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
// 5. MAIN ENTRY POINT
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
  const IslamicPrayerAthkarApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const primaryDark = Color(0xFF0D3B2E);
    const secondaryGold = Color(0xFFD4AF37);
    const bgLight = Color(0xFFF2F5F3);

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
            fontSize: 22,
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

// ==========================================
// 6. NAVIGATION & SCREENS
// ==========================================

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

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
        elevation: 10,
        indicatorColor: const Color(0x4D1B5E4A),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.access_time_filled_rounded),
            label: 'مواقيت الصلاة',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_rounded),
            label: 'الأذكار والمسبحة',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_rounded),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 7. PRAYER TIMES SCREEN
// ==========================================

class PrayerTimesScreen extends StatelessWidget {
  const PrayerTimesScreen({Key? key}) : super(key: key);

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
            icon: const Icon(Icons.edit_location_alt_rounded),
            onPressed: () => _showLocationDialog(context),
            tooltip: 'تغيير الموقع',
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
            return const Center(child: Text('حدث خطأ في عرض التوقيت'));
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
                      padding: const EdgeInsets.all(24),
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
                            color: Color(0x4D0D3B2E),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.mosque, color: Color(0xFFD4AF37), size: 55),
                          const SizedBox(height: 12),
                          Text(
                            '${appRepository.currentCityArabic} - ${appRepository.currentCountryArabic}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'التاريخ: ${data.date}',
                            style: const TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0x1A0D3B2E),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF0D3B2E)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D3B2E),
          ),
        ),
        trailing: Text(
          time,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFC59B27),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 8. INTERACTIVE MASBAHA SCREEN
// ==========================================

class AthkarScreen extends StatelessWidget {
  const AthkarScreen({Key? key}) : super(key: key);

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
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D3B2E), Color(0xFF1B5E4A)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4D0D3B2E),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Color(0x33D4AF37),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fingerprint_rounded,
                        size: 36,
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'المسبحة الإلكترونية التفاعلية',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'انقر للبدء بالتسبيح مع الصوت والاهتزاز',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFFD4AF37),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 12, right: 4),
              child: Text(
                'أقسام الأذكار والأدعية',
                style: TextStyle(
                  fontSize: 18,
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
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0D3B2E),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          category.icon,
                          size: 28,
                          color: const Color(0xFFD4AF37),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D3B2E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'عدد الأذكار: ${category.athkar.length}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Color(0xFFD4AF37),
                        size: 18,
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
  const MasbahaDetailScreen({Key? key}) : super(key: key);

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
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.93).animate(
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: appRepository.selectedTasbeehIndex,
                    isExpanded: true,
                    style: const TextStyle(
                      fontSize: 18,
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
              const SizedBox(height: 50),

              GestureDetector(
                onTap: _onTapCounter,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: RepaintBoundary(
                    child: Container(
                      width: 260,
                      height: 260,
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
                            color: Color(0x590D3B2E),
                            blurRadius: 25,
                            offset: Offset(0, 10),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFD4AF37),
                          width: 5,
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
                                  fontSize: 68,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD4AF37),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'اضغط للتسبيح',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),

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
// 9. THIKR DETAIL & SETTINGS SCREENS
// ==========================================

class ThikrDetailScreen extends StatelessWidget {
  final ThikrCategory category;

  const ThikrDetailScreen({Key? key, required this.category}) : super(key: key);

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
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isCompleted ? const Color(0x1A0D3B2E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCompleted ? const Color(0xFF0D3B2E) : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 8,
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
                          fontSize: 20,
                          height: 1.7,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0D3B2E),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'المطلوب: ${thikr.targetCount}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              appRepository.incrementThikr(thikr);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 65,
                              height: 65,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? const Color(0xFF0D3B2E)
                                    : const Color(0xFFD4AF37),
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x330D3B2E),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(Icons.check, color: Colors.white, size: 32)
                                    : Text(
                                        '${thikr.currentCount}',
                                        style: const TextStyle(
                                          fontSize: 24,
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
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات والخيارات'),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: appRepository,
          builder: (context, child) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader('طريقة حساب أوقات الصلاة'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: appRepository.calculationMethod,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 4, child: Text('رابطة العالم الإسلامي')),
                        DropdownMenuItem(value: 5, child: Text('أم القرى (مكة المكرمة)')),
                        DropdownMenuItem(value: 1, child: Text('جامعة العلوم الإسلامية بكراتشي')),
                        DropdownMenuItem(value: 3, child: Text('الهيئة المصرية العامة للمساحة')),
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

                _buildSectionHeader('معلومات التطبيق والموقع'),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.location_city, color: Color(0xFF0D3B2E)),
                        title: const Text('المدينة والدولة الحالية'),
                        subtitle: Text('${appRepository.currentCityArabic} - ${appRepository.currentCountryArabic}'),
                      ),
                      const Divider(height: 1),
                      const ListTile(
                        leading: Icon(Icons.verified_user_rounded, color: Color(0xFF0D3B2E)),
                        title: Text('إصدار التطبيق'),
                        subtitle: Text('3.0.0 (النسخة الاحترافية السريعة)'),
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

class LocationSearchDialog extends StatefulWidget {
  const LocationSearchDialog({Key? key}) : super(key: key);

  @override
  State<LocationSearchDialog> createState() => _LocationSearchDialogState();
}

class _LocationSearchDialogState extends State<LocationSearchDialog> {
  late TextEditingController _cityController;
  late TextEditingController _countryController;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: appRepository.currentCity);
    _countryController = TextEditingController(text: appRepository.currentCountry);
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
                labelText: 'اسم الدولة (مثال: Iraq أو العراق)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.public),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'اسم المدينة (مثال: Baghdad أو بغداد)',
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
            }
          },
          child: const Text('تحديث'),
        ),
      ],
    );
  }
}
