import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'widgets/consumption_hero_card.dart';
import 'widgets/weekly_prediction_card.dart';
import 'widgets/monthly_budget_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final predictions = const [
      DayPrediction(label: 'L', kwh: '12', isHigh: false),
      DayPrediction(label: 'M', kwh: '14', isHigh: false),
      DayPrediction(label: 'X', kwh: '22', isHigh: true),
      DayPrediction(label: 'J', kwh: '15', isHigh: false),
      DayPrediction(label: 'V', kwh: '13', isHigh: false),
      DayPrediction(label: 'S', kwh: '10', isHigh: false),
      DayPrediction(label: 'D', kwh: '9', isHigh: false),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text('Cochabamba, BO', style: AppTextStyles.bodySmall.copyWith(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
          ],
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary,
            child: Text('M', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.w600)),
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ConsumptionHeroCard(
                consumptionKwh: 12.5,
                costBs: 22.40,
                percentageChange: -8,
                isNormal: true,
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 20),
              WeeklyPredictionCard(predictions: predictions)
                  .animate().fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: 20),
              MonthlyBudgetCard(spent: 315, budget: 560, isOverBudget: false)
                  .animate().fadeIn(delay: 400.ms, duration: 400.ms),
              const SizedBox(height: 20),
              // Recomendaciones
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 18, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Text('Recomendación', style: AppTextStyles.h3.copyWith(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Hoy a las 3 PM baja la temperatura exterior. Abre ventanas y usa ventilador en lugar de A/C.',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          debugPrint('Tab: $index');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Análisis'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_rounded), label: 'Alertas'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Perfil'),
        ],
      ),
    );
  }
}