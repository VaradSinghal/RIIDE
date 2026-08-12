import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/boost_screen.dart';
import 'screens/insurance_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/splash_screen.dart';
import 'dart:async';
import 'data/mock_data.dart';
import 'services/notification_service.dart';
import 'models/notification_model.dart';
import 'services/supabase_service.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase backend connection
  await SupabaseService.initialize();

  // Initialize Notification Service
  NotificationService();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const GigKavachApp());
}

class GigKavachApp extends StatefulWidget {
  const GigKavachApp({super.key});

  @override
  State<GigKavachApp> createState() => _GigKavachAppState();
}

class _GigKavachAppState extends State<GigKavachApp> {
  bool _isRegistered = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GigKavach',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: SplashScreen(
        nextScreen: _isRegistered ? const MainNavigationShell() : LandingScreen(
          onRegistrationComplete: (ctx) {
            setState(() {
              _isRegistered = true;
              MockData.isRegistered = true;
            });
            Navigator.of(ctx).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainNavigationShell()),
            );
          },
        ),
      ),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 0;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _startNotificationPolling();
  }

  void _startNotificationPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final notifications = await GigKavachApiService.getNotifications();
      if (!mounted) return;
      for (final notif in notifications) {
        final String id = notif['id'];
        
        // Add to global service
        final typeStr = notif['type'] as String? ?? 'info';
        final type = typeStr == 'geo_risk' 
            ? NotificationType.risk 
            : typeStr == 'claim_update' 
                ? NotificationType.payout 
                : NotificationType.info;

        final service = NotificationService();
        final isNew = !service.notifications.any((n) => n.id == id);
        
        if (isNew) {
          service.addNotification(
            id: id,
            title: notif['title'] ?? 'Updated',
            message: notif['message'] ?? '',
            type: type,
          );
          _showNotificationSnackbar(notif);
        }
      }
    });
  }

  void _showNotificationSnackbar(dynamic notif) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notif['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(notif['message'] ?? '', style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: notif['type'] == 'geo_risk' ? AppColors.danger : AppColors.success,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  final List<Widget> _screens = const [
    DashboardScreen(),
    BoostScreen(),
    InsuranceScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          border: Border(
            top: BorderSide(
              color: AppColors.textMuted.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_rounded, 'Home'),
                _buildNavItem(1, Icons.rocket_launch_rounded, 'Boost'),
                _buildNavItem(2, Icons.shield_rounded, 'Insurance'),
                _buildNavItem(
                  3,
                  Icons.account_balance_wallet_rounded,
                  'Wallet',
                ),
                _buildNavItem(4, Icons.person_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
