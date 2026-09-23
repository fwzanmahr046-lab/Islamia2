import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart' hide TextDirection;

// ==========================================
// 1. DATA MODELS (نماذج البيانات)
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

  factory PrayerTimesData.fromJson(Map<String, dynamic> json) {
    final timings = json['data']['timings'];
    final date = json['data']['date']['readable'];
    return PrayerTimesData(
      fajr: _formatTo12Hour(timings['Fajr'] ?? ''),
      sunrise: _formatTo12Hour(timings['Sunrise'] ?? ''),
      dhuhr: _formatTo12Hour(timings['Dhuhr'] ?? ''),
      asr: _formatTo12Hour(timings['Asr'] ?? ''),
      maghrib: _formatTo12Hour(timings['Maghrib'] ?? ''),
      isha: _formatTo12Hour(timings['Isha'] ?? ''),
      date: date ?? '',
    );
  }

  factory PrayerTimesData.mock() {
    return PrayerTimesData(
      fajr: "4:30 ص",
      sunrise: "5:45 ص",
      dhuhr: "12:15 م",
      asr: "3:45 م",
      maghrib: "6:30 م",
      isha: "8:00 م",
      date: DateFormat('dd MMM yyyy').format(DateTime.now()),
    );
  }

  // تحويل الوقت من نظام 24 إلى نظام 12 ساعة مع (ص/م)
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
// 2. API & CLOUD SERVICE LAYER
// ==========================================

class IslamicApiService {
  static const String _baseUrl = 'https://api.aladhan.com/v1/timingsByCity';

  Future<PrayerTimesData> fetchPrayerTimes(String city, String country, int method) async {
    try {
      final uri = Uri.parse('$_baseUrl?city=$city&country=$country&method=$method');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return PrayerTimesData.fromJson(json.decode(response.body));
      } else {
        throw Exception('فشل في جلب البيانات من السيرفر');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال بالشبكة: $e');
    }
  }
}

// ==========================================
// 3. STATE MANAGEMENT REPOSITORY
// ==========================================

class AppRepository extends ChangeNotifier {
  final IslamicApiService _apiService = IslamicApiService();
  
  PrayerTimesData? prayerTimes;
  bool isLoading = true;
  String errorMessage = '';
  
  String currentCity = 'Baghdad';
  String currentCountry = 'Iraq';
  int calculationMethod = 4;

  // بيانات المسبحة
  int tasbeehCounter = 0;
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
        ThikrData(text: 'أصبحنا وأصبح الملك لله، والحمد لله، لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير.', targetCount: 1),
        ThikrData(text: 'اللهم بك أصبحنا، وبك أمسينا، وبك نحيا، وبك نموت، وإليك النشور.', targetCount: 1),
        ThikrData(text: 'آية الكرسي: اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ...', targetCount: 1),
        ThikrData(text: 'سورة الإخلاص والمعوذتين.', targetCount: 3),
        ThikrData(text: 'أصبحنا على فطرة الإسلام وعلى كلمة الإخلاص وعلى دين نبينا محمد صلى الله عليه وسلم.', targetCount: 1),
        ThikrData(text: 'رضيت بالله رباً، وبالإسلام ديناً، وبمحمد صلى الله عليه وسلم نبياً.', targetCount: 3),
        ThikrData(text: 'حسبي الله لا إله إلا هو عليه توكلت وهو رب العرش العظيم.', targetCount: 7),
        ThikrData(text: 'بسم الله الذي لا يضر مع اسمه شيء في الأرض ولا في السماء وهو السميع العليم.', targetCount: 3),
        ThikrData(text: 'سبحان الله وبحمده: عدد خلقه، ورضا نفسه، وزنة عرشه، ومداد كلماته.', targetCount: 3),
        ThikrData(text: 'يا حي يا قيوم برحمتك أستغيث أصلح لي شأني كله ولا تكلني إلى نفسي طرفة عين.', targetCount: 1),
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
        ThikrData(text: 'اللهم إني أسألك العفو والعافية في الدنيا والآخرة.', targetCount: 1),
        ThikrData(text: 'أستغفر الله وأتوب إليه.', targetCount: 100),
      ],
    ),
    ThikrCategory(
      title: 'أذكار الصلاة',
      icon: Icons.mosque_rounded,
      athkar: [
        ThikrData(text: 'أستغفر الله، أستغفر الله، أستغفر الله.', targetCount: 1),
        ThikrData(text: 'اللهم أنت السلام ومنك السلام، تباركت يا ذا الجلال والإكرام.', targetCount: 1),
        ThikrData(text: 'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير.', targetCount: 1),
        ThikrData(text: 'سبحان الله (33)، الحمد لله (33)، الله أكبر (33).', targetCount: 99),
        ThikrData(text: 'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير (تمام المائة).', targetCount: 1),
      ],
    ),
    ThikrCategory(
      title: 'أذكار النوم والاستيقاظ',
      icon: Icons.bedtime_rounded,
      athkar: [
        ThikrData(text: 'باسمك ربي وضعت جنبي، وبك أرفعه، فإن أمسكت نفسي فارحمها، وإن أرسلتها فاحفظها.', targetCount: 1),
        ThikrData(text: 'اللهم قني عذابك يوم تبعث عبادك.', targetCount: 3),
        ThikrData(text: 'الحمد لله الذي أحيانا بعد ما أماتنا وإليه النشور.', targetCount: 1),
      ],
    ),
    ThikrCategory(
      title: 'أدعية قرآنية ومأثورة',
      icon: Icons.menu_book_rounded,
      athkar: [
        ThikrData(text: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ.', targetCount: 1),
        ThikrData(text: 'رَبَّنَا لا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِنْ لَدُنْكَ رَحْمَةً إِنَّكَ أَنْتَ الْوَهَّابُ.', targetCount: 1),
        ThikrData(text: 'رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي.', targetCount: 1),
        ThikrData(text: 'اللهم إنك عفو كريم تحب العفو فاعفُ عني.', targetCount: 1),
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
      prayerTimes = await _apiService.fetchPrayerTimes(city, country, calculationMethod);
      currentCity = city;
      currentCountry = country;
    } catch (e) {
      prayerTimes = PrayerTimesData.mock();
      errorMessage = 'تعذر الاتصال بالشبكة، تم إدراج أوقات تقريبية.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setCalculationMethod(int method) {
    calculationMethod = method;
    loadPrayerTimes(currentCity, currentCountry);
  }

  void incrementTasbeeh() {
    tasbeehCounter++;
    notifyListeners();
  }

  void resetTasbeeh() {
    tasbeehCounter = 0;
    notifyListeners();
  }

  void changeTasbeehPhrase(int index) {
    selectedTasbeehIndex = index;
    tasbeehCounter = 0;
    notifyListeners();
  }

  void resetThikrCount(ThikrCategory category) {
    for (var thikr in category.athkar) {
      thikr.currentCount = 0;
    }
    notifyListeners();
  }

  void incrementThikr(ThikrData thikr) {
    if (thikr.currentCount < thikr.targetCount) {
      thikr.currentCount++;
      notifyListeners();
    }
  }
}

final AppRepository appRepository = AppRepository();

// ==========================================
// 4. MAIN APP ENTRY POINT
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
      title: 'صلاتي والأذكار',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryDark,
          primary: primaryDark,
          secondary: secondaryGold,
          surface: Colors.white, // تم حذف background وإصلاح التحذير نهائياً
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
// 5. MAIN NAVIGATION & SCREENS
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
      resizeToAvoidBottomInset: true,
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
        indicatorColor: const Color(0xFFD4AF37).withAlpha(60),
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

// ------------------------------------------
// SCREEN 1: مواقيت الصلاة (Prayer Times Screen)
// ------------------------------------------

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({Key? key}) : super(key: key);

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  void _showLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LocationSearchDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                    if (appRepository.errorMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade700),
                        ),
                        child: Text(
                          appRepository.errorMessage,
                          style: TextStyle(color: Colors.amber.shade900, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    
                    // بطاقة الموقع
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
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D3B2E).withAlpha(90),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.mosque, color: Color(0xFFD4AF37), size: 55),
                          const SizedBox(height: 12),
                          Text(
                            '${appRepository.currentCity} - ${appRepository.currentCountry}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D3B2E).withAlpha(20),
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

// ------------------------------------------
// SCREEN 2: الأذكار والأدعية والمسبحة (Athkar & Masbaha Screen)
// ------------------------------------------

class AthkarScreen extends StatelessWidget {
  const AthkarScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأذكار والمسبحة الإلكترونية'),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: appRepository,
          builder: (context, child) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // زر قسم المسبحة الإلكترونية (داخل قسم الأذكار)
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
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D3B2E).withAlpha(80),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withAlpha(40),
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
                                'انقر للبدء بالتسبيح والاستغفار',
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D3B2E),
                  ),
                  child: Text('أقسام الأذكار والأدعية'),
                ),

                // قائمة الأقسام للأذكار
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(12),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
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
            );
          },
        ),
      ),
    );
  }
}

// شاشة تفاصيل المسبحة تفاعلية (تم تضمينها داخل قسم الأذكار)
class MasbahaDetailScreen extends StatelessWidget {
  const MasbahaDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المسبحة التفاعلية'),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: appRepository,
          builder: (context, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(10),
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
                          if (val != null) appRepository.changeTasbeehPhrase(val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  GestureDetector(
                    onTap: () {
                      appRepository.incrementTasbeeh();
                      HapticFeedback.lightImpact();
                    },
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
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D3B2E).withAlpha(80),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
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
                          Text(
                            '${appRepository.tasbeehCounter}',
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD4AF37),
                            ),
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
                      HapticFeedback.mediumImpact();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('تصفير العداد', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

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
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isCompleted ? const Color(0xFF0D3B2E).withAlpha(25) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCompleted ? const Color(0xFF0D3B2E) : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
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
                              if (thikr.currentCount == thikr.targetCount) {
                                HapticFeedback.heavyImpact();
                              } else {
                                HapticFeedback.lightImpact();
                              }
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
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0D3B2E).withAlpha(51),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
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

// ------------------------------------------
// SCREEN 3: الإعدادات (Settings Screen)
// ------------------------------------------

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
                        if (val != null) appRepository.setCalculationMethod(val);
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
                        subtitle: Text('${appRepository.currentCity} - ${appRepository.currentCountry}'),
                      ),
                      const Divider(height: 1),
                      const ListTile(
                        leading: Icon(Icons.verified_user_rounded, color: Color(0xFF0D3B2E)),
                        title: Text('إصدار التطبيق'),
                        subtitle: Text('3.0.0 (النسخة الاحترافية)'),
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
                labelText: 'اسم الدولة',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.public),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'اسم المدينة أو القرية',
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
