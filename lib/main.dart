import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart' hide TextDirection; // تم منع التعارض بإضافة hide TextDirection

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
      fajr: timings['Fajr'] ?? '',
      sunrise: timings['Sunrise'] ?? '',
      dhuhr: timings['Dhuhr'] ?? '',
      asr: timings['Asr'] ?? '',
      maghrib: timings['Maghrib'] ?? '',
      isha: timings['Isha'] ?? '',
      date: date ?? '',
    );
  }

  factory PrayerTimesData.mock() {
    return PrayerTimesData(
      fajr: "04:30",
      sunrise: "05:45",
      dhuhr: "12:15",
      asr: "15:45",
      maghrib: "18:30",
      isha: "20:00",
      date: DateFormat('dd MMM yyyy').format(DateTime.now()),
    );
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
// 2. API & CLOUD SERVICE LAYER (طبقة الاتصال السحابي)
// ==========================================

class IslamicApiService {
  static const String _baseUrl = 'https://api.aladhan.com/v1/timingsByCity';

  Future<PrayerTimesData> fetchPrayerTimes(String city, String country) async {
    try {
      final uri = Uri.parse('$_baseUrl?city=$city&country=$country&method=8');
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
// 3. STATE MANAGEMENT REPOSITORY (إدارة الحالة)
// ==========================================

class AppRepository extends ChangeNotifier {
  final IslamicApiService _apiService = IslamicApiService();
  
  PrayerTimesData? prayerTimes;
  bool isLoading = true;
  String errorMessage = '';
  
  String currentCity = 'Baghdad';
  String currentCountry = 'Iraq';

  final List<ThikrCategory> athkarCategories = [
    ThikrCategory(
      title: 'أذكار الصباح',
      icon: Icons.wb_sunny_rounded,
      athkar: [
        ThikrData(text: 'أصبحنا وأصبح الملك لله، والحمد لله، لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير.', targetCount: 1),
        ThikrData(text: 'اللهم بك أصبحنا، وبك أمسينا، وبك نحيا، وبك نموت، وإليك النشور.', targetCount: 1),
        ThikrData(text: 'آية الكرسي: اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ...', targetCount: 1),
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
        ThikrData(text: 'أمسينا على فطرة الإسلام وعلى كلمة الإخلاص وعلى دين نبينا محمد صلى الله عليه وسلم.', targetCount: 1),
        ThikrData(text: 'أعوذ بكلمات الله التامات من شر ما خلق.', targetCount: 3),
        ThikrData(text: 'أستغفر الله وأتوب إليه.', targetCount: 100),
      ],
    ),
    ThikrCategory(
      title: 'أذكار الصلاة',
      icon: Icons.mosque_rounded,
      athkar: [
        ThikrData(text: 'أستغفر الله.', targetCount: 3),
        ThikrData(text: 'اللهم أنت السلام ومنك السلام، تباركت يا ذا الجلال والإكرام.', targetCount: 1),
        ThikrData(text: 'سبحان الله (33)، الحمد لله (33)، الله أكبر (33).', targetCount: 99),
        ThikrData(text: 'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير.', targetCount: 1),
      ],
    ),
    ThikrCategory(
      title: 'أذكار النوم',
      icon: Icons.bedtime_rounded,
      athkar: [
        ThikrData(text: 'باسمك ربي وضعت جنبي، وبك أرفعه، فإن أمسكت نفسي فارحمها، وإن أرسلتها فاحفظها.', targetCount: 1),
        ThikrData(text: 'اللهم قني عذابك يوم تبعث عبادك.', targetCount: 3),
        ThikrData(text: 'سورة الإخلاص والمعوذتين.', targetCount: 3),
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
      prayerTimes = await _apiService.fetchPrayerTimes(city, country);
      currentCity = city;
      currentCountry = country;
    } catch (e) {
      prayerTimes = PrayerTimesData.mock();
      errorMessage = 'تعذر الاتصال بالموقع، تم تحميل التوقيت التقريبي. يمكنك المحاولة لاحقاً.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
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
    return MaterialApp(
      title: 'صلاتي والأذكار',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B4332),
          primary: const Color(0xFF1B4332),
          secondary: const Color(0xFFD8F3DC),
          tertiary: const Color(0xFFE9C46A),
          surface: Colors.white, // استبدال background بالخاصية الحديثة surface
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFF1B4332),
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
          textDirection: TextDirection.rtl, // تعمل الآن بدون تعارض
          child: child!,
        );
      },
      home: const MainNavigationScreen(),
    );
  }
}

// ==========================================
// 5. UI SCREENS & COMPONENTS
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
        indicatorColor: Theme.of(context).colorScheme.secondary,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.access_time_filled_rounded),
            label: 'مواقيت الصلاة',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_rounded),
            label: 'الأذكار والدعاء',
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
            tooltip: 'تغيير الدولة والمدينة',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: appRepository,
        builder: (context, child) {
          if (appRepository.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B4332)),
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
                    
                    // بطاقة عنوان الموقع والحالة
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF1B4332),
                            Color(0xFF2D6A4F),
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1B4332).withAlpha(77), // استبدال withOpacity بـ withAlpha
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.mosque, color: Color(0xFFE9C46A), size: 50),
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
                              color: Color(0xFFD8F3DC),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // قائمة أوقات الصلوات
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10), // استبدال withOpacity بـ withAlpha
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Color(0xFFD8F3DC),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF1B4332)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B4332),
          ),
        ),
        trailing: Text(
          time,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D6A4F),
          ),
        ),
      ),
    );
  }
}

// نافذة البحث عن الدولة والمدينة
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
      title: const Text('اختيار الدولة والمدينة', textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _countryController,
              decoration: const InputDecoration(
                labelText: 'اسم الدولة (بالإنجليزية/عربي)',
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
            backgroundColor: const Color(0xFF1B4332),
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
          child: const Text('تحديث والتأكيد'),
        ),
      ],
    );
  }
}

// ------------------------------------------
// SCREEN 2: الأذكار والسبحة (Athkar Screen)
// ------------------------------------------

class AthkarScreen extends StatelessWidget {
  const AthkarScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حصن المسلم والأذكار'),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: appRepository,
          builder: (context, child) {
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.95,
              ),
              itemCount: appRepository.athkarCategories.length,
              itemBuilder: (context, index) {
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
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(13), // استبدال withOpacity بـ withAlpha
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD8F3DC),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            category.icon,
                            size: 42,
                            color: const Color(0xFF1B4332),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          category.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B4332),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
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
                    color: isCompleted ? const Color(0xFFD8F3DC) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCompleted ? const Color(0xFF1B4332) : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13), // استبدال withOpacity بـ withAlpha
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
                          color: Color(0xFF1B4332),
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
                                    ? const Color(0xFF1B4332)
                                    : const Color(0xFFE9C46A),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1B4332).withAlpha(51), // استبدال withOpacity بـ withAlpha
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
                                          color: Color(0xFF1B4332),
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
