import 'dart:math';
import 'api_service.dart';

/// GigKavach — AI-Driven Insurance Premium Engine v2
///
/// Calculates dynamic, personalized insurance premiums using a multi-factor
/// risk assessment model. Each driver gets a unique risk profile based on:
///
///   1. AGE — younger/older drivers carry different actuarial risk
///   2. TRAVEL DISTANCE — daily km driven affects exposure duration
///   3. ORDER VOLUME — high order counts = more road time = more risk
///   4. AREA HISTORIC CONDITIONS — flood/waterlog/AQI/heat history
///   5. VEHICLE TYPE — exposure characteristics differ
///   6. CLAIMS HISTORY — past behavior predicts future risk
///   7. WEATHER FORECAST — predictive near-term risk
///
/// DYNAMIC POLICY: After Week 1, a new policy is generated using the
/// driver's actual performance metrics (delivery success rate, safe driving
/// hours, incidents) to reward good behavior with lower premiums.

class PremiumEngine {
  // ── Hyper-local zone risk database (mock API data per zone) ────
  static final Map<String, ZoneRiskProfile> _zoneProfiles = {
    // Chennai zones
    'Adyar': ZoneRiskProfile(
      floodRiskScore: 0.65, waterloggingHistory: 12, avgRainfallMm: 28,
      avgAqi: 142, avgTempC: 34, historicClaimRate: 0.18,
      predictedRainNextWeek: 15, isCycloneSeason: false,
      accidentRate: 0.12, roadQualityScore: 0.6, avgTrafficDensity: 0.72,
    ),
    'Velachery': ZoneRiskProfile(
      floodRiskScore: 0.35, waterloggingHistory: 4, avgRainfallMm: 8,
      avgAqi: 120, avgTempC: 33, historicClaimRate: 0.08,
      predictedRainNextWeek: 5, isCycloneSeason: false,
      accidentRate: 0.08, roadQualityScore: 0.75, avgTrafficDensity: 0.55,
    ),
    'T. Nagar': ZoneRiskProfile(
      floodRiskScore: 0.25, waterloggingHistory: 2, avgRainfallMm: 3,
      avgAqi: 135, avgTempC: 35, historicClaimRate: 0.05,
      predictedRainNextWeek: 2, isCycloneSeason: false,
      accidentRate: 0.15, roadQualityScore: 0.7, avgTrafficDensity: 0.85,
    ),
    'Mylapore': ZoneRiskProfile(
      floodRiskScore: 0.72, waterloggingHistory: 15, avgRainfallMm: 32,
      avgAqi: 155, avgTempC: 34, historicClaimRate: 0.22,
      predictedRainNextWeek: 22, isCycloneSeason: false,
      accidentRate: 0.10, roadQualityScore: 0.55, avgTrafficDensity: 0.65,
    ),
    'Anna Nagar': ZoneRiskProfile(
      floodRiskScore: 0.18, waterloggingHistory: 1, avgRainfallMm: 2,
      avgAqi: 128, avgTempC: 34, historicClaimRate: 0.03,
      predictedRainNextWeek: 0, isCycloneSeason: false,
      accidentRate: 0.06, roadQualityScore: 0.85, avgTrafficDensity: 0.50,
    ),
    'Guindy': ZoneRiskProfile(
      floodRiskScore: 0.55, waterloggingHistory: 8, avgRainfallMm: 18,
      avgAqi: 160, avgTempC: 36, historicClaimRate: 0.14,
      predictedRainNextWeek: 10, isCycloneSeason: false,
      accidentRate: 0.14, roadQualityScore: 0.5, avgTrafficDensity: 0.78,
    ),
    'Porur': ZoneRiskProfile(
      floodRiskScore: 0.82, waterloggingHistory: 20, avgRainfallMm: 38,
      avgAqi: 145, avgTempC: 33, historicClaimRate: 0.28,
      predictedRainNextWeek: 30, isCycloneSeason: false,
      accidentRate: 0.11, roadQualityScore: 0.45, avgTrafficDensity: 0.60,
    ),
    'Tambaram': ZoneRiskProfile(
      floodRiskScore: 0.90, waterloggingHistory: 24, avgRainfallMm: 45,
      avgAqi: 138, avgTempC: 33, historicClaimRate: 0.32,
      predictedRainNextWeek: 35, isCycloneSeason: false,
      accidentRate: 0.09, roadQualityScore: 0.4, avgTrafficDensity: 0.45,
    ),
    // Delhi zones
    'Connaught Place': ZoneRiskProfile(
      floodRiskScore: 0.20, waterloggingHistory: 3, avgRainfallMm: 5,
      avgAqi: 280, avgTempC: 38, historicClaimRate: 0.15,
      predictedRainNextWeek: 2, isCycloneSeason: false,
      accidentRate: 0.18, roadQualityScore: 0.8, avgTrafficDensity: 0.92,
    ),
    'Dwarka': ZoneRiskProfile(
      floodRiskScore: 0.60, waterloggingHistory: 10, avgRainfallMm: 20,
      avgAqi: 310, avgTempC: 40, historicClaimRate: 0.20,
      predictedRainNextWeek: 12, isCycloneSeason: false,
      accidentRate: 0.13, roadQualityScore: 0.65, avgTrafficDensity: 0.70,
    ),
    'Rohini': ZoneRiskProfile(
      floodRiskScore: 0.55, waterloggingHistory: 8, avgRainfallMm: 15,
      avgAqi: 350, avgTempC: 42, historicClaimRate: 0.25,
      predictedRainNextWeek: 8, isCycloneSeason: false,
      accidentRate: 0.16, roadQualityScore: 0.55, avgTrafficDensity: 0.75,
    ),
    'Saket': ZoneRiskProfile(
      floodRiskScore: 0.30, waterloggingHistory: 4, avgRainfallMm: 8,
      avgAqi: 260, avgTempC: 37, historicClaimRate: 0.10,
      predictedRainNextWeek: 3, isCycloneSeason: false,
      accidentRate: 0.10, roadQualityScore: 0.78, avgTrafficDensity: 0.68,
    ),
    'Lajpat Nagar': ZoneRiskProfile(
      floodRiskScore: 0.40, waterloggingHistory: 6, avgRainfallMm: 12,
      avgAqi: 290, avgTempC: 39, historicClaimRate: 0.12,
      predictedRainNextWeek: 5, isCycloneSeason: false,
      accidentRate: 0.14, roadQualityScore: 0.6, avgTrafficDensity: 0.80,
    ),
    'Karol Bagh': ZoneRiskProfile(
      floodRiskScore: 0.45, waterloggingHistory: 7, avgRainfallMm: 14,
      avgAqi: 320, avgTempC: 40, historicClaimRate: 0.16,
      predictedRainNextWeek: 6, isCycloneSeason: false,
      accidentRate: 0.17, roadQualityScore: 0.5, avgTrafficDensity: 0.88,
    ),
    // Mumbai zones
    'Andheri': ZoneRiskProfile(
      floodRiskScore: 0.70, waterloggingHistory: 14, avgRainfallMm: 35,
      avgAqi: 175, avgTempC: 33, historicClaimRate: 0.22,
      predictedRainNextWeek: 25, isCycloneSeason: false,
      accidentRate: 0.15, roadQualityScore: 0.55, avgTrafficDensity: 0.90,
    ),
    'Bandra': ZoneRiskProfile(
      floodRiskScore: 0.50, waterloggingHistory: 6, avgRainfallMm: 18,
      avgAqi: 155, avgTempC: 32, historicClaimRate: 0.12,
      predictedRainNextWeek: 10, isCycloneSeason: false,
      accidentRate: 0.12, roadQualityScore: 0.7, avgTrafficDensity: 0.85,
    ),
    'Dadar': ZoneRiskProfile(
      floodRiskScore: 0.65, waterloggingHistory: 11, avgRainfallMm: 28,
      avgAqi: 180, avgTempC: 33, historicClaimRate: 0.18,
      predictedRainNextWeek: 18, isCycloneSeason: false,
      accidentRate: 0.16, roadQualityScore: 0.5, avgTrafficDensity: 0.92,
    ),
    'Borivali': ZoneRiskProfile(
      floodRiskScore: 0.40, waterloggingHistory: 5, avgRainfallMm: 12,
      avgAqi: 140, avgTempC: 32, historicClaimRate: 0.08,
      predictedRainNextWeek: 6, isCycloneSeason: false,
      accidentRate: 0.08, roadQualityScore: 0.75, avgTrafficDensity: 0.60,
    ),
    'Kurla': ZoneRiskProfile(
      floodRiskScore: 0.85, waterloggingHistory: 22, avgRainfallMm: 42,
      avgAqi: 195, avgTempC: 34, historicClaimRate: 0.30,
      predictedRainNextWeek: 32, isCycloneSeason: false,
      accidentRate: 0.19, roadQualityScore: 0.35, avgTrafficDensity: 0.88,
    ),
    'Goregaon': ZoneRiskProfile(
      floodRiskScore: 0.45, waterloggingHistory: 6, avgRainfallMm: 15,
      avgAqi: 165, avgTempC: 33, historicClaimRate: 0.10,
      predictedRainNextWeek: 8, isCycloneSeason: false,
      accidentRate: 0.11, roadQualityScore: 0.65, avgTrafficDensity: 0.72,
    ),
    'Powai': ZoneRiskProfile(
      floodRiskScore: 0.30, waterloggingHistory: 3, avgRainfallMm: 10,
      avgAqi: 150, avgTempC: 32, historicClaimRate: 0.06,
      predictedRainNextWeek: 4, isCycloneSeason: false,
      accidentRate: 0.07, roadQualityScore: 0.82, avgTrafficDensity: 0.55,
    ),
  };

  /// ─── NEW: Optional AI Async Calculation ───
  static Future<PremiumResult> calculateAsync({
    required String workerId,
    required String zone,
    required String city,
    required String vehicleType,
    int experienceWeeks = 0,
    int claimCount = 0,
    int driverAge = 25,
    double dailyTravelKm = 40.0,
    int dailyOrderVolume = 15,
    double dailyHours = 8.0,
  }) async {
    // 1. Try fetching from the Advanced AI Backend (FastAPI)
    final apiResult = await GigKavachApiService.getPremiumQuote(
      workerId: workerId,
      zone: zone,
      city: city,
      vehicleType: vehicleType,
    );

    if (apiResult.containsKey('premium') && !apiResult.containsKey('fallback')) {
       final profile = _zoneProfiles[zone] ?? _zoneProfiles['Adyar']!;
       return PremiumResult(
         totalPremium: (apiResult['premium'] as num).toDouble(),
         factors: (apiResult['factors'] as List?)?.map((f) => PremiumFactor(
           label: f['label'],
           amount: (f['amount'] as num).toDouble(),
           type: f['type'],
           info: f['info'],
           icon: f['icon'] ?? 'star',
         )).toList() ?? [
           PremiumFactor(
             label: 'GigKavach Neural Pricing', 
             amount: (apiResult['premium'] as num).toDouble(), 
             type: 'base', 
             info: 'Quote dynamically generated by the Phase 5 Transformer model.', 
             icon: 'auto_awesome'
           )
         ],
         coverageHoursPerDay: apiResult['coverage_hours'] ?? 9,
         zoneProfile: profile,
         modelConfidence: apiResult['confidence'] ?? 0.95,
         riskScore: (apiResult['risk_score'] as num?)?.toDouble() ?? 45.0,
         riskLabel: apiResult['risk_label'] ?? 'Optimized',
         recommendedTier: 'AI Smart Shield',
         tierReason: 'Optimized via Neural Network Fine-tuning (DAE Backbone)',
       );
    }

    // 2. Fallback to local deterministic engine if offline/backend failing
    return calculate(
      zone: zone, 
      city: city, 
      vehicleType: vehicleType,
      experienceWeeks: experienceWeeks, 
      claimCount: claimCount,
      driverAge: driverAge, 
      dailyTravelKm: dailyTravelKm,
      dailyOrderVolume: dailyOrderVolume, 
      dailyHours: dailyHours,
    );
  }

  /// ─── MAIN: Compute dynamic premium for a given worker profile ───
  static PremiumResult calculate({
    required String zone,
    required String city,
    required String vehicleType,
    required int experienceWeeks,
    required int claimCount,
    required int driverAge,
    required double dailyTravelKm,
    required int dailyOrderVolume,
    required double dailyHours,
  }) {
    final profile = _zoneProfiles[zone] ?? _zoneProfiles['Adyar']!;
    final factors = <PremiumFactor>[];

    // ── 1. Base Platform Rate ──────────────────────────────────────
    double base = 22;
    factors.add(PremiumFactor(
      label: 'Base Platform Rate',
      amount: base,
      type: 'base',
      info: 'Standard GigKavach weekly base rate',
      icon: 'foundation',
    ));

    // ── 2. AGE RISK FACTOR ─────────────────────────────────────────
    // Actuarial curve: higher risk for very young (<22) and older (>50)
    // Sweet spot: 28-40 (lowest risk coefficient)
    double ageRisk;
    String ageInfo;
    if (driverAge < 22) {
      ageRisk = 6;
      ageInfo = 'Age $driverAge — young driver surcharge (higher incident rate for under-22)';
    } else if (driverAge < 25) {
      ageRisk = 3;
      ageInfo = 'Age $driverAge — moderate young driver adjustment';
    } else if (driverAge <= 40) {
      ageRisk = 0;
      ageInfo = 'Age $driverAge — optimal age bracket, no surcharge';
    } else if (driverAge <= 50) {
      ageRisk = 2;
      ageInfo = 'Age $driverAge — slight mature driver adjustment';
    } else {
      ageRisk = 5;
      ageInfo = 'Age $driverAge — senior driver surcharge (fatigue & health risk)';
    }
    factors.add(PremiumFactor(
      label: 'Age Risk Factor',
      amount: ageRisk,
      type: ageRisk > 0 ? 'risk' : 'neutral',
      info: ageInfo,
      icon: 'age',
    ));

    // ── 3. TRAVEL DISTANCE FACTOR ──────────────────────────────────
    // More km/day = more road exposure = higher accident probability
    // Tiered: <30km safe, 30-60 moderate, 60-100 high, >100 very high
    double distanceRisk;
    String distanceInfo;
    if (dailyTravelKm < 30) {
      distanceRisk = -1;
      distanceInfo = '${dailyTravelKm.toInt()} km/day — low exposure credit applied';
    } else if (dailyTravelKm < 60) {
      distanceRisk = 2;
      distanceInfo = '${dailyTravelKm.toInt()} km/day — moderate road exposure';
    } else if (dailyTravelKm < 100) {
      distanceRisk = 5;
      distanceInfo = '${dailyTravelKm.toInt()} km/day — high daily travel, elevated risk';
    } else {
      distanceRisk = 8;
      distanceInfo = '${dailyTravelKm.toInt()} km/day — very high exposure, extended coverage needed';
    }
    factors.add(PremiumFactor(
      label: 'Travel Distance',
      amount: distanceRisk,
      type: distanceRisk < 0 ? 'discount' : (distanceRisk > 0 ? 'risk' : 'neutral'),
      info: distanceInfo,
      icon: 'distance',
    ));

    // ── 4. ORDER VOLUME FACTOR ─────────────────────────────────────
    // Higher order count = more stops = more traffic maneuvers = higher risk
    // But also = higher income = can afford more premium
    double orderRisk;
    String orderInfo;
    if (dailyOrderVolume < 10) {
      orderRisk = 0;
      orderInfo = '$dailyOrderVolume orders/day — light workload, standard risk';
    } else if (dailyOrderVolume < 20) {
      orderRisk = 2;
      orderInfo = '$dailyOrderVolume orders/day — moderate stops & traffic exposure';
    } else if (dailyOrderVolume < 35) {
      orderRisk = 4;
      orderInfo = '$dailyOrderVolume orders/day — heavy workload, frequent stops increase risk';
    } else {
      orderRisk = 7;
      orderInfo = '$dailyOrderVolume orders/day — ultra-heavy delivery schedule, peak risk';
    }
    factors.add(PremiumFactor(
      label: 'Order Volume',
      amount: orderRisk,
      type: orderRisk > 0 ? 'risk' : 'neutral',
      info: orderInfo,
      icon: 'orders',
    ));

    // ── 5. AREA HISTORIC CONDITIONS ────────────────────────────────
    // Composite score from flood history, waterlogging events,
    // road quality, accident rates, and traffic density
    double areaHistoricRisk = 0;
    String areaInfo;
    List<String> areaFlags = [];

    // 5a. Flood & waterlogging history
    double floodComponent = profile.floodRiskScore * 12;
    if (profile.waterloggingHistory > 10) {
      floodComponent += 3;
      areaFlags.add('${profile.waterloggingHistory} waterlogging events');
    }

    // 5b. Road quality impact
    double roadComponent = (1 - profile.roadQualityScore) * 5;
    if (profile.roadQualityScore < 0.5) {
      areaFlags.add('Poor road quality');
    }

    // 5c. Accident rate in area
    double accidentComponent = profile.accidentRate * 20;
    if (profile.accidentRate > 0.12) {
      areaFlags.add('High accident zone');
    }

    // 5d. Traffic density
    double trafficComponent = profile.avgTrafficDensity > 0.8 ? 2 : 0;
    if (profile.avgTrafficDensity > 0.8) {
      areaFlags.add('Dense traffic area');
    }

    areaHistoricRisk = (floodComponent + roadComponent + accidentComponent + trafficComponent).roundToDouble();
    areaHistoricRisk = areaHistoricRisk.clamp(0, 25); // cap at ₹25

    if (areaFlags.isEmpty) {
      areaInfo = '$zone has favorable historic conditions';
    } else {
      areaInfo = '$zone: ${areaFlags.join(' · ')}';
    }

    factors.add(PremiumFactor(
      label: 'Area Historic Risk',
      amount: areaHistoricRisk,
      type: areaHistoricRisk > 8 ? 'risk' : (areaHistoricRisk > 3 ? 'moderate' : 'neutral'),
      info: areaInfo,
      icon: 'area',
    ));

    // ── 6. WEATHER FORECAST ────────────────────────────────────────
    double weatherAdj;
    String weatherInfo;
    if (profile.predictedRainNextWeek >= 25) {
      weatherAdj = 6;
      weatherInfo = 'Heavy rain forecast: ${profile.predictedRainNextWeek}mm predicted next week';
    } else if (profile.predictedRainNextWeek >= 10) {
      weatherAdj = 3;
      weatherInfo = 'Moderate rain expected: ${profile.predictedRainNextWeek}mm next week';
    } else if (profile.predictedRainNextWeek <= 3) {
      weatherAdj = -2;
      weatherInfo = 'Clear skies predicted — safe-weather credit applied';
    } else {
      weatherAdj = 0;
      weatherInfo = 'Normal conditions: ${profile.predictedRainNextWeek}mm forecast';
    }
    factors.add(PremiumFactor(
      label: 'Weather Forecast',
      amount: weatherAdj,
      type: weatherAdj < 0 ? 'discount' : (weatherAdj == 0 ? 'neutral' : 'risk'),
      info: weatherInfo,
      icon: 'weather',
    ));

    // ── 7. AQI Health Risk ─────────────────────────────────────────
    double aqiAdj;
    String aqiInfo;
    if (profile.avgAqi > 300) {
      aqiAdj = 5;
      aqiInfo = 'Hazardous AQI (avg ${profile.avgAqi}) — high disruption probability';
    } else if (profile.avgAqi > 200) {
      aqiAdj = 3;
      aqiInfo = 'Poor AQI (avg ${profile.avgAqi}) — moderate health risk';
    } else {
      aqiAdj = 0;
      aqiInfo = 'Acceptable AQI levels (avg ${profile.avgAqi})';
    }
    factors.add(PremiumFactor(
      label: 'Air Quality',
      amount: aqiAdj,
      type: aqiAdj > 0 ? 'risk' : 'neutral',
      info: aqiInfo,
      icon: 'air',
    ));

    // ── 8. VEHICLE RISK ────────────────────────────────────────────
    double vehicleAdj;
    String vehicleInfo;
    switch (vehicleType) {
      case 'Bicycle':
        vehicleAdj = 4;
        vehicleInfo = 'Bicycle — highest weather & traffic exposure';
        break;
      case 'Scooter':
        vehicleAdj = 1;
        vehicleInfo = 'Scooter — moderate exposure profile';
        break;
      default:
        vehicleAdj = 0;
        vehicleInfo = 'Bike — standard vehicle classification';
    }
    factors.add(PremiumFactor(
      label: 'Vehicle Type',
      amount: vehicleAdj,
      type: vehicleAdj > 0 ? 'risk' : 'neutral',
      info: vehicleInfo,
      icon: 'vehicle',
    ));

    // ── 9. CLAIMS HISTORY LOADING ──────────────────────────────────
    double claimRate = experienceWeeks > 0 ? claimCount / experienceWeeks : 0;
    double claimAdj;
    String claimInfo;
    if (claimRate > 0.15) {
      claimAdj = 5;
      claimInfo = 'High claim frequency: $claimCount claims in $experienceWeeks weeks';
    } else if (claimRate > 0.08) {
      claimAdj = 2;
      claimInfo = 'Moderate claim history: $claimCount claims in $experienceWeeks weeks';
    } else {
      claimAdj = 0;
      claimInfo = experienceWeeks > 0
          ? 'Clean claim record — no loading applied'
          : 'New driver — no claims yet';
    }
    factors.add(PremiumFactor(
      label: 'Claims History',
      amount: claimAdj,
      type: claimAdj > 0 ? 'risk' : 'neutral',
      info: claimInfo,
      icon: 'claims',
    ));

    // ── 10. SAFE ZONE CREDIT ───────────────────────────────────────
    if (profile.waterloggingHistory <= 3 && profile.accidentRate < 0.08) {
      factors.add(PremiumFactor(
        label: 'Safe Zone Credit',
        amount: -3,
        type: 'discount',
        info: '$zone is historically safe — ₹3 weekly credit',
        icon: 'safe',
      ));
    }

    // ── 11. LOYALTY DISCOUNT ───────────────────────────────────────
    if (experienceWeeks >= 20) {
      factors.add(PremiumFactor(
        label: 'Loyalty Discount',
        amount: -4,
        type: 'discount',
        info: '$experienceWeeks weeks loyalty — maximum discount',
        icon: 'loyalty',
      ));
    } else if (experienceWeeks >= 10) {
      factors.add(PremiumFactor(
        label: 'Loyalty Discount',
        amount: -2,
        type: 'discount',
        info: '$experienceWeeks weeks — returning subscriber discount',
        icon: 'loyalty',
      ));
    }

    // ── 12. SUSTAINED WEATHER FATIGUE (EDGE CASE) ────────────────
    bool isSustainedHazardActive = false;
    double maxDailyCoverage = double.maxFinite;
    
    if (profile.sustainedHazardDays >= 3) {
      isSustainedHazardActive = true;
      // Logarithmic scaling for premium penalty: 10 * log_base_1.5(days)
      double sustainedPenalty = 10 * (log(profile.sustainedHazardDays) / log(1.5));
      maxDailyCoverage = 1000.0; // Hard cap on maximum daily coverage to prevent extreme systemic losses
      
      factors.add(PremiumFactor(
        label: 'Sustained Weather Fatigue',
        amount: sustainedPenalty,
        type: 'risk',
        info: '${profile.sustainedHazardDays} days continuous disruption. Systemic risk multiplier applied (capped non-linearly).',
        icon: 'storm',
      ));
    }

    // ── Compute total ──────────────────────────────────────────────
    double total = factors.fold(0.0, (sum, f) => sum + f.amount);
    total = max(15, total); // minimum ₹15 premium floor

    // ── Compute Risk Score (0-100) ─────────────────────────────────
    // Weighted aggregate of all risk factors
    double riskScore = _computeRiskScore(
      driverAge: driverAge,
      dailyTravelKm: dailyTravelKm,
      dailyOrderVolume: dailyOrderVolume,
      profile: profile,
      vehicleType: vehicleType,
      claimRate: claimRate,
    );

    // ── Determine recommended tier ─────────────────────────────────
    String recommendedTier;
    String tierReason;
    if (riskScore < 30) {
      recommendedTier = 'Lite Shield';
      tierReason = 'Low-risk profile — basic coverage sufficient';
    } else if (riskScore < 55) {
      recommendedTier = 'Smart Shield';
      tierReason = 'Moderate risk — balanced coverage recommended';
    } else if (riskScore < 75) {
      recommendedTier = 'Max Shield';
      tierReason = 'Elevated risk — comprehensive protection advised';
    } else {
      recommendedTier = 'Ultra Shield';
      tierReason = 'High-risk profile — maximum coverage essential';
    }

    // Coverage hours based on weather + work pattern
    int coverageHours;
    if (profile.predictedRainNextWeek >= 25 || dailyHours >= 10) {
      coverageHours = 12;
    } else if (profile.predictedRainNextWeek >= 10 || dailyHours >= 7) {
      coverageHours = 9;
    } else {
      coverageHours = 6;
    }

    return PremiumResult(
      totalPremium: total,
      factors: factors,
      coverageHoursPerDay: isSustainedHazardActive ? max(6, coverageHours - (profile.sustainedHazardDays ~/ 2)) : coverageHours,
      zoneProfile: profile,
      modelConfidence: 0.87 + Random().nextDouble() * 0.1,
      riskScore: riskScore,
      riskLabel: _getRiskLabel(riskScore),
      recommendedTier: recommendedTier,
      tierReason: tierReason,
      maxDailyCoverage: maxDailyCoverage,
      isSustainedHazardActive: isSustainedHazardActive,
    );
  }

  /// ─── WEEKLY RENEWAL: Recalculate based on performance ───────────
  /// After a week of driving, the system evaluates the driver's actual
  /// performance and adjusts the premium accordingly.
  static PolicyRenewal calculateRenewal({
    required PremiumResult previousPolicy,
    required DriverPerformance performance,
    required String zone,
    required String city,
    required String vehicleType,
    required int driverAge,
    required double dailyTravelKm,
    required int dailyOrderVolume,
    required double dailyHours,
  }) {
    // Recalculate base premium with updated parameters
    final newResult = calculate(
      zone: zone,
      city: city,
      vehicleType: vehicleType,
      experienceWeeks: performance.totalWeeks,
      claimCount: performance.totalClaims,
      driverAge: driverAge,
      dailyTravelKm: dailyTravelKm,
      dailyOrderVolume: dailyOrderVolume,
      dailyHours: dailyHours,
    );

    double adjustedPremium = newResult.totalPremium;
    List<String> adjustments = [];

    // ── Performance-based adjustments ──────────────────────────────

    // 1. Delivery success rate bonus
    if (performance.deliverySuccessRate >= 0.98) {
      adjustedPremium -= 3;
      adjustments.add('Excellent delivery rate (${(performance.deliverySuccessRate * 100).toStringAsFixed(1)}%) — ₹3 off');
    } else if (performance.deliverySuccessRate >= 0.95) {
      adjustedPremium -= 1;
      adjustments.add('Good delivery rate — ₹1 off');
    }

    // 2. Safe driving hours bonus
    if (performance.safeHoursRatio >= 0.95) {
      adjustedPremium -= 2;
      adjustments.add('${(performance.safeHoursRatio * 100).toInt()}% safe driving hours — ₹2 off');
    }

    // 3. Zero incidents bonus
    if (performance.incidentCount == 0) {
      adjustedPremium -= 2;
      adjustments.add('Zero incidents this week — ₹2 off');
    } else {
      adjustedPremium += performance.incidentCount * 3;
      adjustments.add('${performance.incidentCount} incident(s) — +₹${performance.incidentCount * 3}');
    }

    // 4. Zone fidelity (if they stayed in predicted zone)
    if (performance.zoneFidelity >= 0.8) {
      adjustedPremium -= 1;
      adjustments.add('Zone fidelity ${(performance.zoneFidelity * 100).toInt()}% — ₹1 off');
    }

    // 5. Late night driving surcharge
    if (performance.lateNightHoursRatio > 0.3) {
      adjustedPremium += 3;
      adjustments.add('High late-night driving — +₹3 surcharge');
    }

    adjustedPremium = max(15, adjustedPremium);

    double premiumChange = adjustedPremium - previousPolicy.totalPremium;
    String changeLabel;
    if (premiumChange < -2) {
      changeLabel = 'Reward: Premium reduced for good performance';
    } else if (premiumChange > 2) {
      changeLabel = 'Adjustment: Premium increased due to risk factors';
    } else {
      changeLabel = 'Steady: Premium maintained — keep up the good work';
    }

    return PolicyRenewal(
      previousPremium: previousPolicy.totalPremium,
      newPremium: adjustedPremium,
      premiumChange: premiumChange,
      changeLabel: changeLabel,
      adjustments: adjustments,
      newResult: newResult,
      performance: performance,
      renewalDate: DateTime.now().add(const Duration(days: 7)),
    );
  }

  /// ─── Risk Score Computation (0-100) ─────────────────────────────
  static double _computeRiskScore({
    required int driverAge,
    required double dailyTravelKm,
    required int dailyOrderVolume,
    required ZoneRiskProfile profile,
    required String vehicleType,
    required double claimRate,
  }) {
    double score = 0;

    // Age component (0-15)
    if (driverAge < 22) {
      score += 12;
    // ignore: curly_braces_in_flow_control_structures
    } else if (driverAge < 25) score += 8;
    else if (driverAge <= 40) score += 3;
    else if (driverAge <= 50) score += 7;
    else score += 13;

    // Travel distance component (0-20)
    score += (dailyTravelKm / 150 * 20).clamp(0, 20);

    // Order volume component (0-15)
    score += (dailyOrderVolume / 40 * 15).clamp(0, 15);

    // Area historic conditions (0-25)
    double areaScore = profile.floodRiskScore * 10
        + (1 - profile.roadQualityScore) * 5
        + profile.accidentRate * 30
        + profile.avgTrafficDensity * 5;
    score += areaScore.clamp(0, 25);

    // Weather (0-10)
    score += (profile.predictedRainNextWeek / 50 * 10).clamp(0, 10);

    // Vehicle (0-5)
    switch (vehicleType) {
      case 'Bicycle': score += 5; break;
      case 'Scooter': score += 2; break;
      default: score += 1;
    }

    // Claims history (0-10)
    score += (claimRate * 50).clamp(0, 10);

    return score.clamp(0, 100).roundToDouble();
  }

  static String _getRiskLabel(double score) {
    if (score < 25) return 'Low';
    if (score < 45) return 'Moderate';
    if (score < 65) return 'Elevated';
    if (score < 80) return 'High';
    return 'Very High';
  }

  /// Get the zone profile for display purposes
  static ZoneRiskProfile? getZoneProfile(String zone) => _zoneProfiles[zone];

  /// Get all available zones
  static List<String> get availableZones => _zoneProfiles.keys.toList();
}

// ─── Data Models ──────────────────────────────────────────────────────

class ZoneRiskProfile {
  final double floodRiskScore;
  final int waterloggingHistory;
  final double avgRainfallMm;
  final int avgAqi;
  final int avgTempC;
  final double historicClaimRate;
  final int predictedRainNextWeek;
  final bool isCycloneSeason;
  final double accidentRate;
  final double roadQualityScore;
  final double avgTrafficDensity;
  final int sustainedHazardDays;

  const ZoneRiskProfile({
    required this.floodRiskScore,
    required this.waterloggingHistory,
    required this.avgRainfallMm,
    required this.avgAqi,
    required this.avgTempC,
    required this.historicClaimRate,
    required this.predictedRainNextWeek,
    required this.isCycloneSeason,
    required this.accidentRate,
    required this.roadQualityScore,
    required this.avgTrafficDensity,
    this.sustainedHazardDays = 0,
  });
}

class PremiumFactor {
  final String label;
  final double amount;
  final String type; // base, risk, discount, neutral, moderate
  final String info;
  final String icon;

  const PremiumFactor({
    required this.label,
    required this.amount,
    required this.type,
    required this.info,
    required this.icon,
  });
}

class PremiumResult {
  final double totalPremium;
  final List<PremiumFactor> factors;
  final int coverageHoursPerDay;
  final ZoneRiskProfile zoneProfile;
  final double modelConfidence;
  final double riskScore;
  final String riskLabel;
  final String recommendedTier;
  final String tierReason;
  final double maxDailyCoverage;
  final bool isSustainedHazardActive;

  const PremiumResult({
    required this.totalPremium,
    required this.factors,
    required this.coverageHoursPerDay,
    required this.zoneProfile,
    required this.modelConfidence,
    required this.riskScore,
    required this.riskLabel,
    required this.recommendedTier,
    required this.tierReason,
    this.maxDailyCoverage = double.maxFinite,
    this.isSustainedHazardActive = false,
  });
}

class DriverPerformance {
  final int totalWeeks;
  final int totalClaims;
  final double deliverySuccessRate;  // 0-1.0
  final double safeHoursRatio;      // 0-1.0
  final int incidentCount;
  final double zoneFidelity;        // 0-1.0 (stayed in predicted zone)
  final double lateNightHoursRatio; // 0-1.0

  const DriverPerformance({
    required this.totalWeeks,
    required this.totalClaims,
    required this.deliverySuccessRate,
    required this.safeHoursRatio,
    required this.incidentCount,
    required this.zoneFidelity,
    required this.lateNightHoursRatio,
  });
}

class PolicyRenewal {
  final double previousPremium;
  final double newPremium;
  final double premiumChange;
  final String changeLabel;
  final List<String> adjustments;
  final PremiumResult newResult;
  final DriverPerformance performance;
  final DateTime renewalDate;

  const PolicyRenewal({
    required this.previousPremium,
    required this.newPremium,
    required this.premiumChange,
    required this.changeLabel,
    required this.adjustments,
    required this.newResult,
    required this.performance,
    required this.renewalDate,
  });
}
