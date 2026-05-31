import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class MonthlyBudgetCard extends StatelessWidget {
  final double spent;
  final double budget;
  final bool isOverBudget;

  const MonthlyBudgetCard({
    super.key,
    required this.spent,
    required this.budget,
    required this.isOverBudget,
  });

  double get _percentage => (spent / budget).clamp(0.0, 1.0);

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
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Presupuesto mensual', style: AppTextStyles.h3.copyWith(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
                ],
              ),
              Text('${(_percentage * 100).round()}%', style: AppTextStyles.h3.copyWith(color: isOverBudget ? AppColors.danger : AppColors.primary)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _percentage,
              backgroundColor: isDark ? AppColors.darkBorder : AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(isOverBudget ? AppColors.danger : AppColors.primary),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Has gastado Bs ${spent.toStringAsFixed(0)} de Bs ${budget.toStringAsFixed(0)}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          if (isOverBudget) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vas por encima de tu presupuesto. Activa el modo ahorro.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}