import 'package:flutter/material.dart';

/// نقطة جغرافية مع اسم عرض بالعربية.
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.lat,
    required this.lng,
    this.isQuickShortcut = false,
  });

  final String id;
  final String name;
  final String subtitle;
  final double lat;
  final double lng;

  /// هل تظهر ضمن أزرار الاختصار السريعة في بطاقة تحديد الوجهة؟
  final bool isQuickShortcut;
}

/// فئات المركبات المتاحة في التطبيق.
enum VehicleClass { economy, family, vip }

extension VehicleClassX on VehicleClass {
  String get label {
    switch (this) {
      case VehicleClass.economy:
        return 'اقتصادي';
      case VehicleClass.family:
        return 'عائلي';
      case VehicleClass.vip:
        return 'VIP';
    }
  }

  String get subtitle {
    switch (this) {
      case VehicleClass.economy:
        return 'سيارة سيدان مريحة';
      case VehicleClass.family:
        return 'دفع رباعي — حتى 6 ركاب';
      case VehicleClass.vip:
        return 'سيارات فخمة مع سائق محترف';
    }
  }

  IconData get icon {
    switch (this) {
      case VehicleClass.economy:
        return Icons.directions_car;
      case VehicleClass.family:
        return Icons.airport_shuttle;
      case VehicleClass.vip:
        return Icons.stars;
    }
  }

  /// اسم مركبة افتراضي يظهر للكابتن.
  String get sampleCar {
    switch (this) {
      case VehicleClass.economy:
        return 'تويوتا كامري';
      case VehicleClass.family:
        return 'هيونداي H1';
      case VehicleClass.vip:
        return 'لكزس ES';
    }
  }
}

/// حساب دالة Haversine للمسافة بين نقطتين بالكيلومترات.
double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = _rad(lat2 - lat1);
  final dLng = _rad(lng2 - lng1);
  final a = _sq(_sin(dLat / 2)) +
      _cos(_rad(lat1)) * _cos(_rad(lat2)) * _sq(_sin(dLng / 2));
  return 2 * r * _asin(_sqrt(a));
}

double _rad(double d) => d * 3.141592653589793 / 180.0;
double _sq(double x) => x * x;
double _sin(double x) => x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
double _cos(double x) => 1 - (x * x) / 2 + (x * x * x * x) / 24;
double _asin(double x) => x + (x * x * x) / 6 + (3 * x * x * x * x * x) / 40;
double _sqrt(double x) => x <= 0 ? 0 : _sqrtIter(x, x / 2);
double _sqrtIter(double x, double g) {
  final n = (g + x / g) / 2;
  return (g - n).abs() < 1e-12 ? n : _sqrtIter(x, n);
}
