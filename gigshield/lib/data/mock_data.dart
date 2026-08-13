// Comprehensive mock data for GigKavach Phase 2
// Simulates backend responses for all features

class MockData {
  // ─── Worker Profile ─────────────────────────────────────────────
  static String workerName = 'Ravi Kumar';
  static String workerId = 'GK-28471';
  static String workerCity = 'Chennai';
  static String workerZone = 'Adyar';
  static String workerPhone = '+91 98765 43210';
  static String workerPlatform = 'Swiggy';
  static String workerVehicle = 'Bike';
  static int experienceWeeks = 24;
  static bool isRegistered = true;

  // ─── Earnings ───────────────────────────────────────────────────
  static double todayEarnings = 847.0;
  static double weekEarnings = 3420.0;
  static double monthEarnings = 14850.0;
  static double avgWeeklyIncome = 4200.0;
  static double avgHourlyIncome = 70.0;

  static Map<String, double> platformEarnings = {
    'Swiggy': 2150.0,
    'Zomato': 890.0,
  };

  static List<double> weeklyDailyEarnings = [
    620,
    780,
    430,
    910,
    540,
    847,
    0,
  ];
  static const List<String> weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  // ─── Insurance Policy ───────────────────────────────────────────
  static double weeklyPremium = 45.0;
  static double coverageCeiling = 2940.0;
  static bool isCovered = true;
  static int policyDaysRemaining = 4;
  static String policyId = 'POL-GK-2026-0847';
  static String policyStatus = 'Active';
  static String policyStartDate = '15 Mar 2026';
  static String policyEndDate = '22 Mar 2026';
  static String policyTier = 'Standard';
  static double coveragePercentage = 70.0;
  static int totalClaimsPaid = 3;
  static double totalPayoutsReceived = 1330.0;

  // Premium Breakdown (Phase 2 — Dynamic)
  static double basePremium = 25.0;
  static double zoneRiskAdjustment = 12.0;
  static double weatherAdjustment = 8.0;
  static double claimsHistoryFactor = 3.0;
  static double loyaltyDiscount = 3.0;

  // Premium factors with explanations
  static List<Map<String, dynamic>> premiumFactors = [
    {
      'label': 'Base Rate (Standard)',
      'amount': 25.0,
      'type': 'base',
      'info': 'Standard plan base rate',
    },
    {
      'label': 'Zone Risk (Adyar)',
      'amount': 12.0,
      'type': 'add',
      'info': 'Moderate flood risk zone - ML Risk Score: 65/100',
    },
    {
      'label': 'Weather Forecast',
      'amount': 8.0,
      'type': 'add',
      'info': 'Light rain predicted this week',
    },
    {
      'label': 'Claims History',
      'amount': 3.0,
      'type': 'add',
      'info': '3 claims in 24 weeks = low frequency',
    },
    {
      'label': 'Loyalty Discount',
      'amount': -3.0,
      'type': 'discount',
      'info': '24 weeks continuous subscriber',
    },
  ];

  // ─── Policy History ─────────────────────────────────────────────
  static List<Map<String, dynamic>> policyHistory = [
    {
      'id': 'POL-GK-2026-0847',
      'period': 'Mar 15 - Mar 22',
      'tier': 'Standard',
      'premium': 45.0,
      'status': 'Active',
      'claims': 0,
    },
    {
      'id': 'POL-GK-2026-0732',
      'period': 'Mar 8 - Mar 15',
      'tier': 'Standard',
      'premium': 42.0,
      'status': 'Completed',
      'claims': 1,
    },
    {
      'id': 'POL-GK-2026-0618',
      'period': 'Mar 1 - Mar 8',
      'tier': 'Standard',
      'premium': 48.0,
      'status': 'Completed',
      'claims': 1,
    },
    {
      'id': 'POL-GK-2026-0504',
      'period': 'Feb 22 - Mar 1',
      'tier': 'Standard',
      'premium': 40.0,
      'status': 'Completed',
      'claims': 1,
    },
    {
      'id': 'POL-GK-2026-0390',
      'period': 'Feb 15 - Feb 22',
      'tier': 'Basic',
      'premium': 28.0,
      'status': 'Completed',
      'claims': 0,
    },
  ];

  // ─── Regulatory Info ────────────────────────────────────────────
  static List<String> exclusions = [
    'Self-inflicted disruption or injury',
    'Disruptions during non-working hours (11 PM - 5 AM)',
    'Pre-existing platform bans or suspensions',
    'Disruptions in zones outside subscribed coverage area',
    'Claims filed more than 48 hours after the event',
    'Intoxication during work hours',
    'Fraudulent claims or GPS spoofing',
  ];

  static String coolingOffPeriod = '7 days';
  static String grievanceEmail = 'support@gigkavach.in';
  static String grievancePhone = '1800-GIG-HELP';

  // ─── Claims Management ──────────────────────────────────────────
  static List<Map<String, dynamic>> claimsHistory = [
    {
      'id': 'CLM-100847',
      'date': '12 Mar 2026',
      'type': 'Heavy Rainfall',
      'amount': 420.0,
      'status': 'Paid',
      'hours': 6.0,
      'confidenceScore': 92,
      'triggerData': 'Rainfall: 48mm in 6hrs at Adyar zone',
      'timeline': [
        {
          'time': '2:15 PM',
          'event': 'Trigger detected: Heavy rainfall > 40mm',
          'status': 'detected',
        },
        {'time': '2:16 PM', 'event': 'Auto-claim created', 'status': 'created'},
        {
          'time': '2:17 PM',
          'event': 'Fraud validation: Score 92/100',
          'status': 'validated',
        },
        {
          'time': '2:18 PM',
          'event': 'Payout calculated: 6hrs \u00d7 \u20b970/hr \u00d7 70%',
          'status': 'calculated',
        },
        {
          'time': '2:22 PM',
          'event': 'Payout processed via UPI',
          'status': 'paid',
        },
      ],
    },
    {
      'id': 'CLM-100632',
      'date': '28 Feb 2026',
      'type': 'Severe AQI',
      'amount': 350.0,
      'status': 'Paid',
      'hours': 5.0,
      'confidenceScore': 88,
      'triggerData': 'AQI: 385 for 4 consecutive hours at Adyar',
      'timeline': [
        {
          'time': '10:30 AM',
          'event': 'Trigger detected: AQI > 350 for 3+ hours',
          'status': 'detected',
        },
        {
          'time': '10:31 AM',
          'event': 'Auto-claim created',
          'status': 'created',
        },
        {
          'time': '10:32 AM',
          'event': 'Fraud validation: Score 88/100',
          'status': 'validated',
        },
        {
          'time': '10:33 AM',
          'event': 'Payout calculated: 5hrs \u00d7 \u20b970/hr \u00d7 70%',
          'status': 'calculated',
        },
        {
          'time': '10:38 AM',
          'event': 'Payout processed via UPI',
          'status': 'paid',
        },
      ],
    },
    {
      'id': 'CLM-100418',
      'date': '15 Feb 2026',
      'type': 'Flooding',
      'amount': 560.0,
      'status': 'Paid',
      'hours': 8.0,
      'confidenceScore': 95,
      'triggerData': 'Active flood alert + 62mm rainfall at Adyar',
      'timeline': [
        {
          'time': '4:00 PM',
          'event': 'Trigger detected: IMD flood warning for Adyar',
          'status': 'detected',
        },
        {'time': '4:01 PM', 'event': 'Auto-claim created', 'status': 'created'},
        {
          'time': '4:02 PM',
          'event': 'Fraud validation: Score 95/100',
          'status': 'validated',
        },
        {
          'time': '4:03 PM',
          'event': 'Payout calculated: 8hrs \u00d7 \u20b970/hr \u00d7 70%',
          'status': 'calculated',
        },
        {
          'time': '4:06 PM',
          'event': 'Payout processed via UPI',
          'status': 'paid',
        },
      ],
    },
  ];

  // ─── Active Triggers (Simulated Live Status) ────────────────────
  static List<Map<String, dynamic>> activeTriggers = [
    {
      'id': 'rain',
      'icon': 'water_drop',
      'label': 'Heavy Rainfall',
      'threshold': '>40mm in 6hrs',
      'currentValue': '12mm',
      'status': 'monitoring',
      'source': 'OpenWeather API',
      'lastChecked': '2 min ago',
      'riskLevel': 0.3,
    },
    {
      'id': 'aqi',
      'icon': 'air',
      'label': 'Severe AQI',
      'threshold': '>350 for 3hrs',
      'currentValue': 'AQI 142',
      'status': 'monitoring',
      'source': 'AQICN API',
      'lastChecked': '5 min ago',
      'riskLevel': 0.15,
    },
    {
      'id': 'flood',
      'icon': 'waves',
      'label': 'Flood Alert',
      'threshold': 'Active IMD alert',
      'currentValue': 'No alerts',
      'status': 'safe',
      'source': 'IMD Alert Feed',
      'lastChecked': '15 min ago',
      'riskLevel': 0.0,
    },
    {
      'id': 'civic',
      'icon': 'block',
      'label': 'Civic Disruption',
      'threshold': 'Zone closure/bandh',
      'currentValue': 'All clear',
      'status': 'safe',
      'source': 'News API + Traffic',
      'lastChecked': '30 min ago',
      'riskLevel': 0.0,
    },
    {
      'id': 'heat',
      'icon': 'thermostat',
      'label': 'Extreme Heat',
      'threshold': '>43\u00b0C during work hours',
      'currentValue': '34\u00b0C',
      'status': 'monitoring',
      'source': 'OpenWeather API',
      'lastChecked': '2 min ago',
      'riskLevel': 0.15,
    },
  ];

  // ─── Wallet ─────────────────────────────────────────────────────
  static double walletBalance = 385.0;
  static double autoDeductionPerDay = 10.0;

  static List<Map<String, dynamic>> walletTransactions = [
    {
      'date': 'Today',
      'desc': 'Auto-save from earnings',
      'amount': 10.0,
      'type': 'credit',
    },
    {
      'date': 'Yesterday',
      'desc': 'Weekly premium paid (Standard)',
      'amount': -45.0,
      'type': 'debit',
    },
    {
      'date': 'Yesterday',
      'desc': 'Auto-save from earnings',
      'amount': 10.0,
      'type': 'credit',
    },
    {
      'date': '17 Mar',
      'desc': 'Claim payout: Heavy Rainfall',
      'amount': 420.0,
      'type': 'credit',
    },
    {
      'date': '16 Mar',
      'desc': 'Auto-save from earnings',
      'amount': 10.0,
      'type': 'credit',
    },
    {
      'date': '15 Mar',
      'desc': 'Auto-save from earnings',
      'amount': 10.0,
      'type': 'credit',
    },
    {
      'date': '14 Mar',
      'desc': 'Weekly premium paid (Standard)',
      'amount': -42.0,
      'type': 'debit',
    },
  ];

  static void addTransaction({
    required double amount,
    required String desc,
    required String type,
  }) {
    walletTransactions.insert(0, {
      'date': 'Just Now',
      'desc': desc,
      'amount': amount,
      'type': type,
    });
    walletBalance += amount;
  }

  // ─── Stability Score ────────────────────────────────────────────
  static int stabilityScore = 62;
  static double earningsConsistency = 68.0;
  static double riskExposure = 55.0;
  static double insuranceUtil = 80.0;
  static double savingsBehavior = 45.0;

  // ─── Work Decision ──────────────────────────────────────────────
  static int decisionScore = 72;
  static String decisionLabel = 'GO';
  static double demandScore = 78.0;
  static double weatherSafety = 65.0;
  static double coverageBonus = 80.0;
  static double historicalStability = 60.0;

  // ─── Boost Recommendations ──────────────────────────────────────
  static List<Map<String, dynamic>> boostZones = [
    {
      'zone': 'Velachery',
      'score': 92,
      'peakTime': '7:30 - 9:30 PM',
      'estimatedBoost': '+28%',
      'distance': '3.2 km',
    },
    {
      'zone': 'T. Nagar',
      'score': 85,
      'peakTime': '12:00 - 2:00 PM',
      'estimatedBoost': '+22%',
      'distance': '5.1 km',
    },
    {
      'zone': 'Anna Nagar',
      'score': 78,
      'peakTime': '6:00 - 8:00 PM',
      'estimatedBoost': '+18%',
      'distance': '8.4 km',
    },
    {
      'zone': 'Mylapore',
      'score': 71,
      'peakTime': '11:00 AM - 1:00 PM',
      'estimatedBoost': '+15%',
      'distance': '2.8 km',
    },
  ];

  // ─── Risk Zones ─────────────────────────────────────────────────
  static List<Map<String, dynamic>> riskZones = [
    {'zone': 'Adyar', 'risk': 65, 'label': 'Moderate', 'rain': '12mm'},
    {'zone': 'Velachery', 'risk': 35, 'label': 'Low', 'rain': '2mm'},
    {'zone': 'T. Nagar', 'risk': 25, 'label': 'Low', 'rain': '0mm'},
    {'zone': 'Mylapore', 'risk': 72, 'label': 'High', 'rain': '28mm'},
    {'zone': 'Anna Nagar', 'risk': 18, 'label': 'Low', 'rain': '0mm'},
    {'zone': 'Guindy', 'risk': 55, 'label': 'Moderate', 'rain': '8mm'},
    {'zone': 'Porur', 'risk': 82, 'label': 'High', 'rain': '35mm'},
    {'zone': 'Tambaram', 'risk': 90, 'label': 'Critical', 'rain': '42mm'},
  ];

  // ─── Weekly Forecast ────────────────────────────────────────────
  static List<Map<String, dynamic>> weekForecast = [
    {'day': 'Thu', 'risk': 30, 'rain': '2mm', 'demand': 'High'},
    {'day': 'Fri', 'risk': 45, 'rain': '8mm', 'demand': 'Medium'},
    {'day': 'Sat', 'risk': 75, 'rain': '25mm', 'demand': 'Low'},
    {'day': 'Sun', 'risk': 60, 'rain': '15mm', 'demand': 'Medium'},
    {'day': 'Mon', 'risk': 20, 'rain': '0mm', 'demand': 'High'},
    {'day': 'Tue', 'risk': 15, 'rain': '0mm', 'demand': 'High'},
    {'day': 'Wed', 'risk': 35, 'rain': '5mm', 'demand': 'High'},
  ];

  // ─── Insurance Plans (for catalog) ──────────────────────────────
  static List<Map<String, dynamic>> insurancePlans = [
    {
      'name': 'Basic',
      'price': 25,
      'coverage': 50,
      'triggers': 3,
      'description': 'Essential protection for weather disruptions',
      'features': ['Heavy Rainfall', 'Severe AQI', 'Extreme Heat'],
    },
    {
      'name': 'Standard',
      'price': 45,
      'coverage': 70,
      'triggers': 5,
      'description': 'Complete income protection with all triggers',
      'features': [
        'All Basic triggers',
        'Flooding',
        'Civic Disruption',
        'Priority payouts',
      ],
    },
    {
      'name': 'Premium',
      'price': 65,
      'coverage': 85,
      'triggers': 5,
      'description': 'Maximum protection with instant payouts',
      'features': [
        'All Standard triggers',
        '85% coverage',
        'Instant payouts',
        'Predictive alerts',
        'Dedicated support',
      ],
    },
  ];

  // ─── Profile Loading Logic ───────────────────────────────────────
  static void loadProfileForPhone(String phone) {
    if (phone.contains('9999999999')) {
      // Demo Admin Profile: Fully populated with policies and claims
      workerName = 'Varad Singhal (Admin)';
      workerPhone = '+91 99999 99999';
      isCovered = true;
      policyStatus = 'Active';
      policyTier = 'Standard';
      totalClaimsPaid = 3;
      totalPayoutsReceived = 1330.0;
      walletBalance = 1585.0;
      stabilityScore = 88;
      
      todayEarnings = 847.0;
      weekEarnings = 3420.0;
      monthEarnings = 14850.0;
      weeklyDailyEarnings = [620, 780, 430, 890, 700, 0, 0];
      platformEarnings = {'Swiggy': 2150.0, 'Zomato': 890.0};
      decisionScore = 72;
      decisionLabel = 'GO';
      
      activeTriggers = [
        {'id': 'rain', 'icon': 'water_drop', 'label': 'Heavy Rain', 'value': '45mm/hr', 'color': 0xFF2196F3},
        {'id': 'aqi', 'icon': 'air', 'label': 'Severe AQI', 'value': '342', 'color': 0xFFF44336},
      ];
      boostZones = [
        {'zone': 'Velachery', 'score': 92, 'bonus': '+₹45/hr', 'trend': 'up', 'icon': 'trending_up'},
        {'zone': 'Adyar', 'score': 85, 'bonus': '+₹30/hr', 'trend': 'stable', 'icon': 'trending_flat'},
      ];
      riskZones = [
        {'zone': 'Adyar', 'risk': 65, 'label': 'Moderate', 'rain': '12mm'},
        {'zone': 'Velachery', 'risk': 35, 'label': 'Low', 'rain': '2mm'},
      ];

      claimsHistory = [
        {
          'id': 'CLM-100847', 'date': '12 Mar 2026', 'type': 'Heavy Rainfall', 'amount': 420.0,
          'status': 'Paid', 'hours': 6.0, 'confidenceScore': 92, 'triggerData': 'Rainfall: 48mm in 6hrs at Adyar zone',
          'timeline': [
            {'time': '2:15 PM', 'event': 'Trigger detected: Heavy rainfall > 40mm', 'status': 'detected'},
            {'time': '2:16 PM', 'event': 'Auto-claim created', 'status': 'created'},
            {'time': '2:17 PM', 'event': 'Fraud validation: Score 92/100', 'status': 'validated'},
            {'time': '2:18 PM', 'event': 'Payout calculated: 6hrs \u00d7 \u20b970/hr \u00d7 70%', 'status': 'calculated'},
            {'time': '2:22 PM', 'event': 'Payout processed via UPI', 'status': 'paid'},
          ],
        }
      ];

      policyHistory = [
        {'id': 'POL-GK-2026-0847', 'period': 'Mar 15 - Mar 22', 'tier': 'Standard', 'premium': 45.0, 'status': 'Active', 'claims': 0},
        {'id': 'POL-GK-2026-0732', 'period': 'Mar 8 - Mar 15', 'tier': 'Standard', 'premium': 42.0, 'status': 'Completed', 'claims': 1},
      ];

    } else {
      // New User Profile: Blank slate for underwriting demonstration
      workerName = 'New User';
      workerPhone = phone;
      isCovered = false;
      policyStatus = 'Not Active';
      policyTier = 'None';
      totalClaimsPaid = 0;
      totalPayoutsReceived = 0.0;
      walletBalance = 0.0;
      stabilityScore = 20;
      
      // Clean UI: No dummy earnings or triggers for new users
      todayEarnings = 0.0;
      weekEarnings = 0.0;
      monthEarnings = 0.0;
      weeklyDailyEarnings = [0, 0, 0, 0, 0, 0, 0];
      platformEarnings = {};
      decisionScore = 50;
      decisionLabel = 'N/A';
      
      activeTriggers = [];
      boostZones = [];
      riskZones = [];
      
      claimsHistory = [];
      policyHistory = [];
      walletTransactions = [];
    }
  }
}
