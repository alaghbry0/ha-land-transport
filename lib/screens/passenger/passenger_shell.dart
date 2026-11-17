import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/places_data.dart';
import '../../../models/place.dart';
import '../../../models/ride.dart';
import '../../../services/app_service.dart';
import '../../../theme/ha_theme.dart';
import '../../../widgets/ha_map.dart';
import '../../../widgets/sheets.dart';
import '../../../widgets/ui_kit.dart';

/// شاشة الراكب: خريطة كاملة الشاشة + بطاقة سفلية بمراحل الطلب.
///
/// المراحل: تحديد النقاط ← اختيار الفئة ← تأكيد الطلب ← متابعة الحالة
/// ← التقييم.
class PassengerShell extends StatefulWidget {
  const PassengerShell({super.key});

  @override
  State<PassengerShell> createState() => _PassengerShellState();
}

class _PassengerShellState extends State<PassengerShell> {
  final AppService _service = AppService.instance;
  Place? _pickup;
  Place? _destination;
  VehicleClass _selectedClass = VehicleClass.economy;

  Place get _pickupOr => _pickup ?? defaultPickup;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        final ride = _service.activeRide;
        final hasActiveRide = ride != null &&
            ride.status != RideStatus.completed &&
            ride.status != RideStatus.cancelled;
        final showCompleted = ride != null &&
            (ride.status == RideStatus.completed ||
                ride.status == RideStatus.cancelled);

        return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // الخريطة كاملة الشاشة
                Positioned.fill(
                  child: _buildMap(ride),
                ),
                // البطاقة السفلية
                Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, anim) => SlideTransition(
                      position: Tween(
                        begin: const Offset(0, 0.08),
                        end: Offset.zero,
                      ).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: hasActiveRide
                        ? _RideTrackingCard(
                            key: ValueKey('tracking-${ride.id}-${ride.status}'),
                            ride: ride,
                          )
                        : showCompleted
                            ? _RideSummaryCard(
                                key: ValueKey('summary-${ride.id}'),
                                ride: ride,
                              )
                            : _BookingCard(
                                key: const ValueKey('booking'),
                                pickup: _pickupOr,
                                destination: _destination,
                                selectedClass: _selectedClass,
                                onPickupChanged: (p) =>
                                    setState(() => _pickup = p),
                                onDestinationChanged: (p) =>
                                    setState(() => _destination = p),
                                onClassChanged: (c) =>
                                    setState(() => _selectedClass = c),
                                onRequest: _requestRide,
                              ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMap(Ride? ride) {
    final markers = <({Place place, HaMarkerKind kind})>[];

    final hasRide = ride != null &&
        ride.status != RideStatus.completed &&
        ride.status != RideStatus.cancelled;

    if (hasRide) {
      markers.add((place: ride.pickup, kind: HaMarkerKind.pickup));
      markers.add((place: ride.destination, kind: HaMarkerKind.destination));
      if (ride.captain != null &&
          ride.status != RideStatus.inProgress) {
        // موقع سيارة الكابتن: قرب نقطة الانطلاق (محاكاة اقتراب)
        markers.add((
          place: Place(
            id: 'car',
            name: 'car',
            subtitle: '',
            lat: ride.pickup.lat + 0.008,
            lng: ride.pickup.lng + 0.006,
          ),
          kind: HaMarkerKind.car
        ));
      }
    } else {
      markers.add((place: _pickupOr, kind: HaMarkerKind.passengerHere));
      if (_destination != null) {
        markers.add((place: _destination!, kind: HaMarkerKind.destination));
      }
    }

    final polyline = <LatLng>[];
    if (hasRide && ride.status == RideStatus.inProgress) {
      polyline.addAll([
        LatLng(ride.pickup.lat, ride.pickup.lng),
        LatLng(ride.destination.lat, ride.destination.lng),
      ]);
    } else if (!hasRide && _destination != null) {
      polyline.addAll([
        LatLng(_pickupOr.lat, _pickupOr.lng),
        LatLng(_destination!.lat, _destination!.lng),
      ]);
    }

    final fitPoints = <LatLng>[];
    if (polyline.isNotEmpty) {
      fitPoints.addAll(polyline);
    } else if (hasRide) {
      fitPoints.addAll([
        LatLng(ride.pickup.lat, ride.pickup.lng),
        LatLng(ride.destination.lat, ride.destination.lng),
      ]);
    } else if (_destination != null) {
      fitPoints.addAll([
        LatLng(_pickupOr.lat, _pickupOr.lng),
        LatLng(_destination!.lat, _destination!.lng),
      ]);
    }

    return HaMap(
      markers: markers,
      polylinePoints: polyline,
      fitPoints: fitPoints,
      onTapPick: null,
    );
  }

  void _requestRide() {
    if (_destination == null) {
      _service.showMessage('اختر وجهتك أولاً');
      return;
    }
    if (_destination!.id == _pickupOr.id) {
      _service.showMessage('نقطة الانطلاق والوجهة متطابقتان');
      return;
    }
    _service.requestRide(
      pickup: _pickupOr,
      destination: _destination!,
      vehicleClass: _selectedClass,
    );
  }
}

/// بطاقة حجز رحلة جديدة: نقاط + اختصارات + فئات + زر الطلب.
class _BookingCard extends StatelessWidget {
  const _BookingCard({
    super.key,
    required this.pickup,
    required this.destination,
    required this.selectedClass,
    required this.onPickupChanged,
    required this.onDestinationChanged,
    required this.onClassChanged,
    required this.onRequest,
  });

  final Place pickup;
  final Place? destination;
  final VehicleClass selectedClass;
  final ValueChanged<Place> onPickupChanged;
  final ValueChanged<Place> onDestinationChanged;
  final ValueChanged<VehicleClass> onClassChanged;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final km = destination == null
        ? 0.0
        : distanceKm(pickup.lat, pickup.lng, destination!.lat, destination!.lng);
    final fare = destination == null ? 0.0 : estimateFare(selectedClass, km);
    final eta = destination == null ? 0 : estimateEtaMinutes(km);

    return HaBottomSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // نقطة الانطلاق
          _PointField(
            label: 'من — نقطة الانطلاق',
            icon: Icons.trip_origin,
            iconColor: HaColors.emerald,
            value: pickup.name,
            onTap: () => _openPlacePicker(context, isPickup: true),
          ),
          const SizedBox(height: 10),
          // الوجهة
          _PointField(
            label: 'إلى — الوجهة',
            icon: Icons.location_on,
            iconColor: HaColors.navy,
            value: destination?.name ?? 'إلى أين تريد الذهاب؟',
            hint: destination == null,
            onTap: () => _openPlacePicker(context, isPickup: false),
          ),
          const SizedBox(height: 12),
          // اختصارات سريعة
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final p in quickShortcuts)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: QuickChip(
                      label: _shortName(p.name),
                      icon: Icons.near_me,
                      selected: destination?.id == p.id,
                      onTap: () => onDestinationChanged(p),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // فئات المركبات
          Row(
            children: [
              for (final v in VehicleClass.values) ...[
                Expanded(
                  child: VehicleClassCard(
                    label: v.label,
                    subtitle: v.subtitle,
                    subtitle2: v.subtitle,
                    icon: v.icon,
                    price: destination == null
                        ? '—'
                        : '${fareFor(v, km).toStringAsFixed(0)} ر.س',
                    selected: selectedClass == v,
                    onTap: () => onClassChanged(v),
                  ),
                ),
                if (v != VehicleClass.vip) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 14),
          // ملخص الرحلة
          if (destination != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: HaColors.slate50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: HaColors.slate200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SummaryItem(
                    icon: Icons.route,
                    value: '${km.toStringAsFixed(1)} كم',
                    label: 'المسافة',
                  ),
                  Container(
                      width: 1, height: 26, color: HaColors.slate200),
                  _SummaryItem(
                    icon: Icons.schedule,
                    value: '$eta دقيقة',
                    label: 'الوقت المتوقع',
                  ),
                  Container(
                      width: 1, height: 26, color: HaColors.slate200),
                  _SummaryItem(
                    icon: Icons.payments_outlined,
                    value: '${fare.toStringAsFixed(fare == fare.roundToDouble() ? 0 : 2)} ر.س',
                    label: 'السعر التقديري',
                    highlight: true,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: destination == null ? null : onRequest,
            icon: const Icon(Icons.local_taxi, size: 20),
            label: Text(destination == null ? 'اختر وجهتك للبدء' : 'تأكيد الطلب'),
          ),
        ],
      ),
    );
  }

  String _shortName(String fullName) {
    if (fullName.contains('(')) {
      return fullName.split('(').first.trim();
    }
    if (fullName.contains('—')) {
      return fullName.split('—').first.trim();
    }
    return fullName;
  }

  double fareFor(VehicleClass v, double km) => estimateFare(v, km);

  void _openPlacePicker(BuildContext context, {required bool isPickup}) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (sheetContext, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: HaColors.slate300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isPickup ? 'اختر نقطة الانطلاق' : 'اختر وجهتك',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans Arabic',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: HaColors.navy,
              ),
            ),
            const SizedBox(height: 14),
            for (final p in riyadhPlaces)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PlaceTile(
                  place: p,
                  onTap: () {
                    if (isPickup) {
                      onPickupChanged(p);
                    } else {
                      onDestinationChanged(p);
                    }
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({required this.place, required this.onTap});

  final Place place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: HaColors.slate200),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: HaColors.emeraldLight,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.place,
                    size: 19, color: HaColors.emeraldDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(
                        fontFamily: 'IBM Plex Sans Arabic',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: HaColors.navy,
                      ),
                    ),
                    Text(
                      place.subtitle,
                      style: const TextStyle(
                        fontFamily: 'IBM Plex Sans Arabic',
                        fontSize: 11.5,
                        color: HaColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: HaColors.slate400),
            ],
          ),
        ),
      ),
    );
  }
}

/// حقل عرض نقطة (انطلاق/وجهة) قابل للنقر.
class _PointField extends StatelessWidget {
  const _PointField({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.onTap,
    this.hint = false,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final String value;
  final VoidCallback onTap;
  final bool hint;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: HaColors.slate100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'IBM Plex Sans Arabic',
                        fontSize: 10.5,
                        color: HaColors.slate500,
                      ),
                    ),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'IBM Plex Sans Arabic',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: hint ? HaColors.slate400 : HaColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.expand_more, color: HaColors.slate400),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.value,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 17,
            color: highlight ? HaColors.emeraldDark : HaColors.slate400),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'IBM Plex Sans Arabic',
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: highlight ? HaColors.emeraldDark : HaColors.navy,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'IBM Plex Sans Arabic',
            fontSize: 10,
            color: HaColors.slate500,
          ),
        ),
      ],
    );
  }
}

/// بطاقة متابعة الرحلة النشطة.
class _RideTrackingCard extends StatelessWidget {
  const _RideTrackingCard({super.key, required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final service = AppService.instance;
    final stepIndex = switch (ride.status) {
      RideStatus.searching => 0,
      RideStatus.captainOnTheWay => 1,
      RideStatus.captainArrived => 2,
      RideStatus.inProgress => 3,
      _ => 4,
    };

    return HaBottomSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // شريط الحالة الحالية
          Row(
            children: [
              if (ride.status == RideStatus.searching)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: HaColors.emerald,
                  ),
                )
              else
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: HaColors.emeraldLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    ride.status.icon,
                    size: 20,
                    color: HaColors.emeraldDark,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.status.passengerLabel,
                      style: const TextStyle(
                        fontFamily: 'IBM Plex Sans Arabic',
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: HaColors.navy,
                      ),
                    ),
                    Text(
                      '${ride.pickup.name} ← ${ride.destination.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'IBM Plex Sans Arabic',
                        fontSize: 11.5,
                        color: HaColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${ride.fare.toStringAsFixed(ride.fare == ride.fare.roundToDouble() ? 0 : 2)} ر.س',
                    style: const TextStyle(
                      fontFamily: 'IBM Plex Sans Arabic',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: HaColors.emeraldDark,
                    ),
                  ),
                  Text(
                    '${ride.vehicleClass.label} · ${ride.distanceKmValue.toStringAsFixed(1)} كم',
                    style: const TextStyle(
                      fontFamily: 'IBM Plex Sans Arabic',
                      fontSize: 11,
                      color: HaColors.slate500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // مؤشر المراحل
          RideProgressDots(
            steps: const ['بحث', 'في الطريق', 'وصل', 'الرحلة', 'الوصول'],
            current: stepIndex,
          ),
          const SizedBox(height: 12),
          // بطاقة الكابتن عند القبول
          if (ride.captain != null) ...[
            CaptainCard(
              name: ride.captain!.name,
              carModel: ride.captain!.carModel,
              plateNumber: ride.captain!.plateNumber,
              rating: ride.captain!.rating,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      service.showMessage('جاري الاتصال بالكابتن…');
                    },
                    icon: const Icon(Icons.phone_outlined, size: 18),
                    label: const Text('اتصال'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        service.cancelRideByPassenger(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: HaColors.red,
                      side: const BorderSide(color: HaColors.red, width: 1.2),
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('إلغاء'),
                  ),
                ),
              ],
            ),
          ],
          if (ride.status == RideStatus.searching) ...[
            const SizedBox(height: 2),
            Text(
              'نبحث عن أقرب كابتن ${ride.vehicleClass.label} حولك…',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans Arabic',
                fontSize: 12.5,
                color: HaColors.slate500,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => service.cancelRideByPassenger(),
              style: OutlinedButton.styleFrom(
                foregroundColor: HaColors.red,
                side: const BorderSide(color: HaColors.red, width: 1.2),
              ),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('إلغاء الطلب'),
            ),
          ],
        ],
      ),
    );
  }
}

/// بطاقة ملخص الرحلة المنتهية + التقييم.
class _RideSummaryCard extends StatefulWidget {
  const _RideSummaryCard({super.key, required this.ride});

  final Ride ride;

  @override
  State<_RideSummaryCard> createState() => _RideSummaryCardState();
}

class _RideSummaryCardState extends State<_RideSummaryCard> {
  final AppService _service = AppService.instance;
  int _stars = 0;

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final cancelled = ride.status == RideStatus.cancelled;

    return HaBottomSheet(
      child: cancelled
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.cancel_outlined,
                    size: 44, color: HaColors.red),
                const SizedBox(height: 8),
                const Text(
                  'أُلغيت الرحلة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: HaColors.navy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'يمكنك طلب رحلة جديدة في أي وقت',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontSize: 13,
                    color: HaColors.slate500,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _service.dismissCompletedRide,
                  child: const Text('طلب رحلة جديدة'),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: HaColors.emeraldLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emoji_events,
                      size: 34, color: HaColors.emeraldDark),
                ),
                const SizedBox(height: 10),
                const Text(
                  'وصلت لوجهتك بأمان',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: HaColors.navy,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SummaryItem(
                      icon: Icons.route,
                      value: '${ride.distanceKmValue.toStringAsFixed(1)} كم',
                      label: 'المسافة',
                    ),
                    _SummaryItem(
                      icon: Icons.schedule,
                      value: '${ride.etaMinutes} دقيقة',
                      label: 'المدة',
                    ),
                    _SummaryItem(
                      icon: Icons.payments_outlined,
                      value:
                          '${ride.fare.toStringAsFixed(ride.fare == ride.fare.roundToDouble() ? 0 : 2)} ر.س',
                      label: 'المبلغ',
                      highlight: true,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (ride.rating == null) ...[
                  const Text(
                    'كيف كانت رحلتك مع الكابتن؟',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans Arabic',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: HaColors.navy,
                    ),
                  ),
                  RatingStars(rating: _stars, onChanged: (s) {
                    setState(() => _stars = s);
                    _service.rateCaptain(s);
                  }),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'تقييمك: ${ride.rating} ',
                        style: const TextStyle(
                          fontFamily: 'IBM Plex Sans Arabic',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: HaColors.slate600,
                        ),
                      ),
                      const Icon(Icons.star_rounded,
                          size: 18, color: HaColors.amber),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _service.dismissCompletedRide,
                  child: const Text('إنهاء — طلب رحلة جديدة'),
                ),
              ],
            ),
    );
  }
}
