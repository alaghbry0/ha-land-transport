import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/captain/captain_shell.dart';
import 'screens/passenger/passenger_shell.dart';
import 'theme/ha_theme.dart';
import 'services/app_service.dart';
import 'widgets/sheets.dart';

/// جذر التطبيق — يفرض RTL العربية ويطبق ثيم HA ويستضيف مبدل الوضع.
class HaApp extends StatefulWidget {
  const HaApp({super.key});

  @override
  State<HaApp> createState() => _HaAppState();
}

class _HaAppState extends State<HaApp> {
  final AppService _service = AppService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (!mounted) return;
    final msg = _service.transientMessage;
    if (msg != null) {
      _service.consumeMessage();
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        return MaterialApp(
          title: 'HA للنقل البري',
          debugShowCheckedModeBanner: false,
          theme: buildHaTheme(),
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
          home: const _HomeShell(),
        );
      },
    );
  }
}

/// الهيكل الرئيسي: خريطة كاملة الشاشة خلفية + بطاقات سفلية + مبدل وضع علوي.
class _HomeShell extends StatelessWidget {
  const _HomeShell();

  @override
  Widget build(BuildContext context) {
    final service = AppService.instance;
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        return Scaffold(
          body: Stack(
            children: [
              // الخلفية: شاشة الوضع النشط (تحتوي الخريطة كاملة الشاشة)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(
                    scale: anim.drive(Tween<double>(begin: 0.97, end: 1.0)),
                    child: child,
                  ),
                ),
                child: service.role == AppRole.passenger
                    ? const PassengerShell(key: ValueKey('passenger'))
                    : service.currentCaptain == null
                        ? const CaptainLoginScreen(
                            key: ValueKey('captain-login'))
                        : CaptainShell(
                            key: ValueKey(
                                'captain-${service.currentCaptain!.id}')),
              ),

              // الشريط العلوي العائم: مبدل الوضع الفوري
              FloatingTopBar(
                child: Row(
                  children: [
                    const HaLogoBadge(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        service.role == AppRole.passenger
                            ? 'HA للنقل البري'
                            : 'HA — لوحة الكابتن',
                        style: const TextStyle(
                          fontFamily: 'IBM Plex Sans Arabic',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    RoleSwitcher(
                      current: service.role == AppRole.passenger
                          ? Role.passenger
                          : Role.captain,
                      onChanged: (role) => service.switchRole(
                        role == Role.passenger
                            ? AppRole.passenger
                            : AppRole.captain,
                      ),
                      badge: service.role != AppRole.captain &&
                              service.incomingRide != null
                          ? 1
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// شعار صغير داخل الشريط العلوي.
class HaLogoBadge extends StatelessWidget {
  const HaLogoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [HaColors.emerald, HaColors.emeraldDark],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Text(
          'HA',
          style: TextStyle(
            fontFamily: 'IBM Plex Sans Arabic',
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
