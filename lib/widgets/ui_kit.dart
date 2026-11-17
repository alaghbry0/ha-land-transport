import 'package:flutter/material.dart';

import '../theme/ha_theme.dart';

/// شعار HA الدائري — يستخدم في الشاشات العلوية.
class HaLogo extends StatelessWidget {
  const HaLogo({super.key, this.size = 40, this.dark = false});

  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HaColors.emerald, HaColors.emeraldDark],
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: HaColors.emerald.withValues(alpha: 0.35),
            blurRadius: size * 0.35,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'HA',
          style: TextStyle(
            fontFamily: 'IBM Plex Sans Arabic',
            fontSize: size * 0.38,
            fontWeight: FontWeight.w700,
            color: dark ? HaColors.navy : Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// صف معلومات صغير (أيقونة + عنوان + قيمة).
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: (iconColor ?? HaColors.emerald).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: iconColor ?? HaColors.emeraldDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'IBM Plex Sans Arabic',
                  fontSize: 11.5,
                  color: HaColors.slate500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'IBM Plex Sans Arabic',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: HaColors.navy,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// بطاقة اختيار فئة المركبة.
class VehicleClassCard extends StatelessWidget {
  const VehicleClassCard({
    super.key,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.price,
    required this.selected,
    required this.onTap,
    required this.subtitle2,
  });

  final String label;
  final String subtitle;
  final String subtitle2;
  final IconData icon;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? HaColors.emeraldLight
              : HaColors.slate100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? HaColors.emerald : HaColors.slate200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: selected ? HaColors.emeraldDark : HaColors.slate500,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'IBM Plex Sans Arabic',
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: selected ? HaColors.emeraldDark : HaColors.navy,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              price,
              style: TextStyle(
                fontFamily: 'IBM Plex Sans Arabic',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? HaColors.emeraldDark : HaColors.slate600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle2,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans Arabic',
                fontSize: 10,
                color: HaColors.slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// مؤشر مراحل الرحلة الأفقية (نقاط متصلة).
class RideProgressDots extends StatelessWidget {
  const RideProgressDots({
    super.key,
    required this.steps,
    required this.current,
  });

  final List<String> steps;
  final int current;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: i <= current
                        ? HaColors.emerald
                        : HaColors.slate200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < current
                        ? HaColors.emerald
                        : i == current
                            ? HaColors.emeraldLight
                            : HaColors.slate100,
                    border: Border.all(
                      color: i <= current
                          ? HaColors.emerald
                          : HaColors.slate300,
                      width: 2,
                    ),
                  ),
                  child: i < current
                      ? const Icon(Icons.check,
                          size: 13, color: Colors.white)
                      : i == current
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: HaColors.emeraldDark,
                              ),
                            )
                          : null,
                ),
                const SizedBox(height: 5),
                SizedBox(
                  width: 64,
                  child: Text(
                    steps[i],
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans Arabic',
                      fontSize: 9.5,
                      fontWeight:
                          i == current ? FontWeight.w700 : FontWeight.w500,
                      color: i <= current
                          ? HaColors.navy
                          : HaColors.slate400,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// نجوم التقييم القابلة للنقر.
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    required this.onChanged,
    this.size = 38,
  });

  final int rating;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final star = i + 1;
        return IconButton(
          onPressed: () => onChanged(star),
          icon: Icon(
            star <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
            color: star <= rating ? HaColors.amber : HaColors.slate300,
            size: size,
          ),
        );
      }),
    );
  }
}

/// زر كبسولي صغير بأيقونة — للاختصارات السريعة.
class QuickChip extends StatelessWidget {
  const QuickChip({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? HaColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? HaColors.navy : HaColors.slate200,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: HaColors.navy.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? HaColors.emerald : HaColors.slate500,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'IBM Plex Sans Arabic',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : HaColors.slate600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// شارة حالة صغيرة.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'IBM Plex Sans Arabic',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة الكابتن — الصورة الرمزية والاسم والتقييم وبيانات السيارة واللوحة.
class CaptainCard extends StatelessWidget {
  const CaptainCard({
    super.key,
    required this.name,
    required this.carModel,
    required this.plateNumber,
    required this.rating,
    this.avatarLabel,
    this.trailing,
  });

  final String name;
  final String carModel;
  final String plateNumber;
  final double rating;
  final String? avatarLabel;
  final Widget? trailing;

  String _initials() {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return parts[0].characters.first + parts[1].characters.first;
    }
    return name.characters.first;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HaColors.slate50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HaColors.slate200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [HaColors.navy, HaColors.navySoft],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                avatarLabel ?? _initials(),
                style: const TextStyle(
                  fontFamily: 'IBM Plex Sans Arabic',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: HaColors.emerald,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'IBM Plex Sans Arabic',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: HaColors.navy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.star_rounded,
                        size: 15, color: HaColors.amber),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontFamily: 'IBM Plex Sans Arabic',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: HaColors.slate600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  carModel,
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontSize: 12.5,
                    color: HaColors.slate500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing ??
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: HaColors.slate300, width: 1.4),
                ),
                child: Text(
                  plateNumber,
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: HaColors.navy,
                    letterSpacing: 1,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
