import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class WeeklyPredictionCard extends StatelessWidget {
  final List<DayPrediction> predictions;

  const WeeklyPredictionCard({super.key, required this.predictions});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.cardBackground;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Próximos 7 días', style: AppTextStyles.h3.copyWith(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
              Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: predictions.map((day) {
              final barColor = day.isHigh ? AppColors.danger : AppColors.primary;
              return Column(
                children: [
                  Text(day.label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Container(
                    width: 8,
                    height: day.isHigh ? 48 : 32,
                    decoration: BoxDecoration(
                      color: barColor.withValues(alpha: day.isHigh ? 1.0 : 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(day.kwh, style: AppTextStyles.bodySmall.copyWith(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary, fontWeight: FontWeight.w600)),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.wb_sunny_outlined, size: 16, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'El miércoles será tu día más caro. Reduce el A/C por la tarde.',
                    style: AppTextStyles.bodySmall.copyWith(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
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

class DayPrediction {
  final String label;
  final String kwh;
  final bool isHigh;

  const DayPrediction({required this.label, required this.kwh, this.isHigh = false});
}