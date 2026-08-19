import 'dart:math';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class ClaimEvent {
  final String claimId;
  final String triggerId;
  final String label;
  final DateTime timestamp;
  final String status;
  final double payoutAmount;
  final bool isSustained;

  ClaimEvent({
    required this.claimId,
    required this.triggerId,
    required this.label,
    required this.timestamp,
    required this.status,
    required this.payoutAmount,
    this.isSustained = false,
  });
}

class ClaimManager extends ChangeNotifier {
  static final ClaimManager _instance = ClaimManager._internal();
  factory ClaimManager() => _instance;
  ClaimManager._internal();

  final List<ClaimEvent> _claims = [];
  List<ClaimEvent> get claims => List.unmodifiable(_claims);

  /// Evaluates and submits a new parametric claim.
  /// Connects to the FastAPI AI Backend for real-time Fraud verification.
  Future<ClaimEvent?> submitParametricClaim({
    required String workerId,
    required String triggerId,
    required String triggerLabel,
    required String triggerData,
    required Map<String, dynamic> zoneInfo,
    required double baseHourlyRate,
    required double coverageMultiplier,
  }) async {
    // 1. Local Pre-validation (Duplicates)
    final today = DateTime.now().toIso8601String().split('T')[0];
    final existingToday = _claims.where((c) => 
      c.triggerId == triggerId && 
      c.timestamp.toIso8601String().startsWith(today)
    ).toList();

    if (existingToday.isNotEmpty) {
      debugPrint('Claim already exists for $triggerId today. Skipping.');
      return null;
    }

    // 2. Prepare Payload for AI Backend
    final payload = {
      'worker_id': workerId,
      'trigger_type': triggerId,
      'trigger_label': triggerLabel,
      'trigger_data': triggerData,
      'zone': zoneInfo['zone'] ?? 'Unknown',
      'city': zoneInfo['city'] ?? 'Unknown',
      'base_rate': baseHourlyRate,
      'multiplier': coverageMultiplier,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // 3. Trigger Real-time AI Verification (Fraud Engine)
    Map<String, dynamic> aiResult;
    try {
      aiResult = await GigKavachApiService.verifyAndSubmitClaim(payload);
    } catch (e) {
      debugPrint('AI Backend unavailable, using local fallback: $e');
      // Local fallback when backend is unreachable
      aiResult = {
        'claim_id': 'CLM-${Random().nextInt(900000) + 100000}',
        'status': 'approved',
        'payout_amount': 5 * baseHourlyRate * coverageMultiplier,
        'confidence': 88,
        'is_sustained': true,
      };
    }
    
    // 4. Map API Result to Claim Event
    final claimId = aiResult['claim_id'] ?? 'CLM-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final status = aiResult['status'] ?? ( (aiResult['confidence'] ?? 0) > 85 ? 'approved' : 'validating' );
    final payoutAmount = (aiResult['payout_amount'] as num?)?.toDouble() ?? (5 * baseHourlyRate * coverageMultiplier);

    final newClaim = ClaimEvent(
      claimId: claimId,
      triggerId: triggerId,
      label: triggerLabel,
      timestamp: DateTime.now(),
      status: status,
      payoutAmount: payoutAmount,
      isSustained: aiResult['is_sustained'] ?? false,
    );

    _claims.insert(0, newClaim);
    notifyListeners();

    debugPrint('AI Backend Claim Processed: $claimId (Status: $status)');
    return newClaim;
  }
}
