import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../widgets/common_widgets.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

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
              const Text(
                'Wallet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              _buildBalanceCard(),
              const SizedBox(height: 16),
              _buildStabilityScore(),
              const SectionHeader(title: 'Transactions'),
              _buildTransactions(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Micro-Savings Wallet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Available Balance',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            '\u20B9${MockData.walletBalance.toInt()}',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Auto-save',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                Text(
                  '\u20B9${MockData.autoDeductionPerDay.toInt()}/day',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Next premium due',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                Text(
                  '\u20B9${MockData.weeklyPremium.toInt()} in ${MockData.policyDaysRemaining} days',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStabilityScore() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Income Stability Score',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${MockData.stabilityScore}/100',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _stabilityBar(
            'Earnings Consistency',
            MockData.earningsConsistency,
            '40%',
            AppColors.accent,
          ),
          const SizedBox(height: 10),
          _stabilityBar(
            'Risk Zone Exposure',
            MockData.riskExposure,
            '25%',
            AppColors.warning,
          ),
          const SizedBox(height: 10),
          _stabilityBar(
            'Insurance Utilization',
            MockData.insuranceUtil,
            '20%',
            AppColors.primary,
          ),
          const SizedBox(height: 10),
          _stabilityBar(
            'Savings Behavior',
            MockData.savingsBehavior,
            '15%',
            AppColors.danger,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Increase daily savings to \u20B915 to improve your score by ~8 points.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stabilityBar(String label, double value, String weight, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${value.toInt()}% ($weight)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 6,
            backgroundColor: AppColors.bgSurface,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactions() {
    return Column(
      children: MockData.walletTransactions.map((tx) {
        final isCredit = tx['type'] == 'credit';
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCredit ? AppColors.onboardSuccessBg : AppColors.onboardDangerBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isCredit
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: isCredit ? AppColors.success : AppColors.danger,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx['desc'] as String,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        tx['date'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isCredit ? '+' : ''}\u20B9${(tx['amount'] as double).abs().toInt()}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCredit ? AppColors.success : AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
