import 'package:flutter/material.dart';

import '../../../models/place.dart';
import '../../../services/app_service.dart';
import '../../../theme/ha_theme.dart';
import '../../../widgets/ui_kit.dart';

/// شاشة دخول/تسجيل الكابتن — دخول سريع بحساب افتراضي أو تسجيل جديد.
class CaptainLoginScreen extends StatefulWidget {
  const CaptainLoginScreen({super.key});

  @override
  State<CaptainLoginScreen> createState() => _CaptainLoginScreenState();
}

class _CaptainLoginScreenState extends State<CaptainLoginScreen> {
  final AppService _service = AppService.instance;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _carCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  VehicleClass _vehicleClass = VehicleClass.economy;
  bool _showRegister = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _carCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: HaColors.navy,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const HaLogo(size: 64),
                const SizedBox(height: 14),
                const Text(
                  'HA للنقل البري',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'بوابة الكابتن — سجّل وانطلق معنا',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontSize: 13.5,
                    color: HaColors.slate300,
                  ),
                ),
                const SizedBox(height: 24),
                // بطاقة الدخول
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: !_showRegister
                      ? _buildQuickLogin(context)
                      : _buildRegisterForm(context),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickLogin(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'دخول الكباتن',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'IBM Plex Sans Arabic',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: HaColors.navy,
          ),
        ),
        const SizedBox(height: 18),
        // كابتن افتراضي للتجربة السريعة
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: HaColors.slate50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: HaColors.slate200),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [HaColors.navy, HaColors.navySoft],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Center(
                  child: Icon(Icons.local_taxi,
                      size: 24, color: HaColors.emerald),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'كابتن خالد الحربي',
                      style: TextStyle(
                        fontFamily: 'IBM Plex Sans Arabic',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: HaColors.navy,
                      ),
                    ),
                    Text(
                      'كامري 2023 · لوحة: ب ط ح 4821 · 4.9 ★',
                      style: TextStyle(
                        fontFamily: 'IBM Plex Sans Arabic',
                        fontSize: 11.5,
                        color: HaColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _service.loginDemoCaptain,
          icon: const Icon(Icons.bolt, size: 20),
          label: const Text('دخول سريع — حساب تجريبي'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => setState(() => _showRegister = true),
          icon: const Icon(Icons.person_add_alt_outlined, size: 19),
          label: const Text('تسجيل كابتن جديد'),
        ),
      ],
    );
  }

  Widget _buildRegisterForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'تسجيل كابتن جديد',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'IBM Plex Sans Arabic',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: HaColors.navy,
            ),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              hintText: 'الاسم الكامل',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: 'رقم الجوال — 05xxxxxxxx',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _carCtrl,
            decoration: const InputDecoration(
              hintText: 'نوع المركبة — مثال: تويوتا كامري',
              prefixIcon: Icon(Icons.directions_car_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _plateCtrl,
            decoration: const InputDecoration(
              hintText: 'رقم اللوحة — مثال: أ ب ج 1234',
              prefixIcon: Icon(Icons.pin_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 14),
          // فئة المركبة
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'فئة الخدمة',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans Arabic',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: HaColors.slate600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final v in VehicleClass.values) ...[
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _vehicleClass = v),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _vehicleClass == v
                                ? HaColors.emeraldLight
                                : HaColors.slate100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _vehicleClass == v
                                  ? HaColors.emerald
                                  : HaColors.slate200,
                              width: _vehicleClass == v ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                v.icon,
                                size: 22,
                                color: _vehicleClass == v
                                    ? HaColors.emeraldDark
                                    : HaColors.slate500,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                v.label,
                                style: TextStyle(
                                  fontFamily: 'IBM Plex Sans Arabic',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _vehicleClass == v
                                      ? HaColors.emeraldDark
                                      : HaColors.navy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (v != VehicleClass.vip) const SizedBox(width: 8),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _submitRegister,
            icon: const Icon(Icons.check_circle_outline, size: 20),
            label: const Text('إنشاء الحساب والانطلاق'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => setState(() => _showRegister = false),
            child: const Text(
              'العودة للدخول السريع',
              style: TextStyle(color: HaColors.slate500),
            ),
          ),
        ],
      ),
    );
  }

  void _submitRegister() {
    final error = _service.registerCaptain(
      name: _nameCtrl.text,
      phone: _phoneCtrl.text,
      carModel: _carCtrl.text,
      plateNumber: _plateCtrl.text,
      vehicleClass: _vehicleClass,
    );
    if (error != null && mounted) {
      _service.showMessage(error);
    }
  }
}
