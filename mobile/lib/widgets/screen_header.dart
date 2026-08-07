// mobile/lib/widgets/screen_header.dart
import 'package:flutter/material.dart';
import 'package:mobile/theme/app_theme.dart';

/// Large title header used atop list screens (Despesas, Planos), replacing
/// the generic AppBar title/subtitle stack with a badge that carries a live
/// count so the header itself communicates screen state.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  final String title;
  final String subtitle;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.9,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.accentPrimary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.accentPrimary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: AppColors.accentPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
