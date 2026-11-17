import 'package:flutter/material.dart';

import 'place.dart';

/// كابتن (سائق) في النظام.
class Captain {
  Captain({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicleClass,
    required this.carModel,
    required this.plateNumber,
    this.rating = 4.8,
    this.tripsCount = 320,
    this.isOnline = true,
  });

  final String id;
  final String name;
  final String phone;
  final VehicleClass vehicleClass;
  final String carModel;
  final String plateNumber;
  double rating;
  int tripsCount;
  bool isOnline;
}

/// مراحل دورة حياة الرحلة.
enum RideStatus {
  /// لا توجد رحلة نشطة.
  idle,

  /// الراكب أكد الطلب — جاري البحث عن كابتن.
  searching,

  /// كابتن قبل الطلب وهو في الطريق لموقع الراكب.
  captainOnTheWay,

  /// الكابتن وصل لموقع الراكب.
  captainArrived,

  /// الرحلة بدأت.
  inProgress,

  /// الرحلة انتهت — بانتظار التقييم والدفع.
  completed,

  /// الرحلة أُلغيت.
  cancelled,
}

extension RideStatusX on RideStatus {
  /// عنوان المرحلة كما يظهر للراكب.
  String get passengerLabel {
    switch (this) {
      case RideStatus.idle:
        return '';
      case RideStatus.searching:
        return 'جاري البحث عن كابتن';
      case RideStatus.captainOnTheWay:
        return 'الكابتن في الطريق إليك';
      case RideStatus.captainArrived:
        return 'وصل الكابتن لموقعك';
      case RideStatus.inProgress:
        return 'بدأت الرحلة — بالطريق لوجهتك';
      case RideStatus.completed:
        return 'وصلت لوجهتك';
      case RideStatus.cancelled:
        return 'أُلغيت الرحلة';
    }
  }

  /// عنوان المرحلة كما يظهر للكابتن.
  String get captainLabel {
    switch (this) {
      case RideStatus.idle:
        return '';
      case RideStatus.searching:
        return 'طلب جديد وارد';
      case RideStatus.captainOnTheWay:
        return 'في الطريق للعميل';
      case RideStatus.captainArrived:
        return 'وصلت لموقع العميل';
      case RideStatus.inProgress:
        return 'الرحلة جارية';
      case RideStatus.completed:
        return 'انتهت الرحلة';
      case RideStatus.cancelled:
        return 'أُلغيت الرحلة';
    }
  }

  /// أيقونة المرحلة.
  IconData get icon {
    switch (this) {
      case RideStatus.idle:
        return Icons.help_outline;
      case RideStatus.searching:
        return Icons.search;
      case RideStatus.captainOnTheWay:
        return Icons.directions_car;
      case RideStatus.captainArrived:
        return Icons.pin_drop;
      case RideStatus.inProgress:
        return Icons.route;
      case RideStatus.completed:
        return Icons.flag;
      case RideStatus.cancelled:
        return Icons.cancel;
    }
  }
}

/// طريقة الدفع عند إنهاء الرحلة.
enum PaymentMethod { cash, mada, applePay }

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'نقداً';
      case PaymentMethod.mada:
        return 'مدى';
      case PaymentMethod.applePay:
        return 'Apple Pay';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.cash:
        return Icons.payments_outlined;
      case PaymentMethod.mada:
        return Icons.credit_card;
      case PaymentMethod.applePay:
        return Icons.phone_iphone;
    }
  }
}

/// رحلة واحدة عبر دورة حياتها كاملة.
class Ride {
  Ride({
    required this.id,
    required this.passengerName,
    required this.pickup,
    required this.destination,
    required this.vehicleClass,
    required this.distanceKmValue,
    required this.etaMinutes,
    required this.fare,
    this.status = RideStatus.searching,
    this.captain,
    this.rating,
    this.paymentMethod,
    this.createdAt,
  });

  final String id;
  final String passengerName;
  final Place pickup;
  final Place destination;
  final VehicleClass vehicleClass;
  final double distanceKmValue;
  final int etaMinutes;
  final double fare;
  RideStatus status;
  Captain? captain;
  int? rating;
  PaymentMethod? paymentMethod;
  final DateTime? createdAt;
}

/// رحلة منجزة في سجل الكابتن.
class CompletedTrip {
  const CompletedTrip({
    required this.rideId,
    required this.passengerName,
    required this.destinationName,
    required this.fare,
    required this.completedAt,
    this.rating,
  });

  final String rideId;
  final String passengerName;
  final String destinationName;
  final double fare;
  final DateTime completedAt;
  final int? rating;
}
