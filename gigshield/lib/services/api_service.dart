import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/mock_data.dart';

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// GigKavach — Mobile API Bridge
/// All requests go through the API Gateway (port 8000).
/// The gateway routes to internal services — the app never calls them directly.
class GigKavachApiService {
  // API Gateway URL — handles Android emulator 10.0.2.2 trick automatically
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    } else {
      return 'http://localhost:8000/api/v1';
    }
  }

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
      ).timeout(const Duration(seconds: 2));
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
      ).timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _authToken = data['access_token'];
        return data;
      }
    } catch (e) {
      print('API Error (Login): $e');
    }
    // DEMO FALLBACK: Allow dummy OTPs to work if backend is unavailable or fails
    _authToken = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';
    MockData.loadProfileForPhone(phone);
    return {
      'access_token': _authToken, 
      'status': 'success',
      'message': 'Demo login successful'
    };
  }

  static Future<Map<String, dynamic>> startKyc() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/kyc/start'),
        headers: _headers,
      ).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('API Error (Start KYC): $e');
    }
    return {'status': 'error', 'session_id': null};
  }

  static Future<Map<String, dynamic>> getKycStatus(String sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/kyc/$sessionId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('API Error (Get KYC Status): $e');
    }
    return {'status': 'error'};
  }

  static Future<Map<String, dynamic>> verifyPanIdentity(String sessionId, String panNumber, String dob, String fullName) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/kyc/$sessionId/identity'),
        headers: _headers,
        body: jsonEncode({
          'pan_number': panNumber,
          'date_of_birth': dob,
          'full_name': fullName,
        }),
      ).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('API Error (PAN Identity): $e');
    }
    return {'status': 'error', 'verified': false};
  }

  static Future<Map<String, dynamic>> initDigiLockerConsent(String sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/kyc/$sessionId/consent'),
        headers: _headers,
      ).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('API Error (DigiLocker Consent): $e');
    }
    return {'status': 'error'};
  }

  static Future<Map<String, dynamic>> sendAadhaarOtp(String sessionId, String aadhaarNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/kyc/$sessionId/aadhaar'),
        headers: _headers,
        body: jsonEncode({
          'aadhaar_number': aadhaarNumber,
        }),
      ).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('API Error (Aadhaar OTP): $e');
    }
    return {'status': 'error'};
  }

  static Future<Map<String, dynamic>> completeKyc({
    required String sessionId,
    required String panNumber,
    required String aadhaarLast4,
    required String aadhaarOtp,
    required String consentTimestamp,
    required String consentIp,
    required String selfieHash,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/kyc/$sessionId/complete'),
        headers: _headers,
        body: jsonEncode({
          'session_id': sessionId,
          'pan_number': panNumber,
          'aadhaar_last4': aadhaarLast4,
          'aadhaar_otp': aadhaarOtp,
          'consent_timestamp': consentTimestamp,
          'consent_ip': consentIp,
          'selfie_hash': selfieHash,
        }),
      ).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('API Error (Complete KYC): $e');
    }
    return {
      'kyc_status': 'FAILED',
      'provider': 'mock',
      'environment': 'development'
    };
  }

  // ── Platform Integration ──

  static Future<Map<String, dynamic>> linkPlatform(String platformName) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/platform/link'),
        headers: _headers,
        body: jsonEncode({'platform_name': platformName}),
      ).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('API Error (Platform Link): $e');
    }
    return {'status': 'error'};
  }

  static Future<Map<String, dynamic>> verifyPlatformLogin(String sessionId, String phone, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/platform/$sessionId/verify'),
        headers: _headers,
        body: jsonEncode({'phone': phone, 'otp': otp}),
      ).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('API Error (Platform Verify): $e');
    }
    return {'status': 'error'};
  }

  static Future<Map<String, dynamic>> syncPlatformData(String sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/platform/$sessionId/sync'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('API Error (Platform Sync): $e');
    }
    return {'status': 'error'};
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
