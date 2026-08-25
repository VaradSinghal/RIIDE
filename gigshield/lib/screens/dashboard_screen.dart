import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../widgets/common_widgets.dart';
import '../services/notification_service.dart';
import 'notifications_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildDecisionBanner(),
              const SizedBox(height: 20),
              _buildEarningsOverview(),
              const SectionHeader(title: 'Earnings This Week'),
              _buildWeeklyChart(),
              const SectionHeader(title: 'Platform Breakdown'),
              _buildPlatformSplit(),
              const SectionHeader(title: 'Quick Actions'),
              _buildQuickActions(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Text(
              'RK',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hey, ${MockData.workerName.split(' ').first}!',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${MockData.workerZone}, ${MockData.workerCity}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
            );
          },
          child: ListenableBuilder(
            listenable: NotificationService(),
            builder: (context, _) {
              final unreadCount = NotificationService().unreadCount;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.textMuted.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDecisionBanner() {
    Color bannerColor;
    IconData bannerIcon;
    String bannerText;
    String bannerSub;
    bool isProtected = false;

    if (MockData.decisionScore >= 65) {
      bannerColor = AppColors.success;
      bannerIcon = Icons.check_circle_rounded;
      bannerText = 'Good to Go!';
      bannerSub = 'High demand in your zone. Conditions are favorable.';
    } else if (MockData.decisionScore >= 35) {
      bannerColor = AppColors.warning;
      bannerIcon = Icons.warning_rounded;
      bannerText = 'Proceed with Caution';
      bannerSub = 'Moderate risk detected. Stay alert.';
    } else {
      bannerColor = AppColors.danger;
      bannerIcon = Icons.cancel_rounded;
      bannerText = 'Stay Home';
      bannerSub = 'High disruption risk. Your coverage is active.';
      isProtected = true;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bannerColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: bannerColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bannerColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(bannerIcon, color: bannerColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bannerText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: bannerColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bannerSub,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: bannerColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${MockData.decisionScore}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: bannerColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isProtected) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Earnings Protected: ₹450 paid to wallet',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    'View Receipt',
                    style: TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEarningsOverview() {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: "Today's Earnings",
            value: '\u20B9${MockData.todayEarnings.toInt()}',
            icon: Icons.bolt_rounded,
            iconColor: AppColors.accent,
            subtitle: 'Live',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'This Week',
            value: '\u20B9${MockData.weekEarnings.toInt()}',
            icon: Icons.trending_up_rounded,
            iconColor: AppColors.success,
            subtitle:
                '${((MockData.weekEarnings / MockData.avgWeeklyIncome) * 100).toInt()}% of avg',
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart() {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      child: SizedBox(
        height: 160,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 1000,
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        MockData.weekDays[value.toInt()],
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  },
                  reservedSize: 28,
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(7, (i) {
              final isToday = i == 5;
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: MockData.weeklyDailyEarnings[i],
                    color: isToday
                        ? AppColors.primary
                        : AppColors.textMuted.withValues(alpha: 0.5),
                    width: 20,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformSplit() {
    final values = MockData.platformEarnings.values;
    final total = values.isEmpty ? 1.0 : values.reduce((a, b) => a + b);
    final colors = [AppColors.primary, AppColors.accent, AppColors.warning];
    var i = 0;

    return GlassCard(
      child: Column(
        children: MockData.platformEarnings.entries.map((entry) {
          final pct = (entry.value / total * 100).toInt();
          final color = colors[i % colors.length];
          i++;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '\u20B9${entry.value.toInt()}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  child: Text(
                    '$pct%',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _actionButton(Icons.shield_rounded, 'Insurance', AppColors.primary),
        const SizedBox(width: 10),
        _actionButton(
          Icons.account_balance_wallet_rounded,
          'Wallet',
          AppColors.accent,
        ),
        const SizedBox(width: 10),
        _actionButton(Icons.map_rounded, 'Risk Map', AppColors.warning),
        const SizedBox(width: 10),
        _actionButton(Icons.rocket_launch_rounded, 'Boost', AppColors.success),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, Color color) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
