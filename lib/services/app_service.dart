import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/places_data.dart';
import '../models/place.dart';
import '../models/ride.dart';

/// الوضع الحالي للتطبيق: راكب أو كابتن.
enum AppRole { passenger, captain }

extension AppRoleX on AppRole {
  String get label => this == AppRole.passenger ? 'وضع الراكب' : 'وضع الكابتن';
}

/// التطبيق كخدمة واحدة مشتركة (Singleton Mock Service) تزامن لحظياً
/// بين واجهة الراكب وواجهة الكابتن في نفس الجلسة.
///
/// كل تغيير يمر من هنا وينعكس فوراً على كل المستمعين عبر [notifyListeners].
class AppService extends ChangeNotifier {
  AppService._internal() {
    _seedCaptains();
  }

  static final AppService instance = AppService._internal();

  // ── الوضع والحساب ──────────────────────────────────────────────────────

  AppRole role = AppRole.passenger;

  /// الكابتن الذي سجّل دخوله (null = شاشة الدخول/التسجيل).
  Captain? currentCaptain;

  /// كابتن افتراضي جاهز للتجربة السريعة.
  late Captain demoCaptain;

  void switchRole(AppRole newRole) {
    if (role == newRole) return;
    role = newRole;
    notifyListeners();
  }

  void toggleRole() => switchRole(
      role == AppRole.passenger ? AppRole.captain : AppRole.passenger);

  // ── الرحلة النشطة ──────────────────────────────────────────────────────

  /// الطلب الحالي (إن وجد) — يشاركه الوضعان.
  Ride? activeRide;

  /// سجل رحلات اليوم المنجزة (للوحة أرباح الكابتن).
  final List<CompletedTrip> todayTrips = [];

  /// إشعار مؤقت للمستخدم (Snackbar عبر المستمعين).
  String? transientMessage;

  void _say(String msg) {
    transientMessage = msg;
  }

  // ── دورة الراكب ────────────────────────────────────────────────────────

  /// الراكب الافتراضي.
  String get passengerName => 'أبو فهد';

  /// إنشاء طلب رحلة جديد (يصبح مرئياً فوراً للكابتن).
  void requestRide({
    required Place pickup,
    required Place destination,
    required VehicleClass vehicleClass,
  }) {
    if (activeRide != null &&
        activeRide!.status != RideStatus.completed &&
        activeRide!.status != RideStatus.cancelled) {
      _say('لديك رحلة جارية بالفعل');
      notifyListeners();
      return;
    }
    final km = distanceKm(pickup.lat, pickup.lng, destination.lat, destination.lng);
    activeRide = Ride(
      id: 'HA-${DateTime.now().millisecondsSinceEpoch % 100000}',
      passengerName: passengerName,
      pickup: pickup,
      destination: destination,
      vehicleClass: vehicleClass,
      distanceKmValue: km,
      etaMinutes: estimateEtaMinutes(km),
      fare: estimateFare(vehicleClass, km),
      status: RideStatus.searching,
      createdAt: DateTime.now(),
    );
    _say('تم إرسال طلبك — جاري البحث عن كابتن قريب');
    notifyListeners();
  }

  /// إلغاء الرحلة من طرف الراكب.
  void cancelRideByPassenger() {
    if (activeRide == null) return;
    if (activeRide!.status == RideStatus.inProgress ||
        activeRide!.status == RideStatus.captainArrived) {
      _say('لا يمكن إلغاء الرحلة بعد بدئها — تواصل مع الكابتن');
      notifyListeners();
      return;
    }
    activeRide!.status = RideStatus.cancelled;
    _say('تم إلغاء الرحلة');
    notifyListeners();
  }

  /// تقييم الكابتن بعد الوصول.
  void rateCaptain(int stars) {
    if (activeRide == null || activeRide!.captain == null) return;
    activeRide!.rating = stars;
    final cap = activeRide!.captain!;
    // تحديث متوسط الكابتن بشكل مبسط
    cap.rating =
        ((cap.rating * cap.tripsCount + stars) / (cap.tripsCount + 1) * 10)
                .round() /
            10;
    cap.tripsCount += 1;
    _say('شكراً لتقييمك! $stars نجوم');
    notifyListeners();
  }

  /// إغلاق بطاقة الرحلة المنتهية والعودة لوضع الطلب الجديد.
  void dismissCompletedRide() {
    if (activeRide?.status == RideStatus.completed ||
        activeRide?.status == RideStatus.cancelled) {
      activeRide = null;
      notifyListeners();
    }
  }

  // ── دورة الكابتن ───────────────────────────────────────────────────────

  /// كل الكباتن المسجلين في النظام (للنموذج).
  final List<Captain> captains = [];

  void _seedCaptains() {
    demoCaptain = Captain(
      id: 'cap-demo',
      name: 'كابتن خالد الحربي',
      phone: '0551234567',
      vehicleClass: VehicleClass.economy,
      carModel: 'تويوتا كامري 2023',
      plateNumber: 'ب ط ح 4821',
      rating: 4.9,
      tripsCount: 1240,
    );
    captains.add(demoCaptain);
  }

  /// تسجيل دخول الكابتن الافتراضي (زر التجربة السريعة).
  void loginDemoCaptain() {
    currentCaptain = demoCaptain;
    currentCaptain!.isOnline = true;
    role = AppRole.captain;
    _say('أهلاً بعودتك، ${currentCaptain!.name}');
    notifyListeners();
  }

  /// تسجيل كابتن جديد.
  String? registerCaptain({
    required String name,
    required String phone,
    required VehicleClass vehicleClass,
    required String carModel,
    required String plateNumber,
  }) {
    if (name.trim().length < 3) return 'الاسم قصير جداً';
    final phoneOk = RegExp(r'^05\d{8}$').hasMatch(phone.trim());
    if (!phoneOk) return 'رقم الجوال يجب أن يبدأ بـ 05 ويكون 10 أرقام';
    if (carModel.trim().length < 3) return 'اكتب نوع المركبة';
    if (!RegExp(r'^[\u0600-\u06FF ]{2,}[\d\s]{1,}$').hasMatch(plateNumber)) {
      return 'رقم اللوحة غير صحيح — مثال: أ ب ج 1234';
    }
    final cap = Captain(
      id: 'cap-${DateTime.now().millisecondsSinceEpoch % 100000}',
      name: name.trim(),
      phone: phone.trim(),
      vehicleClass: vehicleClass,
      carModel: carModel.trim(),
      plateNumber: plateNumber.trim(),
      rating: 5.0,
      tripsCount: 0,
    );
    captains.add(cap);
    currentCaptain = cap;
    currentCaptain!.isOnline = true;
    role = AppRole.captain;
    _say('تم تسجيلك كابتن HA — بالتوفيق!');
    notifyListeners();
    return null;
  }

  void logoutCaptain() {
    currentCaptain?.isOnline = false;
    currentCaptain = null;
    notifyListeners();
  }

  /// تبديل حالة الاتصال (متاح / غير متاح).
  void toggleOnline() {
    final cap = currentCaptain;
    if (cap == null) return;
    cap.isOnline = !cap.isOnline;
    _say(cap.isOnline ? 'أنت الآن متاح لاستقبال الطلبات' : 'تم إيقاف استقبال الطلبات');
    notifyListeners();
  }

  /// الطلب الوارد الحالي للكابتن (يظهر فقط وهو بالبحث أو معروضاً).
  Ride? get incomingRide {
    final r = activeRide;
    if (r == null) return null;
    if (r.status == RideStatus.searching) return r;
    if (r.captain?.id == currentCaptain?.id &&
        r.status != RideStatus.completed &&
        r.status != RideStatus.cancelled) {
      return r;
    }
    return null;
  }

  /// قبول الطلب الوارد.
  void acceptRide() {
    final r = activeRide;
    final cap = currentCaptain;
    if (r == null || cap == null || r.status != RideStatus.searching) return;
    r.captain = cap;
    r.status = RideStatus.captainOnTheWay;
    _say('قبلت الطلب — توجه لموقع العميل');
    notifyListeners();
  }

  /// رفض الطلب الوارد (يبقى الطلب بالبحث ليكابتن آخر — في النموذج يعود متاحاً).
  void rejectRide() {
    final r = activeRide;
    if (r == null || r.status != RideStatus.searching) return;
    _say('تم رفض الطلب — سيظهر لك طلب آخر قريباً');
    // في النموذج الأولي: الطلب يبقى حياً للراكب (كأن كابتن آخر لم يقبل بعد)
    notifyListeners();
  }

  /// وصلت لموقع العميل.
  void markArrived() {
    final r = _myActiveRide;
    if (r == null || r.status != RideStatus.captainOnTheWay) return;
    r.status = RideStatus.captainArrived;
    _say('وصلت لموقع العميل — بانتظار الركوب');
    notifyListeners();
  }

  /// بدء الرحلة.
  void startRide() {
    final r = _myActiveRide;
    if (r == null || r.status != RideStatus.captainArrived) return;
    r.status = RideStatus.inProgress;
    _say('بدأت الرحلة — بالتوفيق!');
    notifyListeners();
  }

  /// إنهاء الرحلة وتحصيل المبلغ.
  void completeRide(PaymentMethod method) {
    final r = _myActiveRide;
    if (r == null || r.status != RideStatus.inProgress) return;
    r.status = RideStatus.completed;
    r.paymentMethod = method;
    todayTrips.add(CompletedTrip(
      rideId: r.id,
      passengerName: r.passengerName,
      destinationName: r.destination.name,
      fare: r.fare,
      completedAt: DateTime.now(),
    ));
    _say('تمت الرحلة وحُصّل ${r.fare.toStringAsFixed(2)} ر.س (${method.label})');
    notifyListeners();
  }

  Ride? get _myActiveRide {
    final r = activeRide;
    if (r == null) return null;
    if (r.captain?.id == currentCaptain?.id &&
        r.status != RideStatus.completed &&
        r.status != RideStatus.cancelled) {
      return r;
    }
    return null;
  }

  // ── إحصاءات الكابتن ────────────────────────────────────────────────────

  double get todayEarnings =>
      todayTrips.fold(0.0, (sum, t) => sum + t.fare);

  int get todayTripsCount => todayTrips.length;

  // ── رسائل مؤقتة ────────────────────────────────────────────────────────

  /// استهلاك الرسالة المؤقتة (تستدعى بعد عرضها).
  void consumeMessage() {
    transientMessage = null;
  }

  /// بث رسالة مؤقتة لكل المستمعين.
  void showMessage(String msg) {
    _say(msg);
    notifyListeners();
  }
}

/// مزامنة دائمة للرسائل المؤقتة — تستخدمه الشاشات لعرض SnackBar.
final StreamController<String> messageStream =
    StreamController<String>.broadcast();

/// مساعد تنسيق السعر بالريال السعودي.
String sar(num value) =>
    '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2)} ر.س';
