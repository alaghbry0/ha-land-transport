import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/place.dart';
import '../theme/ha_theme.dart';

/// فتح صفحة رخصة OpenStreetMap (رابط ثابت للنقر على الإسناد).
void _openOsmLicense() {}

/// خريطة OpenStreetMap تفاعلية — بلاطات OSM المجانية بدون أي مفاتيح API.
///
/// تغطي كامل الشاشة خلف البطاقات السفلية، وتعرض علامات واضحة
/// لنقطة الانطلاق والوجهة وموقع سيارة الكابتن أثناء الرحلة.
class HaMap extends StatefulWidget {
  const HaMap({
    super.key,
    required this.markers,
    this.polylinePoints = const [],
    this.center,
    this.onTapPick,
    this.fitPoints,
    this.mapController,
    this.dark = false,
  });

  /// العلامات: (الموقع، نوعها).
  final List<({Place place, HaMarkerKind kind})> markers;

  /// خط مسار الرحلة (من الكابتن إلى العميل أو من الانطلاق للوجهة).
  final List<LatLng> polylinePoints;

  /// مركز الخريطة الافتراضي (وسط الرياض إن لم يحدد).
  final LatLng? center;

  /// عند النقر على الخريطة لاختيار نقطة مخصصة.
  final void Function(LatLng tapped)? onTapPick;

  /// نقاط يتم ملاءمة الكاميرا عليها تلقائياً عند تغيرها.
  final List<LatLng>? fitPoints;

  /// متحكم خارجي للخريطة.
  final MapController? mapController;

  /// وضع داكن للبطاقات الزجاجية فوق الخريطة.
  final bool dark;

  @override
  State<HaMap> createState() => _HaMapState();
}

/// أنواع العلامات المعروضة.
enum HaMarkerKind {
  /// نقطة الانطلاق (دائرة زمردية).
  pickup,

  /// الوجهة (مربع كحلي).
  destination,

  /// سيارة الكابتن (أيقونة سيارة داخل دائرة زمردية).
  car,

  /// موقع الراكب الحالي.
  passengerHere,
}

class _HaMapState extends State<HaMap> {
  final MapController _fallbackController = MapController();
  late final MapController _controller =
      widget.mapController ?? _fallbackController;

  List<LatLng>? _lastFitKey;

  @override
  Widget build(BuildContext context) {
    final allMarkers = <Marker>[
      ...widget.markers.map((m) => _buildMarker(m.place, m.kind)),
    ];

    final tileUrl = widget.dark
        ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    // ملاءمة تلقائية عند تغير نقاط الملاءمة
    final fitKey = widget.fitPoints;
    if (fitKey != null && !_listsEqual(fitKey, _lastFitKey)) {
      _lastFitKey = List.of(fitKey);
      WidgetsBinding.instance.addPostFrameCallback((_) => _fit(fitKey));
    }

    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: widget.center ?? const LatLng(24.7136, 46.6753),
        initialZoom: 12.5,
        onTap: widget.onTapPick == null
            ? null
            : (tapPos, latLng) => widget.onTapPick!(latLng),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: tileUrl,
          userAgentPackageName: 'sa.ha.transport',
          maxNativeZoom: 18,
        ),
        if (widget.polylinePoints.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: widget.polylinePoints,
                strokeWidth: 4.5,
                color: HaColors.emerald,
                borderStrokeWidth: 8,
                borderColor: HaColors.emerald.withValues(alpha: 0.25),
              ),
            ],
          ),
        MarkerLayer(markers: allMarkers),
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap',
              onTap: _openOsmLicense,
            ),
          ],
        ),
      ],
    );
  }

  void _fit(List<LatLng> points) {
    if (!mounted || points.isEmpty) return;
    try {
      _controller.fitCamera(
        CameraFit.coordinates(
          coordinates: points,
          padding: const EdgeInsets.fromLTRB(80, 140, 80, 420),
        ),
      );
    } catch (_) {
      // المتحكم قد لا يكون جاهزاً في أول إطار — يُتجاهل بأمان
    }
  }

  bool _listsEqual(List<LatLng> a, List<LatLng>? b) {
    if (b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Marker _buildMarker(Place place, HaMarkerKind kind) {
    return Marker(
      width: 44,
      height: 44,
      point: LatLng(place.lat, place.lng),
      child: _MarkerPin(kind: kind),
    );
  }
}

/// شكل العلامة نفسها — دائرة بيضاء بحد ملون وأيقونة.
class _MarkerPin extends StatelessWidget {
  const _MarkerPin({required this.kind});

  final HaMarkerKind kind;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (kind) {
      HaMarkerKind.pickup => (Icons.trip_origin, HaColors.emerald),
      HaMarkerKind.destination => (Icons.location_on, HaColors.navy),
      HaMarkerKind.car => (Icons.local_taxi, HaColors.emeraldDark),
      HaMarkerKind.passengerHere => (Icons.person_pin_circle, HaColors.amber),
    };
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.fromBorderSide(BorderSide(color: color, width: 3)),
        boxShadow: [
          BoxShadow(
            color: HaColors.navy.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
