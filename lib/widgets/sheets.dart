import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/ha_theme.dart';

/// بطاقة سفلية أنيقة تطفو فوق الخريطة — بنمط تطبيقات النقل الحديثة.
///
/// حواف علوية مستديرة، مقبض سحب صغير، وخلفية بيضاء نظيفة بظل ناعم.
class HaBottomSheet extends StatelessWidget {
  const HaBottomSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 24),
    this.maxHeightFactor,
  });

  final Widget child;
  final EdgeInsets padding;
  final double? maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: HaColors.navy.withValues(alpha: 0.18),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: HaColors.slate300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: SingleChildScrollView(
                padding: padding,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );

    if (maxHeightFactor != null) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: maxHeightFactor!,
          child: body,
        ),
      );
    }
    return Align(alignment: Alignment.bottomCenter, child: body);
  }
}

/// شريط علوي عائم زجاجي (Blur) فوق الخريطة — يستضيف مبدل الوضع.
class FloatingTopBar extends StatelessWidget {
  const FloatingTopBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: HaColors.navy.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// مبدل الوضع الفوري (راكب / كابتن) — قلب تجربة النموذج الأولي.
///
/// شريط كبسولي داخل الشريط العلوي العائم: ضغطة واحدة تنقل المستخدم
/// بين الوضعين مع انتقال سلس، مع إظهار عدد الطلبات الواردة للكابتن.
class RoleSwitcher extends StatelessWidget {
  const RoleSwitcher({
    super.key,
    required this.current,
    required this.onChanged,
    this.badge,
  });

  final Role current;
  final ValueChanged<Role> onChanged;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RoleChip(
            label: 'وضع الراكب',
            icon: Icons.person_outline,
            selected: current == Role.passenger,
            onTap: () => onChanged(Role.passenger),
          ),
          const SizedBox(width: 4),
          _RoleChip(
            label: 'وضع الكابتن',
            icon: Icons.local_taxi_outlined,
            selected: current == Role.captain,
            badge: badge,
            onTap: () => onChanged(Role.captain),
          ),
        ],
      ),
    );
  }
}

enum Role { passenger, captain }

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? HaColors.emerald : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: HaColors.emerald.withValues(alpha: 0.45),
                      blurRadius: 12,
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
                size: 17,
                color: selected ? Colors.white : Colors.white70,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans Arabic',
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : Colors.white70,
                ),
              ),
              if (badge != null && badge! > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: HaColors.amber,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      fontFamily: 'IBM Plex Sans Arabic',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
