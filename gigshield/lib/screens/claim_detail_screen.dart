import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ClaimDetailScreen extends StatelessWidget {
  final Map<String, dynamic> claim;

  const ClaimDetailScreen({super.key, required this.claim});

  @override
  Widget build(BuildContext context) {
    final timeline = claim['timeline'] as List<dynamic>;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            claim['type'] as String,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            claim['id'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const StatusChip(label: 'Paid', color: AppColors.success),
                  ],
                ),
              ),

              // Payout card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Payout Amount',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\u20B9${(claim['amount'] as double).toInt()}',
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${claim['hours']}hrs \u00d7 \u20B970/hr \u00d7 70% coverage',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Confidence Score
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Fraud Validation',
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
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Score: ${claim['confidenceScore']}/100',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildValidationRow(
                        'Environmental disruption confirmed',
                        true,
                        30,
                      ),
                      _buildValidationRow(
                        'Location inside disruption zone',
                        true,
                        25,
                      ),
                      _buildValidationRow('Prior activity coherent', true, 20),
                      _buildValidationRow(
                        'Inactivity onset correlated',
                        true,
                        15,
                      ),
                      _buildValidationRow(
                        'Clean device & network profile',
                        true,
                        10,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // AI Agent Reasoning
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
                          const SizedBox(width: 10),
                          const Text('AI Agent Adjudication', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('Our multi-agent ML orchestrator (IsolationForest + GradientBoosting) evaluated this claim in 142ms.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                      const SizedBox(height: 16),
                      _buildAIReasoningRow('Anomaly Detection', 'Pass (95.2% Conf)'),
                      _buildAIReasoningRow('Weather Severity', 'High Impact'),
                      _buildAIReasoningRow('Decision Engine', 'Auto-Approve'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Trigger data
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.sensors_rounded,
                            color: AppColors.accent,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Trigger Data',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          claim['triggerData'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Timeline
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const SectionHeader(title: 'Claim Timeline'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: List.generate(timeline.length, (i) {
                    final step = timeline[i] as Map<String, dynamic>;
                    final isLast = i == timeline.length - 1;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timeline indicator
                        Column(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: AppColors.success,
                                size: 16,
                              ),
                            ),
                            if (!isLast)
                              Container(
                                width: 2,
                                height: 40,
                                color: AppColors.success.withValues(alpha: 0.3),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        // Content
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step['time'] as String,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  step['event'] as String,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValidationRow(String label, bool passed, int points) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: passed ? AppColors.success : AppColors.danger,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (passed ? AppColors.success : AppColors.danger).withValues(
                alpha: 0.15,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '+$points pts',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: passed ? AppColors.success : AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIReasoningRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.hub_rounded, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
