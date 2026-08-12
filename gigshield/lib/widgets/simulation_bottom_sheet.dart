import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/claim_manager.dart';

class SimulationBottomSheet extends StatefulWidget {
  const SimulationBottomSheet({super.key});

  @override
  State<SimulationBottomSheet> createState() => _SimulationBottomSheetState();
}

class _SimulationBottomSheetState extends State<SimulationBottomSheet> {
  String _triggerType = 'Heavy Rainfall';
  String _triggerData = '65mm/6hrs';
  
  // AI Variables
  bool _envVerified = true;
  bool _gpsConsistent = true;
  bool _activityCoherent = true;
  bool _timingCorrelated = true;
  bool _deviceClean = true;

  bool _isProcessing = false;
  int _processingStep = 0;

  void _loadPreset(String type) {
    setState(() {
      if (type == 'clean') {
        _triggerType = 'Flooding';
        _triggerData = 'IMD Alert Active';
        _envVerified = true;
        _gpsConsistent = true;
        _activityCoherent = true;
        _timingCorrelated = true;
        _deviceClean = true;
      } else if (type == 'suspicious') {
        _triggerType = 'Heavy Rainfall';
        _triggerData = '40mm/6hrs';
        _envVerified = true;
        _gpsConsistent = false;
        _activityCoherent = true;
        _timingCorrelated = false;
        _deviceClean = true;
      } else if (type == 'fraud') {
        _triggerType = 'Severe AQI';
        _triggerData = 'AQI 450 (Spoofed)';
        _envVerified = false;
        _gpsConsistent = false;
        _activityCoherent = false;
        _timingCorrelated = false;
        _deviceClean = false;
      }
    });
  }

  Future<void> _runSimulation() async {
    setState(() {
      _isProcessing = true;
      _processingStep = 1;
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _processingStep = 2);

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _processingStep = 3);

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final claimEvent = await ClaimManager().submitParametricClaim(
      workerId: 'Ravi_K_72',
      triggerId: _triggerType.toLowerCase().replaceAll(' ', '_'),
      triggerLabel: _triggerType,
      triggerData: _triggerData,
      zoneInfo: {'zone': 'Active Zone (Simulated)', 'city': 'Chennai'},
      baseHourlyRate: 70,
      coverageMultiplier: 0.70,
    );
    
    if (claimEvent == null) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
             content: Text('Duplicate claim suppressed to prevent fraud.'),
             backgroundColor: AppColors.warning,
          )
        );
      }
      return;
    }
    
    // Also inject into local stream if we had a local provider, or just pop so the UI updates natively via Supabase StreamBuilder
    if (mounted) {
      Navigator.pop(context);
      
      String msg = 'Claim ${claimEvent.status} for ₹${claimEvent.payoutAmount.toInt()}';
      if (claimEvent.isSustained) msg += ' (Sustained Event Batch)';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: claimEvent.status == 'approved' ? AppColors.success : AppColors.warning,
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Processing Simulator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text('Inject parameters directly to your database.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Load Quick Scenario:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPresetBtn('Clean', AppColors.success, Icons.check_circle_outline, () => _loadPreset('clean')),
              const SizedBox(width: 8),
              _buildPresetBtn('Edge Case', AppColors.warning, Icons.warning_amber_rounded, () => _loadPreset('suspicious')),
              const SizedBox(width: 8),
              _buildPresetBtn('Fraud', AppColors.danger, Icons.gpp_bad_rounded, () => _loadPreset('fraud')),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Event Data', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    _buildTextField('Trigger Type', _triggerType, (v) => _triggerType = v),
                    const SizedBox(height: 8),
                    _buildTextField('Observed Data', _triggerData, (v) => _triggerData = v),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI Validation Signals', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    _buildCheckbox('Environmental APIs Match', _envVerified, (v) => setState(() => _envVerified = v!)),
                    _buildCheckbox('Consistent GPS', _gpsConsistent, (v) => setState(() => _gpsConsistent = v!)),
                    _buildCheckbox('Activity Coherent', _activityCoherent, (v) => setState(() => _activityCoherent = v!)),
                    _buildCheckbox('Timing Correlated', _timingCorrelated, (v) => setState(() => _timingCorrelated = v!)),
                    _buildCheckbox('Clean Device (No VPN)', _deviceClean, (v) => setState(() => _deviceClean = v!)),
                  ],
                ),
              ),
            ],
          ),
          if (_isProcessing) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      const Icon(Icons.bolt, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      const Text('Simulating ML Validator...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('[1] Fetching Mock API Data... ${_processingStep >= 2 ? "OK" : ""}', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: _processingStep >= 1 ? AppColors.textPrimary : AppColors.textMuted)),
                  Text('[2] Generating Feature Matrix [11x1]... ${_processingStep >= 3 ? "OK" : ""}', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: _processingStep >= 2 ? AppColors.textPrimary : AppColors.textMuted)),
                  Text('[3] Executing Random Forest Classification...', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: _processingStep >= 3 ? AppColors.textPrimary : AppColors.textMuted)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _runSimulation,
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: const Text('Run Database Injection', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetBtn(String label, Color color, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String value, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Container(
          height: 36,
          decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.3))),
          child: TextFormField(
            initialValue: value,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckbox(String label, bool value, Function(bool?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 20, height: 20,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
              side: BorderSide(color: AppColors.textMuted.withValues(alpha: 0.5)),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
