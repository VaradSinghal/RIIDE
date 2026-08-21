import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../services/supabase_service.dart';
import '../services/premium_engine.dart';
import '../widgets/common_widgets.dart';
import '../widgets/demo_claim_overlay.dart';
import '../widgets/payment_processing_overlay.dart';
import 'claim_detail_screen.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';

class InsuranceScreen extends StatefulWidget {
  const InsuranceScreen({super.key});

  @override
  State<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends State<InsuranceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _activeTriggers = List.from(
    MockData.activeTriggers,
  );

  // Dynamic Premium State
  late PremiumResult _premiumResult;
  bool _isRecalculating = false;
  String _currentZone = MockData.workerZone;
  final String _currentCity = MockData.workerCity;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Compute initial dynamic premium
    _premiumResult = PremiumEngine.calculate(
      zone: _currentZone,
      city: _currentCity,
      vehicleType: MockData.workerVehicle,
      experienceWeeks: MockData.experienceWeeks,
      claimCount: MockData.totalClaimsPaid,
      driverAge: 28,
      dailyTravelKm: 45,
      dailyOrderVolume: 15,
      dailyHours: 8,
    );

    if (SupabaseService.isConfigured) {
      _initSupabaseStreams();
    }
  }

  void _initSupabaseStreams() async {
    // Initial fetch
    try {
      final data = await SupabaseService.client
          .from('active_triggers')
          .select()
          .order('trigger_id');
      if (data.isNotEmpty) _updateTriggers(data);
    } catch (e) {
      print('Fallback to mock triggers: $e');
    }

    // Subscribe to realtime updates for triggers
    SupabaseService.client
        .channel('public:active_triggers')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'active_triggers',
          callback: (payload) async {
            final data = await SupabaseService.client
                .from('active_triggers')
                .select()
                .order('trigger_id');
            _updateTriggers(data);
          },
        )
        .subscribe();

    // 2. Listen for Auto-Generated Claims (Zero-Touch Demo)
    SupabaseService.client
        .channel('public:claims')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'claims',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'worker_id',
            value: MockData.workerId,
          ),
          callback: (payload) {
            final newClaim = payload.newRecord;
            final amount = (newClaim['payout_amount'] as num).toDouble();
            final label = newClaim['trigger_label'] ?? 'Parametric Payout';
            final claimId = newClaim['claim_id'] ?? 'CLM-${DateTime.now().millisecondsSinceEpoch}';

            // Save to Notifications
            NotificationService().addNotification(
              id: claimId,
              title: '💸 Payout Processed',
              message: 'Claim $claimId processed. ₹$amount credited to wallet.',
              type: NotificationType.payout,
            );
            
            // Auto-trigger the High-Fidelity Mock Payout UI
            if (mounted) {
              PaymentProcessingOverlay.show(
                context, 
                amount: amount, 
                description: 'Claim Payout: $label'
              );
            }
          },
        )
        .subscribe();
  }

  void _updateTriggers(List<dynamic> data) {
    if (!mounted) return;
    setState(() {
      _activeTriggers = data
          .map(
            (t) => {
              'id': t['trigger_id'],
              'label': t['label'],
              'icon': t['trigger_id'] == 'heavy_rainfall'
                  ? 'water_drop'
                  : t['trigger_id'] == 'severe_aqi'
                  ? 'air'
                  : t['trigger_id'] == 'extreme_heat'
                  ? 'thermostat'
                  : t['trigger_id'] == 'flooding'
                  ? 'waves'
                  : 'block',
              'threshold': t['threshold'],
              'currentValue': t['current_value'],
              'riskLevel': (t['risk_level'] as num).toDouble(),
              'status': t['status'],
              'source': t['source'],
              'lastChecked': 'Just now',
            },
          )
          .toList();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (SupabaseService.isConfigured) {
      SupabaseService.client.removeAllChannels();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          DemoClaimOverlay.show(context);
        },
        backgroundColor: AppColors.onboardBluePrimary,
        icon: const Icon(Icons.play_circle_filled_rounded, color: Colors.white),
        label: const Text('Simulate AI Claim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'Insurance',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.all(3),
                tabs: const [
                  Tab(text: 'Policy'),
                  Tab(text: 'Premium'),
                  Tab(text: 'Claims'),
                  Tab(text: 'Triggers'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPolicyTab(),
                  _buildPremiumTab(),
                  _buildClaimsTab(),
                  _buildTriggersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 1: Policy Management ─────────────────────────────────

  Widget _buildPolicyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActivePolicyCard(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                GigKavachApiService.downloadPolicyPdf(MockData.policyId);
              },
              icon: const Icon(Icons.download_rounded, color: AppColors.onboardBluePrimary, size: 20),
              label: const Text('Download Policy Document (PDF)', style: TextStyle(color: AppColors.onboardBluePrimary, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.onboardBluePrimary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildPolicyDetails(),
          const SectionHeader(title: 'Policy History'),
          _buildPolicyHistory(),
          const SectionHeader(title: 'Terms & Exclusions'),
          _buildExclusions(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildActivePolicyCard() {
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
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Coverage',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    MockData.policyTier,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${MockData.policyDaysRemaining} days left',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Coverage Ceiling',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            '\u20B9${MockData.coverageCeiling.toInt()}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            '${MockData.coveragePercentage.toInt()}% of avg weekly income (\u20B9${MockData.avgWeeklyIncome.toInt()})',
            style: const TextStyle(fontSize: 12, color: Colors.white60),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '\u20B9${MockData.weeklyPremium.toInt()}/wk',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Premium',
                        style: TextStyle(fontSize: 10, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${MockData.totalClaimsPaid}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Claims Paid',
                        style: TextStyle(fontSize: 10, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '\u20B9${MockData.totalPayoutsReceived.toInt()}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Total Payouts',
                        style: TextStyle(fontSize: 10, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyDetails() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Policy Details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _detailRow('Policy ID', MockData.policyId),
          _detailRow(
            'Status',
            MockData.policyStatus,
            valueColor: AppColors.success,
          ),
          _detailRow(
            'Period',
            '${MockData.policyStartDate} - ${MockData.policyEndDate}',
          ),
          _detailRow('Tier', MockData.policyTier),
          _detailRow(
            'Auto-Renewal',
            'Enabled (from Wallet)',
            valueColor: AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyHistory() {
    return Column(
      children: MockData.policyHistory.map((policy) {
        final isActive = policy['status'] == 'Active';
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isActive ? AppColors.primary : AppColors.textMuted)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isActive ? Icons.shield_rounded : Icons.history_rounded,
                    color: isActive ? AppColors.primary : AppColors.textMuted,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        policy['period'] as String,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${policy['tier']} \u2022 \u20B9${policy['premium']} \u2022 ${policy['claims']} claims',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip(
                  label: policy['status'] as String,
                  color: isActive ? AppColors.success : AppColors.textMuted,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExclusions() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.gavel_rounded,
                color: AppColors.warning,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Standard Exclusions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...MockData.exclusions.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.remove_rounded,
                    color: AppColors.textMuted,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: AppColors.textMuted, height: 20),
          _detailRow('Cooling-off Period', MockData.coolingOffPeriod),
          _detailRow('Grievance Email', MockData.grievanceEmail),
          _detailRow('Helpline', MockData.grievancePhone),
        ],
      ),
    );
  }

  // ─── Dynamic Premium Recalculation ─────────────────────────────

  Future<void> _recalculatePremium(String zone) async {
    setState(() => _isRecalculating = true);
    await Future.delayed(const Duration(milliseconds: 1200)); // Simulate ML inference
    if (!mounted) return;
    setState(() {
      _currentZone = zone;
      _premiumResult = PremiumEngine.calculate(
        zone: zone,
        city: _currentCity,
        vehicleType: MockData.workerVehicle,
        experienceWeeks: MockData.experienceWeeks,
        claimCount: MockData.totalClaimsPaid,
        driverAge: 28,
        dailyTravelKm: 45,
        dailyOrderVolume: 15,
        dailyHours: 8,
      );
      _isRecalculating = false;
    });
  }

  // ─── TAB 2: Dynamic Premium ────────────────────────────────────

  Widget _buildPremiumTab() {
    final result = _premiumResult;
    final zoneProfile = result.zoneProfile;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium total hero card
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('Your Weekly Premium', style: TextStyle(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 8),
                _isRecalculating
                    ? const SizedBox(
                        height: 50,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                            SizedBox(height: 6),
                            Text('AI Recalculating...', style: TextStyle(fontSize: 11, color: Colors.white70)),
                          ],
                        ),
                      )
                    : Text(
                        '\u20B9${result.totalPremium.toInt()}',
                        style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                const Text('per week', style: TextStyle(fontSize: 13, color: Colors.white60)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text('${(result.modelConfidence * 100).toInt()}% confidence', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text('${result.coverageHoursPerDay}h/day coverage', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Zone Risk Summary Card
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Zone: $_currentZone', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          Text('Priced using ${result.factors.length} ML risk vectors', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _miniStat('Flood Risk', '${(zoneProfile.floodRiskScore * 100).toInt()}%', zoneProfile.floodRiskScore > 0.5 ? AppColors.danger : AppColors.success),
                    _miniStat('Rain Forecast', '${zoneProfile.predictedRainNextWeek}mm', zoneProfile.predictedRainNextWeek > 15 ? AppColors.warning : AppColors.success),
                    _miniStat('AQI', '${zoneProfile.avgAqi}', zoneProfile.avgAqi > 200 ? AppColors.danger : AppColors.textMuted),
                    _miniStat('Temp', '${zoneProfile.avgTempC}°C', zoneProfile.avgTempC >= 40 ? AppColors.danger : AppColors.textMuted),
                  ],
                ),
              ],
            ),
          ),

          const SectionHeader(title: 'AI Premium Breakdown'),

          // Factor-by-factor breakdown from live engine
          ...result.factors.map((factor) {
            final isDiscount = factor.amount < 0;
            final isNeutral = factor.amount == 0;
            final color = isDiscount
                ? AppColors.success
                : isNeutral
                    ? AppColors.textMuted
                    : (factor.type == 'base' ? AppColors.textPrimary : AppColors.warning);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isDiscount ? Icons.trending_down_rounded
                              : isNeutral ? Icons.remove_rounded
                              : factor.type == 'base' ? Icons.foundation_rounded
                              : Icons.add_circle_outline_rounded,
                          color: color, size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(factor.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
                        ),
                        Text(
                          isNeutral ? '\u20B90' : '${isDiscount ? "" : "+"}\u20B9${factor.amount.abs().toInt()}',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(factor.info, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),

          // Total
          GlassCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Weekly Premium', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text('\u20B9${result.totalPremium.toInt()}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Info box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Premium auto-recalculates weekly using ML models on zone flood risk, weather forecasts, AQI levels, claim history, and vehicle type.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  void _showZoneComparisonSheet() {
    final cityZones = {
      'Chennai': ['Adyar', 'Velachery', 'T. Nagar', 'Mylapore', 'Anna Nagar', 'Guindy', 'Porur', 'Tambaram'],
      'Delhi': ['Connaught Place', 'Dwarka', 'Rohini', 'Saket', 'Lajpat Nagar', 'Karol Bagh'],
      'Mumbai': ['Andheri', 'Bandra', 'Dadar', 'Borivali', 'Kurla', 'Goregaon', 'Powai'],
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Compare Zone Premiums', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              const Text('See how the AI adjusts pricing per zone', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: ListView(
                  children: (cityZones[_currentCity] ?? cityZones['Chennai']!).map((zone) {
                    final result = PremiumEngine.calculate(
                      zone: zone,
                      city: _currentCity,
                      vehicleType: MockData.workerVehicle,
                      experienceWeeks: MockData.experienceWeeks,
                      claimCount: MockData.totalClaimsPaid,
                      driverAge: 28,
                      dailyTravelKm: 45,
                      dailyOrderVolume: 15,
                      dailyHours: 8,
                    );
                    final isCurrent = zone == _currentZone;
                    final profile = result.zoneProfile;

                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _recalculatePremium(zone);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isCurrent ? AppColors.primary.withValues(alpha: 0.1) : AppColors.bgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isCurrent ? AppColors.primary : AppColors.textMuted.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(zone, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isCurrent ? AppColors.primary : AppColors.textPrimary)),
                                      if (isCurrent) ...[const SizedBox(width: 6), const Text('(Current)', style: TextStyle(fontSize: 10, color: AppColors.primary))],
                                    ],
                                  ),
                                  Text(
                                    'Flood: ${(profile.floodRiskScore * 100).toInt()}% · Rain: ${profile.predictedRainNextWeek}mm · AQI: ${profile.avgAqi}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Text('\u20B9${result.totalPremium.toInt()}/wk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isCurrent ? AppColors.primary : AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── TAB 3: Claims Management ──────────────────────────────────

  Widget _buildClaimsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zero-touch banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_fix_high_rounded,
                    color: AppColors.success,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zero-Touch Claims',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Claims are auto-detected, validated, and paid. You don\'t need to file anything.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Claim History'),
          // Stats row
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text(
                        '${MockData.totalClaimsPaid}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const Text(
                        'Total Claims',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text(
                        '\u20B9${MockData.totalPayoutsReceived.toInt()}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                      const Text(
                        'Total Payouts',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      const Text(
                        '< 10m',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                      const Text(
                        'Avg Payout',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          // Claims list from Supabase
          if (!SupabaseService.isConfigured)
            ..._buildStaticClaimList(MockData.claimsHistory)
          else
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: SupabaseService.client
                  .from('claims')
                  .stream(primaryKey: ['id'])
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.primary)));
                }
                
                final dbClaims = snapshot.data!;
                if (dbClaims.isEmpty) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No claims found yet.", style: TextStyle(color: AppColors.textSecondary))));
                }

                // Map Supabase claim schema back to Flutter UI schema
                final mappedClaims = dbClaims.map((claim) {
                  return {
                    'id': claim['claim_id'],
                    'date': 'Just now',
                    'type': claim['trigger_label'],
                    'amount': claim['payout_amount']?.toDouble() ?? 0.0,
                    'status': claim['status'] == 'approved' ? 'Resolved' : 'Pending',
                    'hours': claim['inactive_hours'] ?? 0,
                    'confidenceScore': claim['confidence_score']?.toInt() ?? 0,
                    'isSustained': claim['is_sustained'] == true,
                  };
                }).toList();

                return Column(
                  children: _buildStaticClaimList(mappedClaims),
                );
              },
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  List<Widget> _buildStaticClaimList(List<Map<String, dynamic>> claimsList) {
    return claimsList.map((claim) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GlassCard(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ClaimDetailScreen(claim: claim)),
            );
          },
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              claim['type'] as String,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            if (claim['isSustained'] == true) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                child: const Text('Sustained', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.warning)),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          '${claim['date']} \u2022 ${claim['hours']}hrs disruption',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '+\u20B9${(claim['amount'] as double).toInt()}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.success),
                      ),
                      Text(
                        'Score: ${claim['confidenceScore']}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Detected \u2192 Validated \u2192 Paid', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    Row(
                      children: [
                        const Text('View Details', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  // ─── TAB 4: Active Triggers ────────────────────────────────────

  Widget _buildTriggersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.2),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.sensors_rounded, color: AppColors.accent, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '5 automated triggers monitoring your zone in real-time via public APIs.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._activeTriggers.map((trigger) {
            final riskLevel = trigger['riskLevel'] as double;
            final statusColor = riskLevel > 0.5
                ? AppColors.danger
                : riskLevel > 0.2
                ? AppColors.warning
                : AppColors.success;
            final statusLabel = trigger['status'] == 'safe' ? 'Safe' : 'Active';

            final iconMap = {
              'water_drop': Icons.water_drop_rounded,
              'air': Icons.air_rounded,
              'waves': Icons.waves_rounded,
              'block': Icons.block_rounded,
              'thermostat': Icons.thermostat_rounded,
            };

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            iconMap[trigger['icon']] ?? Icons.warning_rounded,
                            color: statusColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trigger['label'] as String,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Threshold: ${trigger['threshold']}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusChip(label: statusLabel, color: statusColor),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Current: ${trigger['currentValue']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${trigger['source']} \u2022 ${trigger['lastChecked']}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Risk bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: riskLevel,
                        backgroundColor: AppColors.textMuted.withValues(
                          alpha: 0.2,
                        ),
                        color: statusColor,
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
