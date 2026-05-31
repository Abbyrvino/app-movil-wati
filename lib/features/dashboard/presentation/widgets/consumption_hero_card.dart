import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ConsumptionHeroCard extends StatelessWidget {
  final double consumptionKwh;
  final double costBs;
  final double percentageChange;
  final bool isNormal;

  const ConsumptionHeroCard({
    super.key,
    required this.consumptionKwh,
    required this.costBs,
    required this.percentageChange,
    required this.isNormal,
  });

  Color get _statusColor => isNormal ? AppColors.success : AppColors.danger;
  String get _arrow => percentageChange > 0 ? '↑' : '↓';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A9B8A), Color(0xFF2D6A5A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Indicador de estado
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: _statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _statusColor.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.bolt_rounded, color: Colors.white38, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          // Consumo
          Text(
            '${consumptionKwh.toStringAsFixed(1)} kWh',
            style: AppTextStyles.bigNumber.copyWith(color: AppColors.textWhite),
          ),
          const SizedBox(height: 4),
          Text(
            'Consumo estimado hoy',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          // Costo y cambio
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '≈ Bs ${costBs.toStringAsFixed(2)}',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      percentageChange > 0 ? Icons.trending_up : Icons.trending_down,
                      size: 14,
                      color: _statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_arrow ${percentageChange.abs().toStringAsFixed(0)}% vs ayer',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textWhite),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}