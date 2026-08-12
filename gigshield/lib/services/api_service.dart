import 'dart:convert';
import 'package:http/http.dart' as http;

/// GigKavach — Mobile API Bridge
/// All requests go through the API Gateway (port 8000).
/// The gateway routes to internal services — the app never calls them directly.
class GigKavachApiService {
  // API Gateway URL — change to your machine's local IP for physical device testing
  static const String baseUrl = 'http://localhost:8000/api/v1';

  static String? _authToken;

  /// Set the auth token after login
  static void setAuthToken(String token) {
    _authToken = token;
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // ── Auth ──

  static Future<Map<String, dynamic>> requestOtp(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/request-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('API Error (Request OTP): $e');
    }
    return {'error': 'Failed to request OTP'};
  }

  static Future<Map<String, dynamic>> login(String phone, {String? otp}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'otp': otp}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _authToken = data['access_token'];
        return data;
      }
    } catch (e) {
      print('API Error (Login): $e');
    }
    return {'error': 'Login failed'};
  }

  static Future<Map<String, dynamic>> verifyKyc(String documentType, String documentNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/kyc/verify'),
        headers: _headers,
        body: jsonEncode({
          'document_type': documentType,
          'document_number': documentNumber,
        }),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('API Error (KYC): $e');
    }
    return {'error': 'KYC verification failed'};
  }

  // ── Workers ──

  static Future<Map<String, dynamic>> getWorkerProfile(String workerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/workers/$workerId'),
        headers: _headers,
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('API Error (Worker): $e');
    }
    return {};
  }

  // ── Earnings ──

  static Future<Map<String, dynamic>> getEarningsSummary(String workerId, {int days = 30}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/earnings/summary/$workerId?days=$days'),
        headers: _headers,
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('API Error (Earnings): $e');
    }
    return {'platforms': {}, 'totals': {}};
  }

  static Future<Map<String, dynamic>> getDailyEarnings(String workerId, {int days = 14}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/earnings/daily/$workerId?days=$days'),
        headers: _headers,
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('API Error (Daily Earnings): $e');
    }
    return {'daily': []};
  }

  static Future<Map<String, dynamic>> getBoostRecommendations({String city = 'Chennai'}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/earnings/boost?city=$city'),
        headers: _headers,
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('API Error (Boost): $e');
    }
    return {'recommendations': []};
  }

  // ── Decision ──

  static Future<Map<String, dynamic>> getDecisionScore(String workerId, {String? h3Zone, String city = 'Chennai'}) async {
    try {
      final zone = h3Zone ?? '872a10d83ffffff';
      final response = await http.get(
        Uri.parse('$baseUrl/decision/score/$workerId?h3_zone=$zone&city=$city'),
        headers: _headers,
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('API Error (Decision): $e');
    }
    return {'composite_score': 0, 'recommendation': 'UNKNOWN'};
  }

  // ── Claims ──

  static Future<Map<String, dynamic>> getClaims({String? workerId}) async {
    try {
      final params = workerId != null ? '?worker_id=$workerId' : '';
      final response = await http.get(
        Uri.parse('$baseUrl/claims/$params'),
        headers: _headers,
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('API Error (Claims): $e');
    }
    return {'claims': [], 'total': 0};
  }

  // ── Policies ──

  static Future<Map<String, dynamic>> getPolicies({String? workerId}) async {
    try {
      final params = workerId != null ? '?worker_id=$workerId' : '';
      final response = await http.get(
        Uri.parse('$baseUrl/policies/$params'),
        headers: _headers,
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('API Error (Policies): $e');
    }
    return {'policies': [], 'total': 0};
  }

  // ── Risk ──

  static Future<Map<String, dynamic>> getZoneRisk(String h3Zone) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/risk/zone/$h3Zone'),
        headers: _headers,
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('API Error (Risk): $e');
    }
    return {'risk_score': 50, 'risk_label': 'Unknown'};
  }

  // ── Premium ──

  static Future<Map<String, dynamic>> calculatePremium({
    required String workerId,
    required String h3Zone,
    String city = 'Chennai',
    double avgWeeklyIncome = 4200,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/premium/calculate'),
        headers: _headers,
        body: jsonEncode({
          'worker_id': workerId,
          'h3_zone': h3Zone,
          'city': city,
          'avg_weekly_income': avgWeeklyIncome,
        }),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('API Error (Premium): $e');
    }
    return {'weekly_premium': 0};
  }

  // ── Triggers ──

  static Future<Map<String, dynamic>> getTriggerStatus(String h3Zone, {String city = 'Chennai'}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/triggers/status?h3_zone=$h3Zone&city=$city'),
        headers: _headers,
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('API Error (Triggers): $e');
    }
    return {'triggers': []};
  }

  // ── Legacy compatibility ──

  static Future<Map<String, dynamic>> getPremiumQuote({
    required String workerId,
    required String zone,
    required String city,
    required String vehicleType,
  }) async {
    return calculatePremium(workerId: workerId, h3Zone: zone, city: city);
  }

  static Future<Map<String, dynamic>> verifyAndSubmitClaim(Map<String, dynamic> claimData) async {
    return getClaims(workerId: claimData['worker_id'] as String?);
  }

  static Future<Map<String, dynamic>> getWorkerDashboard(String workerId) async {
    return getWorkerProfile(workerId);
  }

  static Future<List<dynamic>> getNotifications() async {
    return [];
  }
}
