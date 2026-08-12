import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../widgets/common_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                'Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              _buildProfileCard(),
              const SizedBox(height: 16),
              _buildStatsRow(),
              const SectionHeader(title: 'Account'),
              _buildMenuItem(
                Icons.person_outline_rounded,
                'Personal Information',
                AppColors.primary,
              ),
              _buildMenuItem(
                Icons.location_on_outlined,
                'Work Zones',
                AppColors.accent,
              ),
              _buildMenuItem(
                Icons.payments_outlined,
                'Payment Methods',
                AppColors.success,
              ),
              _buildMenuItem(
                Icons.history_rounded,
                'Earnings History',
                AppColors.warning,
              ),
              const SectionHeader(title: 'Insurance'),
              _buildMenuItem(
                Icons.shield_outlined,
                'My Policies',
                AppColors.primary,
              ),
              _buildMenuItem(
                Icons.receipt_long_outlined,
                'Claims History',
                AppColors.accent,
              ),
              _buildMenuItem(
                Icons.auto_awesome_rounded,
                'Trust Score',
                AppColors.success,
              ),
              const SectionHeader(title: 'Legal & Policies'),
              GestureDetector(
                onTap: () => _showKfdBottomSheet(context),
                child: _buildMenuItem(
                  Icons.policy_outlined,
                  'IRDAI Key Features Document',
                  AppColors.primary,
                ),
              ),
              _buildMenuItem(
                Icons.support_agent_outlined,
                'Grievance Redressal',
                AppColors.warning,
              ),
              _buildMenuItem(
                Icons.privacy_tip_outlined,
                'Privacy Policy',
                AppColors.textSecondary,
              ),
              const SectionHeader(title: 'App'),
              _buildMenuItem(
                Icons.notifications_outlined,
                'Notifications',
                AppColors.warning,
              ),
              _buildMenuItem(
                Icons.help_outline_rounded,
                'Help & Support',
                AppColors.textSecondary,
              ),
              _buildMenuItem(
                Icons.info_outline_rounded,
                'About GigKavach',
                AppColors.textSecondary,
              ),
              const SizedBox(height: 20),
              _buildLogoutButton(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'RK',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                MockData.workerName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'ID: ${MockData.workerId}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.edit_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statTile(
            'Total Earned',
            '\u20B9${MockData.monthEarnings.toInt()}',
            'This month',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: _statTile('Claims Paid', '\u20B91,330', '3 claims')),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile('Stability', '${MockData.stabilityScore}', 'Score'),
        ),
      ],
    );
  }

  Widget _statTile(String label, String value, String sub) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            sub,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: const Center(
        child: Text(
          'Log Out',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.danger,
          ),
        ),
      ),
    );
  }

  void _showKfdBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Key Features Document',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'IRDAI Micro-Insurance Parametric Policy',
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _kfdSection('1. Coverage Details', 'This policy provides parametric coverage for gig workers against environmental and civic disruptions (Heavy Rainfall >40mm/6h, Severe AQI >350/3h, Extreme Heat >43°C, Flooding, Civic Disruptions).'),
                    _kfdSection('2. Premium Payment', 'Premium is collected weekly and dynamically priced using AI-driven risk scoring based on your working zone, vehicle type, and experience.'),
                    _kfdSection('3. Claim Settlement', 'Claims are adjudicated autonomously using 3rd-party Oracle data (IMD, AQI indices). Payouts are instant and require no manual claim filing.'),
                    _kfdSection('4. Exclusions', 'Routine traffic, personal vehicle breakdown, and non-verified environmental triggers are excluded.'),
                    _kfdSection('5. Grievance Redressal', 'Contact our Grievance Officer at grievance@gigkavach.in or call 1800-XXX-XXXX within 15 days of dispute.'),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _kfdSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }
}
