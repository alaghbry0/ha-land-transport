import '../models/place.dart';

/// مواقع الرياض المستخدمة في النموذج الأولي — إحداثيات OpenStreetMap حقيقية.
const List<Place> riyadhPlaces = [
  Place(
    id: 'kafc',
    name: 'مركز الملك عبدالله المالي (KAFD)',
    subtitle: 'الحي المالي — شمال الرياض',
    lat: 24.7633,
    lng: 46.6392,
    isQuickShortcut: true,
  ),
  Place(
    id: 'kkia',
    name: 'مطار الملك خالد الدولي',
    subtitle: 'المطار — الطريق الدائري الشمالي',
    lat: 24.9576,
    lng: 46.6988,
    isQuickShortcut: true,
  ),
  Place(
    id: 'boulevard',
    name: 'بوليفارد سيتي',
    subtitle: 'وجهة الترفيه — طريق خالد بن عبدالعزيز',
    lat: 24.7601,
    lng: 46.6185,
    isQuickShortcut: true,
  ),
  Place(
    id: 'olia',
    name: 'حي العليا',
    subtitle: 'قلب الرياض التجاري',
    lat: 24.6972,
    lng: 46.6853,
    isQuickShortcut: true,
  ),
  Place(
    id: 'kingdom-tower',
    name: 'برج المملكة',
    subtitle: 'العليا — طريق الملك فهد',
    lat: 24.7115,
    lng: 46.6745,
  ),
  Place(
    id: 'qasr-al-hokm',
    name: 'قصر الحكم',
    subtitle: 'وسط الرياض التاريخي',
    lat: 24.6306,
    lng: 46.7139,
  ),
  Place(
    id: 'diriyah',
    name: 'الدرعية — حي طيبة',
    subtitle: 'مواقع التراث العالمي',
    lat: 24.7370,
    lng: 46.5750,
  ),
  Place(
    id: 'panorama-mall',
    name: 'بانوراما مول',
    subtitle: 'طريق الملك عبدالله',
    lat: 24.6742,
    lng: 46.7251,
  ),
  Place(
    id: 'riyadh-front',
    name: 'الرياض فرونت',
    subtitle: 'المعارض والفعاليات — النرجس',
    lat: 24.8272,
    lng: 46.6521,
  ),
  Place(
    id: 'granada-mall',
    name: 'غرناطة مول',
    subtitle: 'طريق الملك فهد الشرقي',
    lat: 24.7753,
    lng: 46.7386,
  ),
];

/// المواقع التي تظهر كأزرار اختصار سريعة.
List<Place> get quickShortcuts =>
    riyadhPlaces.where((p) => p.isQuickShortcut).toList();

/// نقطة انطلاق افتراضية (العليا).
Place get defaultPickup => riyadhPlaces.firstWhere((p) => p.id == 'olia');

/// سعر الأساس لكل فئة (ر.س) + تعرفة لكل كيلومتر.
const Map<VehicleClass, double> baseFare = {
  VehicleClass.economy: 8.0,
  VehicleClass.family: 12.0,
  VehicleClass.vip: 20.0,
};

const Map<VehicleClass, double> perKmFare = {
  VehicleClass.economy: 1.85,
  VehicleClass.family: 2.4,
  VehicleClass.vip: 3.9,
};

/// حساب أجرة تقديرية للرحلة بالريال السعودي.
double estimateFare(VehicleClass vClass, double km) {
  final raw = baseFare[vClass]! + perKmFare[vClass]! * km;
  // تقريب للأعلى لأقرب نصف ريال
  return (raw * 2).ceilToDouble() / 2;
}

/// حساب وقت الوصول المتوقع بالدقائق (متوسط سرعة 32 كم/س داخل الرياض).
int estimateEtaMinutes(double km) => (km / 32 * 60).round().clamp(4, 120);
