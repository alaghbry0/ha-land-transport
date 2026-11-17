import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../models/place.dart';
import '../../../models/ride.dart';
import '../../../services/app_service.dart';
import '../../../theme/ha_theme.dart';
import '../../../widgets/ha_map.dart';
import '../../../widgets/sheets.dart';
import '../../../widgets/ui_kit.dart';
import 'captain_login.dart';

export 'captain_login.dart';

/// شاشة الكابتن: خريطة + لوحة تحكم علوية + بطاقة طلب/رحلة سفلية.
class CaptainShell extends StatefulWidget {
  const CaptainShell({super.key});

  @override
  State<CaptainShell> createState() => _CaptainShellState();
}

class _CaptainShellState extends State<CaptainShell> {
  final AppService _service = AppService.instance;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        final captain = _service.currentCaptain;
        if (captain == null) {
          return const CaptainLoginScreen();
        }
        final ride = _service.incomingRide;

        return Stack(
          children: [
            // الخريطة
            Positioned.fill(
              child: _buildMap(captain, ride),
            ),
            // لوحة تحكم الكابتن العلوية (تحت الشريط العائم)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 64, 14, 0),
                  child: _CaptainDashboard(
                    captain: captain,
                    earnings: _service.todayEarnings,
                    tripsCount: _service.todayTripsCount,
                  ),
                ),
              ),
            ),
            // البطاقة السفلية: طلب وارد أو إدارة مرحلة الرحلة
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
                child: ride == null
                    ? _IdleCard(
                        key: const ValueKey('idle'),
                        captain: captain,
                      )
                    : ride.status == RideStatus.searching
                        ? _IncomingRequestCard(
                            key: ValueKey('incoming-${ride.id}'),
                            ride: ride,
                          )
                        : _ActiveRideCard(
                            key: ValueKey('active-${ride.id}-${ride.status}'),
                            ride: ride,
                          ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMap(Captain captain, Ride? ride) {
    final markers = <({Place place, HaMarkerKind kind})>[];
    final polyline = <LatLng>[];

    // موقع سيارة الكابتن (قرب العليا افتراضياً)
    final carLat = 24.6995;
    final carLng = 46.6830;
    markers.add((
      place: Place(
        id: 'my-car',
        name: 'my-car',
        subtitle: '',
        lat: carLat,
        lng: carLng,
      ),
      kind: HaMarkerKind.car
    ));

    if (ride != null) {
      markers.add((place: ride.pickup, kind: HaMarkerKind.pickup));
      markers.add((place: ride.destination, kind: HaMarkerKind.destination));
      if (ride.status == RideStatus.searching ||
          ride.status == RideStatus.captainOnTheWay) {
        polyline.addAll([
          LatLng(carLat, carLng),
          LatLng(ride.pickup.lat, ride.pickup.lng),
        ]);
      } else if (ride.status == RideStatus.inProgress) {
        polyline.addAll([
          LatLng(ride.pickup.lat, ride.pickup.lng),
          LatLng(ride.destination.lat, ride.destination.lng),
        ]);
      }
    }

    return HaMap(
      markers: markers,
      polylinePoints: polyline,
      fitPoints: polyline.isNotEmpty ? polyline : [LatLng(carLat, carLng)],
    );
  }
}

/// لوحة تحكم الكابتن: الحالة + الأرباح اليومية + عدد الرحلات.
class _CaptainDashboard extends StatelessWidget {
  const _CaptainDashboard({
    required this.captain,
    required this.earnings,
    required this.tripsCount,
  });

  final Captain captain;
  final double earnings;
  final int tripsCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: HaColors.navy.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: HaColors.navy.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [HaColors.emerald, HaColors.emeraldDark],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.local_taxi, size: 22, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      captain.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'IBM Plex Sans Arabic',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${captain.carModel} · ${captain.plateNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'IBM Plex Sans Arabic',
                        fontSize: 10.5,
                        color: HaColors.slate300,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // مفتاح الحالة متاح/غير متاح
              _OnlineToggle(captain: captain),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  icon: Icons.payments_outlined,
                  label: 'أرباح اليوم',
                  value:
                      '${earnings.toStringAsFixed(earnings == earnings.roundToDouble() ? 0 : 2)} ر.س',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatBox(
                  icon: Icons.route,
                  label: 'رحلات اليوم',
                  value: '$tripsCount',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatBox(
                  icon: Icons.star_rounded,
                  label: 'التقييم',
                  value: captain.rating.toStringAsFixed(1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: HaColors.emerald),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontSize: 10,
                    color: HaColors.slate300,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'IBM Plex Sans Arabic',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineToggle extends StatelessWidget {
  const _OnlineToggle({required this.captain});

  final Captain captain;

  @override
  Widget build(BuildContext context) {
    final service = AppService.instance;
    return GestureDetector(
      onTap: service.toggleOnline,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: captain.isOnline
              ? HaColors.emerald
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: captain.isOnline
                ? HaColors.emerald
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              captain.isOnline
                  ? Icons.wifi_tethering
                  : Icons.wifi_tethering_off,
              size: 15,
              color: captain.isOnline ? Colors.white : HaColors.slate300,
            ),
            const SizedBox(width: 5),
            Text(
              captain.isOnline ? 'متاح' : 'غير متاح',
              style: TextStyle(
                fontFamily: 'IBM Plex Sans Arabic',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: captain.isOnline ? Colors.white : HaColors.slate300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة الانتظار — لا طلبات حالياً.
class _IdleCard extends StatelessWidget {
  const _IdleCard({required this.captain, super.key});

  final Captain captain;

  @override
  Widget build(BuildContext context) {
    final service = AppService.instance;
    return HaBottomSheet(
      child: captain.isOnline
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: HaColors.emeraldLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.wifi_tethering,
                          size: 21, color: HaColors.emeraldDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'أنت متاح — بانتظار الطلبات',
                        style: const TextStyle(
                          fontFamily: 'IBM Plex Sans Arabic',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: HaColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'سيصلك إشعار فوري عند ورود طلب قريب منك. '
                  'جرّب الآن: بدّل لوضع الراكب من الشريط العلوي واطلب رحلة.',
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontSize: 12.5,
                    color: HaColors.slate500,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 12),
                if (service.todayTrips.isNotEmpty) ...[
                  Row(
                    children: [
                      const Text(
                        'رحلات اليوم',
                        style: TextStyle(
                          fontFamily: 'IBM Plex Sans Arabic',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: HaColors.navy,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'الإجمالي: ${service.todayEarnings.toStringAsFixed(service.todayEarnings == service.todayEarnings.roundToDouble() ? 0 : 2)} ر.س',
                        style: const TextStyle(
                          fontFamily: 'IBM Plex Sans Arabic',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: HaColors.emeraldDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final t in service.todayTrips.take(4))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: HaColors.slate50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: HaColors.slate200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline,
                                size: 17, color: HaColors.emerald),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${t.passengerName} → ${t.destinationName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'IBM Plex Sans Arabic',
                                  fontSize: 12.5,
                                  color: HaColors.slate600,
                                ),
                              ),
                            ),
                            Text(
                              '${t.fare.toStringAsFixed(t.fare == t.fare.roundToDouble() ? 0 : 2)} ر.س',
                              style: const TextStyle(
                                fontFamily: 'IBM Plex Sans Arabic',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: HaColors.navy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 6),
                TextButton(
                  onPressed: service.logoutCaptain,
                  child: const Text(
                    'تسجيل الخروج',
                    style: TextStyle(color: HaColors.slate500, fontSize: 13),
                  ),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: HaColors.slate100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.wifi_tethering_off,
                          size: 21, color: HaColors.slate500),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'أنت غير متاح حالياً',
                        style: const TextStyle(
                          fontFamily: 'IBM Plex Sans Arabic',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: HaColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'فعّل زر «متاح» في الأعلى لاستقبال طلبات الرحلات.',
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontSize: 12.5,
                    color: HaColors.slate500,
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: service.logoutCaptain,
                  child: const Text(
                    'تسجيل الخروج',
                    style: TextStyle(color: HaColors.slate500, fontSize: 13),
                  ),
                ),
              ],
            ),
    );
  }
}

/// بطاقة الطلب الوارد: قبول / رفض.
class _IncomingRequestCard extends StatelessWidget {
  const _IncomingRequestCard({super.key, required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final service = AppService.instance;
    return HaBottomSheet(
      maxHeightFactor: 0.72,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // شريط علوي ملون
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [HaColors.emerald, HaColors.emeraldDark],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_active,
                    size: 18, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'طلب رحلة جديد!',
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans Arabic',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'طلب ${ride.id}',
                    style: const TextStyle(
                      fontFamily: 'IBM Plex Sans Arabic',
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // نقاط الرحلة
          _RouteRow(
            icon: Icons.trip_origin,
            iconColor: HaColors.emerald,
            title: ride.pickup.name,
            subtitle: ride.pickup.subtitle,
          ),
          const Padding(
            padding: EdgeInsetsDirectional.only(start: 29),
            child: SizedBox(
              height: 14,
              child: VerticalDivider(
                thickness: 2,
                color: HaColors.slate200,
              ),
            ),
          ),
          _RouteRow(
            icon: Icons.location_on,
            iconColor: HaColors.navy,
            title: ride.destination.name,
            subtitle: ride.destination.subtitle,
          ),
          const SizedBox(height: 12),
          // تفاصيل الطلب
          Row(
            children: [
              Expanded(
                child: _DetailChip(
                  icon: Icons.route,
                  label: 'المسافة',
                  value: '${ride.distanceKmValue.toStringAsFixed(1)} كم',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DetailChip(
                  icon: Icons.person_outline,
                  label: 'الراكب',
                  value: ride.passengerName,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DetailChip(
                  icon: Icons.local_taxi_outlined,
                  label: 'الفئة',
                  value: ride.vehicleClass.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: HaColors.emeraldLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'قيمة الرحلة',
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: HaColors.slate700,
                  ),
                ),
                Text(
                  '${ride.fare.toStringAsFixed(ride.fare == ride.fare.roundToDouble() ? 0 : 2)} ر.س',
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: HaColors.emeraldDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: service.rejectRide,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HaColors.red,
                    side: const BorderSide(color: HaColors.red, width: 1.2),
                  ),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('رفض'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: service.acceptRide,
                  icon: const Icon(Icons.check, size: 20),
                  label: const Text('قبول الطلب'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// بطاقة الرحلة النشطة: إدارة المراحل خطوة بخطوة.
class _ActiveRideCard extends StatelessWidget {
  const _ActiveRideCard({super.key, required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final service = AppService.instance;
    final stepIndex = switch (ride.status) {
      RideStatus.captainOnTheWay => 0,
      RideStatus.captainArrived => 1,
      RideStatus.inProgress => 2,
      _ => 3,
    };

    return HaBottomSheet(
      maxHeightFactor: 0.78,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
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
                      ride.status.captainLabel,
                      style: const TextStyle(
                        fontFamily: 'IBM Plex Sans Arabic',
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: HaColors.navy,
                      ),
                    ),
                    Text(
                      'الراكب: ${ride.passengerName} · ${ride.vehicleClass.label}',
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
              Text(
                '${ride.fare.toStringAsFixed(ride.fare == ride.fare.roundToDouble() ? 0 : 2)} ر.س',
                style: const TextStyle(
                  fontFamily: 'IBM Plex Sans Arabic',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: HaColors.emeraldDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RideProgressDots(
            steps: const ['نحو العميل', 'وصلت', 'الرحلة', 'الإنهاء'],
            current: stepIndex,
          ),
          const SizedBox(height: 12),
          _RouteRow(
            icon: Icons.trip_origin,
            iconColor: HaColors.emerald,
            title: ride.pickup.name,
            subtitle: 'نقطة الانطلاق — ${ride.pickup.subtitle}',
          ),
          const Padding(
            padding: EdgeInsetsDirectional.only(start: 29),
            child: SizedBox(
              height: 14,
              child: VerticalDivider(
                thickness: 2,
                color: HaColors.slate200,
              ),
            ),
          ),
          _RouteRow(
            icon: Icons.location_on,
            iconColor: HaColors.navy,
            title: ride.destination.name,
            subtitle: 'الوجهة — ${ride.destination.subtitle}',
          ),
          const SizedBox(height: 14),
          // أزرار المرحلة الحالية
          switch (ride.status) {
            RideStatus.captainOnTheWay => FilledButton.icon(
                onPressed: service.markArrived,
                icon: const Icon(Icons.pin_drop, size: 20),
                label: const Text('وصلت لموقع العميل'),
              ),
            RideStatus.captainArrived => FilledButton.icon(
                onPressed: service.startRide,
                icon: const Icon(Icons.play_arrow, size: 22),
                label: const Text('بدء الرحلة'),
              ),
            RideStatus.inProgress => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'إنهاء الرحلة وتحصيل المبلغ',
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans Arabic',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: HaColors.navy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _PayButton(
                          icon: Icons.payments_outlined,
                          label: 'نقداً',
                          onTap: () =>
                              service.completeRide(PaymentMethod.cash),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PayButton(
                          icon: Icons.credit_card,
                          label: 'مدى',
                          onTap: () =>
                              service.completeRide(PaymentMethod.mada),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PayButton(
                          icon: Icons.phone_iphone,
                          label: 'Apple Pay',
                          onTap: () => service
                              .completeRide(PaymentMethod.applePay),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            _ => const SizedBox.shrink(),
          },
        ],
      ),
    );
  }
}

class _PayButton extends StatelessWidget {
  const _PayButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: HaColors.navy,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: HaColors.navy.withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 21, color: HaColors.emerald),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans Arabic',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: HaColors.navy,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontSize: 10.5,
                    color: HaColors.slate500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: HaColors.slate50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HaColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: HaColors.slate400),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontSize: 10,
                    color: HaColors.slate500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'IBM Plex Sans Arabic',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: HaColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}
