import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_data.dart';
import '../theme/app_colors.dart';
import '../theme/palette.dart';
import '../widgets/glass_input_decoration.dart';
import 'root_shell.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isDark;

  const OnboardingScreen({
    super.key,
    required this.isDark,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController _priceController = TextEditingController(
    text: SettingsData.orderPrice.toString(),
  );
  final TextEditingController _targetController = TextEditingController(
    text: SettingsData.dailyTarget.toString(),
  );
  final TextEditingController _rentController = TextEditingController(
    text: SettingsData.monthlyRent.toString(),
  );

  Palette get palette => Palette(widget.isDark);

  @override
  void dispose() {
    _pageController.dispose();
    _priceController.dispose();
    _targetController.dispose();
    _rentController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final orderPrice = double.tryParse(_priceController.text.trim()) ?? 10.0;
    final dailyTarget = int.tryParse(_targetController.text.trim()) ?? 16;
    final monthlyRent = double.tryParse(_rentController.text.trim()) ?? 0.0;

    SettingsData.orderPrice = orderPrice;
    SettingsData.dailyTarget = dailyTarget;
    SettingsData.monthlyRent = monthlyRent;
    await SettingsData.save();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RootShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = palette;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: p.bgGradient,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextButton(
                      onPressed: _finishOnboarding,
                      child: Text(
                        'تخطي',
                        style: TextStyle(
                          color: p.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      _buildPage(
                        icon: Icons.delivery_dining,
                        title: 'أهلاً بك في كشف الطلبات',
                        subtitle:
                            'شريكك اليومي في إدارة مشاويرك وتوصيلاتك بكل سهولة وبدون تعقيد.',
                        palette: p,
                      ),
                      _buildPage(
                        icon: Icons.account_balance_wallet,
                        title: 'احسب أرباحك ومصاريفك بدقة',
                        subtitle:
                            'سجل بنزين الشركة وبنزين جيبك وإيجار السيارة، واعرف صافي دخلك الحقيقي في نهاية كل شهر.',
                        palette: p,
                      ),
                      _buildPage(
                        icon: Icons.analytics,
                        title: 'تقارير مالية احترافية',
                        subtitle:
                            'احصل على رسوم بيانية وتوقعات ذكية وصورة إنفوجرافيك كاملة جاهزة للمشاركة بنقرة واحدة.',
                        palette: p,
                      ),
                      _buildSetupPage(p),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 20.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(4, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 8,
                            width: _currentPage == index ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? p.gold
                                  : p.cardBorder,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      if (_currentPage < 3)
                        ElevatedButton.icon(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('التالي'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: p.gold,
                            foregroundColor: p.isDark
                                ? const Color(0xFF10141C)
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: _finishOnboarding,
                          icon: const Icon(Icons.check),
                          label: const Text('ابدأ الآن'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPage({
    required IconData icon,
    required String title,
    required String subtitle,
    required Palette palette,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: palette.gold.withValues(alpha: .15),
              shape: BoxShape.circle,
              border: Border.all(
                color: palette.gold.withValues(alpha: .4),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              size: 60,
              color: palette.gold,
            ),
          ),
          const SizedBox(height: 36),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupPage(Palette p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            'إعدادات سريعة للبدء',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'يمكنك تغيير هذه القيم بأي وقت من الإعدادات لاحقاً:',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: p.textPrimary),
            decoration: glassInputDecoration(p, 'سعر الطلب (ر.س)'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _targetController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: p.textPrimary),
            decoration: glassInputDecoration(p, 'التارجت اليومي للطلبات'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _rentController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: p.textPrimary),
            decoration: glassInputDecoration(
              p,
              'إيجار السيارة الشهري (إن وجد)',
            ),
          ),
        ],
      ),
    );
  }
}
