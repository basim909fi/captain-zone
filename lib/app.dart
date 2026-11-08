import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_screen.dart';
import 'screens/root_shell.dart';

class CaptainZoneApp extends StatelessWidget {
  const CaptainZoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'كشف الطلبات',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Thmanyah',
        textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Thmanyah'),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4AF37),
        ),
      ),
      home: const AppEntryGate(),
    );
  }
}

class AppEntryGate extends StatefulWidget {
  const AppEntryGate({super.key});

  @override
  State<AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<AppEntryGate> {
  bool _isLoading = true;
  bool _hasSeenOnboarding = false;
  bool _isDark = true;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('hasSeenOnboarding') ?? false;
    final isDark = prefs.getBool('isDarkMode') ?? true;

    if (mounted) {
      setState(() {
        _hasSeenOnboarding = hasSeen;
        _isDark = isDark;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF10141C),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFD4AF37),
          ),
        ),
      );
    }

    if (!_hasSeenOnboarding) {
      return OnboardingScreen(isDark: _isDark);
    }

    return const RootShell();
  }
}
