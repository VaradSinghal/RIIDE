import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

import '../services/supabase_service.dart';
import '../services/premium_engine.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RegistrationScreen extends StatefulWidget {
  final void Function(BuildContext) onRegistrationComplete;
  const RegistrationScreen({super.key, required this.onRegistrationComplete});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Step 1: Phone
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _otpVerified = false;

  // Step 2: Profile
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _panController = TextEditingController();
  final _dobController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _kycOtpController = TextEditingController();
  bool _kycVerified = false;
  int _kycStep = 0; // 0=PAN, 1=Loading PAN, 2=DigiLocker, 3=Aadhaar OTP, 4=Name Match, 5=Liveness, 6=Verified
  bool _kycConsent = false;
  String? _kycSessionId;
  String _fetchedPanName = '';
  double _nameMatchScore = 0.0;
  final bool _livenessPassed = false;
  bool _livenessSelfieTaken = false;
  String _selectedCity = 'Chennai';
  String _selectedPlatform = 'Swiggy';
  String _vehicleType = 'Bike';

  // Step 3: Risk Inputs
  double _dailyTravelKm = 40;
  int _dailyOrderVolume = 15;
  double _dailyHours = 8;
  String _weeklyIncomeRange = '₹3000-5000';
  bool _hadPriorInsurance = false;

  // Step 4: Zone
  String _selectedZone = 'Adyar';

  // Step 5: AI Premium
  bool _isCalculatingPremium = false;
  PremiumResult? _calculatedPremium;
  int _calculationStep = 0;
  bool _isRegistering = false;
  bool _irdaiConsent = false;

  final _cities = ['Chennai', 'Delhi', 'Mumbai'];
  final _platforms = ['Swiggy', 'Zomato'];
  final _vehicles = ['Bike', 'Scooter', 'Bicycle'];
  final _incomeRanges = ['₹1000-3000', '₹3000-5000', '₹5000-8000', '₹8000+'];
  final Map<String, List<String>> _cityZones = {
    'Chennai': ['Adyar', 'Velachery', 'T. Nagar', 'Mylapore', 'Anna Nagar', 'Guindy', 'Porur', 'Tambaram'],
    'Delhi': ['Connaught Place', 'Dwarka', 'Rohini', 'Saket', 'Lajpat Nagar', 'Karol Bagh'],
    'Mumbai': ['Andheri', 'Bandra', 'Dadar', 'Borivali', 'Kurla', 'Goregaon', 'Powai'],
  };

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this)..forward();
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _aadhaarController.dispose();
    _kycOtpController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() async {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
      _pageController.animateToPage(_currentStep, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      if (_isRegistering) return;
      setState(() => _isRegistering = true);
      if (SupabaseService.isConfigured) {
        try {
          final workerId = '${_nameController.text.split(' ')[0]}_${_phoneController.text.substring(6)}';
          final incomeMap = {'₹1000-3000': 2000, '₹3000-5000': 4000, '₹5000-8000': 6500, '₹8000+': 9000};
          final weeklyIncome = incomeMap[_weeklyIncomeRange] ?? 4000;
          await SupabaseService.client.from('workers').upsert({
            'worker_id': workerId, 'city': _selectedCity, 'zone': _selectedZone,
            'primary_platform': _selectedPlatform, 'vehicle_type': _vehicleType,
            'trust_score': _hadPriorInsurance ? 90 : 100, 'avg_daily_hours': _dailyHours,
            'avg_daily_income': (weeklyIncome / 6).round(), 'avg_weekly_income': weeklyIncome,
          }, onConflict: 'worker_id');
          await SupabaseService.client.from('policies').insert({
            'policy_id': 'POL-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
            'worker_id': workerId, 'tier': _calculatedPremium?.recommendedTier ?? 'Smart Shield',
            'weekly_premium': _calculatedPremium?.totalPremium ?? 45, 'coverage_percentage': 85,
            'coverage_ceiling': (weeklyIncome * 0.85).round(),
            'start_date': DateTime.now().toIso8601String().split('T')[0],
            'end_date': DateTime.now().add(const Duration(days: 7)).toIso8601String().split('T')[0],
            'status': 'Active',
            'premium_breakdown': {'factors': _calculatedPremium?.factors.length ?? 0, 'risk_score': _calculatedPremium?.riskScore ?? 50},
          });
        } catch (e) { debugPrint('Registration sync error: $e'); }
      }
      setState(() => _isRegistering = false);
      widget.onRegistrationComplete(context);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(_currentStep, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0: return _otpVerified;
      case 1: return _nameController.text.length >= 2 && _kycVerified;
      case 2: return true;
      case 3: return _selectedZone.isNotEmpty;
      case 4: return _calculatedPremium != null && _irdaiConsent;
      default: return false;
    }
  }

  String get _stepTitle => ['Verify Phone', 'Your Profile', 'Risk Assessment', 'Working Zone', 'Your Policy'][_currentStep];
  String get _stepSubtitle => [
    'Quick verification to get started',
    'Tell us about yourself',
    'We assess risk for fair pricing',
    'Select your primary zone',
    'AI-generated personalized plan',
  ][_currentStep];

  // ─── Shared UI Helpers ───────────────────────────────────────────

  BoxDecoration get _cardDecor => BoxDecoration(
    color: AppColors.onboardCard,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.onboardBorder),
    boxShadow: [BoxShadow(color: const Color(0xFF1565C0).withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onboardTextBody)),
  );

  Widget _inputField(String label, TextEditingController ctrl, IconData icon, {TextInputType? keyboardType, List<TextInputFormatter>? formatters, String? hint}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(label),
      Container(
        decoration: _cardDecor,
        child: TextField(
          controller: ctrl, keyboardType: keyboardType, inputFormatters: formatters,
          style: const TextStyle(fontSize: 15, color: AppColors.onboardTextDark),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.onboardBlueLight, size: 20),
            hintText: hint ?? 'Enter $label', hintStyle: const TextStyle(color: AppColors.onboardTextMuted),
            border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          ),
        ),
      ),
    ]);
  }

  Widget _dropdown(String label, String value, List<String> items, IconData icon, ValueChanged<String?> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(label),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: _cardDecor,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value, isExpanded: true, dropdownColor: AppColors.onboardCard,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.onboardTextMuted),
            items: items.map((e) => DropdownMenuItem(value: e, child: Row(children: [
              Icon(icon, color: AppColors.onboardBlueLight, size: 20), const SizedBox(width: 12),
              Text(e, style: const TextStyle(fontSize: 15, color: AppColors.onboardTextDark)),
            ]))).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    ]);
  }

  // ─── BUILD ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.onboardBg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(children: [
            _buildHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [_buildPhoneStep(), _buildProfileStep(), _buildRiskStep(), _buildZoneStep(), _buildPlanStep()],
              ),
            ),
            _buildBottomButton(),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.onboardCard,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Row(children: [
          if (_currentStep > 0)
            GestureDetector(
              onTap: _prevStep,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.onboardBlueSoft, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_back_rounded, color: AppColors.onboardBluePrimary, size: 20),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_stepTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.onboardTextDark)),
            Text(_stepSubtitle, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.onboardTextMuted)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.onboardBlueSoft, borderRadius: BorderRadius.circular(20)),
            child: Text('${_currentStep + 1}/5', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onboardBluePrimary)),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: List.generate(5, (i) => Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.only(right: i < 4 ? 4 : 0), height: 4,
            decoration: BoxDecoration(
              color: i <= _currentStep ? AppColors.onboardBluePrimary : AppColors.onboardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ))),
      ]),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.onboardCard,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SizedBox(
        width: double.infinity, height: 52,
        child: ElevatedButton(
          onPressed: _canProceed ? _nextStep : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.onboardBluePrimary,
            disabledBackgroundColor: AppColors.onboardBorder,
            elevation: 0,
          ),
          child: _isRegistering
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(_currentStep == 4 ? 'Activate Policy' : 'Continue', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      ),
    );
  }

  // ─── STEP 1: Phone ───────────────────────────────────────────────

  Widget _buildPhoneStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 20),
        Center(child: Container(
          width: 80, height: 80,
          decoration: BoxDecoration(gradient: AppColors.onboardGradient, borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.phone_android_rounded, color: Colors.white, size: 36),
        )),
        const SizedBox(height: 32),
        _label('Phone Number'),
        Container(
          decoration: _cardDecor,
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(border: Border(right: BorderSide(color: AppColors.onboardBorder))),
              child: const Text('+91', style: TextStyle(fontSize: 15, color: AppColors.onboardTextDark, fontWeight: FontWeight.w600)),
            ),
            Expanded(child: TextField(
              controller: _phoneController, keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              style: const TextStyle(fontSize: 15, color: AppColors.onboardTextDark),
              decoration: const InputDecoration(hintText: 'Enter 10-digit number', hintStyle: TextStyle(color: AppColors.onboardTextMuted), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16)),
              onChanged: (_) => setState(() {}),
            )),
          ]),
        ),
        const SizedBox(height: 12),
        if (!_otpSent) SizedBox(width: double.infinity, child: OutlinedButton(
          onPressed: _phoneController.text.length == 10 ? () async {
            setState(() => _otpSent = true);
            await GigKavachApiService.requestOtp('+91${_phoneController.text}');
          } : null,
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.onboardBluePrimary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
          child: const Text('Send OTP', style: TextStyle(color: AppColors.onboardBluePrimary, fontWeight: FontWeight.w600)),
        )),
        if (_otpSent && !_otpVerified) ...[
          const SizedBox(height: 20),
          Container(padding: const EdgeInsets.all(16), decoration: _cardDecor, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.sms_rounded, color: AppColors.onboardBluePrimary, size: 18), const SizedBox(width: 8),
              const Text('OTP Sent!', style: TextStyle(color: AppColors.onboardBluePrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('to +91 ${_phoneController.text}', style: const TextStyle(color: AppColors.onboardTextMuted, fontSize: 11)),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _otpController, keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              style: const TextStyle(fontSize: 20, color: AppColors.onboardTextDark, fontWeight: FontWeight.w700, letterSpacing: 8),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(hintText: '• • • • • •', hintStyle: TextStyle(color: AppColors.onboardTextMuted, letterSpacing: 8), border: InputBorder.none),
              onChanged: (val) async { 
                if (val.length == 6) {
                  final result = await GigKavachApiService.login('+91${_phoneController.text}', otp: val);
                  if (result.containsKey('access_token')) {
                    setState(() => _otpVerified = true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid OTP')));
                  }
                } 
              },
            ),
            const Center(child: Text('Enter any 6-digit code (demo)', style: TextStyle(fontSize: 11, color: AppColors.onboardTextMuted))),
          ])),
        ],
        if (_otpVerified) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.onboardSuccessBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.onboardSuccess.withValues(alpha: 0.3))),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.onboardSuccess.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.onboardSuccess, size: 20)),
              const SizedBox(width: 12),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Phone Verified!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onboardSuccess)),
                Text('Your number is now linked', style: TextStyle(fontSize: 12, color: AppColors.onboardTextBody)),
              ]),
            ]),
          ),
        ],
      ]),
    );
  }

  // ─── STEP 2: Profile ─────────────────────────────────────────────

  Widget _buildProfileStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _dropdown('City', _selectedCity, _cities, Icons.location_city_rounded, (v) => setState(() { _selectedCity = v!; _selectedZone = _cityZones[_selectedCity]!.first; })),
        const SizedBox(height: 16),
        _dropdown('Platform', _selectedPlatform, _platforms, Icons.delivery_dining_rounded, (v) => setState(() => _selectedPlatform = v!)),
        const SizedBox(height: 16),
        _dropdown('Vehicle', _vehicleType, _vehicles, Icons.two_wheeler_rounded, (v) => setState(() => _vehicleType = v!)),
        const SizedBox(height: 16),
        
        // KYC Section
        const SizedBox(height: 16),
        _label('Identity & Background Verification'),
        
        // SANDBOX BANNER
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: AppColors.onboardWarningBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.onboardWarning)),
          child: Row(children: [
            const Icon(Icons.science_rounded, color: AppColors.onboardWarning, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Text('Development / Sandbox Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onboardWarning)),
              Text('Your identity verification is currently simulated for development purposes.', style: TextStyle(fontSize: 11, color: AppColors.onboardWarning)),
            ])),
          ]),
        ),
        
        if (_kycStep == 0) ...[
          _inputField('Full Name (As on PAN)', _nameController, Icons.person_rounded),
          const SizedBox(height: 16),
          _inputField('PAN Number', _panController, Icons.credit_card_rounded, formatters: [LengthLimitingTextInputFormatter(10)], hint: 'ABCDE1234F'),
          const SizedBox(height: 16),
          _inputField('Date of Birth', _dobController, Icons.calendar_today_rounded, hint: 'YYYY-MM-DD'),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: OutlinedButton(
            onPressed: (_panController.text.length == 10 && _nameController.text.isNotEmpty && _dobController.text.isNotEmpty) ? () async {
              setState(() => _kycStep = 1);
              
              // 1. Start KYC session if we don't have one
              if (_kycSessionId == null) {
                final initRes = await GigKavachApiService.startKyc();
                _kycSessionId = initRes['session_id'];
              }
              
              if (_kycSessionId == null) {
                if (mounted) setState(() => _kycStep = 0);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to initialize KYC')));
                return;
              }
              
              // 2. Verify PAN
              final res = await GigKavachApiService.verifyPanIdentity(_kycSessionId!, _panController.text, _dobController.text, _nameController.text);
              if (res['verified'] == true) {
                if (mounted) setState(() {
                  _fetchedPanName = res['fetched_name'] ?? _nameController.text;
                  _nameMatchScore = res['name_match_score'] ?? 0.0;
                  _kycStep = 2;
                });
              } else {
                if (mounted) {
                  setState(() => _kycStep = 0);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PAN Verification Failed')));
                }
              }
            } : null,
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.onboardBluePrimary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Verify PAN', style: TextStyle(color: AppColors.onboardBluePrimary, fontWeight: FontWeight.w600)),
          )),
        ] else if (_kycStep == 1) ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: _cardDecor,
            child: Column(children: [
              const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onboardBluePrimary)),
              const SizedBox(height: 16),
              const Text('Verifying PAN with NSDL...', style: TextStyle(fontSize: 13, color: AppColors.onboardBluePrimary, fontWeight: FontWeight.w600)),
            ]),
          ),
        ] else if (_kycStep == 2) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecor,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.onboardSuccess, size: 20),
                const SizedBox(width: 8),
                const Text('PAN Verified', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.onboardSuccess)),
              ]),
              const SizedBox(height: 16),
              const Text('Connect Aadhaar via DigiLocker', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onboardTextDark)),
              const SizedBox(height: 8),
              
              // DigiLocker Sandbox Warning
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: AppColors.onboardBlueSoft.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
                child: const Text('DigiLocker Integration - Sandbox\nThis is a simulated DigiLocker authorization flow for development purposes.', style: TextStyle(fontSize: 11, color: AppColors.onboardBluePrimary)),
              ),
              
              _inputField('Aadhaar Number', _aadhaarController, Icons.badge_rounded, keyboardType: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(12)], hint: '12-digit Aadhaar'),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: _aadhaarController.text.length == 12 ? () async {
                  setState(() => _kycStep = 1); // Loading
                  await GigKavachApiService.initDigiLockerConsent(_kycSessionId!);
                  final res = await GigKavachApiService.sendAadhaarOtp(_kycSessionId!, _aadhaarController.text);
                  if (res['status'] != 'error') {
                    if (mounted) setState(() => _kycStep = 3);
                  } else {
                    if (mounted) {
                      setState(() => _kycStep = 2);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to trigger OTP')));
                    }
                  }
                } : null,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.onboardBluePrimary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                child: const Text('Send Aadhaar OTP', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              )),
            ]),
          ),
        ] else if (_kycStep == 3) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecor,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Enter Aadhaar OTP', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onboardTextDark)),
              const SizedBox(height: 4),
              const Text('OTP sent to UIDAI registered mobile number.', style: TextStyle(fontSize: 11, color: AppColors.onboardTextMuted)),
              const SizedBox(height: 16),
              TextField(
                controller: _kycOtpController, keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                style: const TextStyle(fontSize: 20, color: AppColors.onboardTextDark, fontWeight: FontWeight.w700, letterSpacing: 8),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(hintText: '• • • • • •', hintStyle: TextStyle(color: AppColors.onboardTextMuted, letterSpacing: 8), border: InputBorder.none),
                onChanged: (val) async {
                  if (val.length == 6) {
                    if (mounted) setState(() => _kycStep = 4);
                  }
                },
              ),
            ]),
          ),
        ] else if (_kycStep == 4) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecor,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Identity Match', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onboardTextDark)),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('PAN Name:', style: TextStyle(fontSize: 13, color: AppColors.onboardTextMuted)),
                Text(_fetchedPanName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onboardTextDark)),
              ]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Aadhaar Name:', style: TextStyle(fontSize: 13, color: AppColors.onboardTextMuted)),
                Text(_nameController.text.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onboardTextDark)),
              ]),
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.onboardSuccessBg, borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.onboardSuccess, size: 16),
                  const SizedBox(width: 8),
                  Text('Names match (${(_nameMatchScore*100).toInt()}% confidence)', style: const TextStyle(fontSize: 11, color: AppColors.onboardSuccess, fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () => setState(() => _kycStep = 5),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.onboardBluePrimary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                child: const Text('Proceed to Liveness Check', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              )),
            ]),
          ),
        ] else if (_kycStep == 5) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecor,
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              const Text('In-Person Verification (IPV)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onboardTextDark)),
              const SizedBox(height: 8),
              const Text('Write this code on a piece of paper and hold it up while taking a selfie.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.onboardTextBody)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(color: AppColors.onboardBlueSoft, borderRadius: BorderRadius.circular(8)),
                child: const Text('4 9 2 1', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 8, color: AppColors.onboardBluePrimary)),
              ),
              const SizedBox(height: 20),
              if (_livenessSelfieTaken) ...[
                Container(
                  height: 150, width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Icon(Icons.image_rounded, color: Colors.grey, size: 40)),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => setState(() => _kycConsent = !_kycConsent),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(_kycConsent ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, color: _kycConsent ? AppColors.onboardSuccess : AppColors.onboardTextMuted, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('I provide DPDP consent to process my data for insurance underwriting.', style: TextStyle(fontSize: 11, color: AppColors.onboardTextBody))),
                  ]),
                ),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: ElevatedButton(
                  onPressed: _kycConsent ? () async {
                    setState(() => _kycStep = 1); // Loading
                    final res = await GigKavachApiService.completeKyc(
                      sessionId: _kycSessionId ?? 'demo',
                      panNumber: _panController.text,
                      aadhaarLast4: _aadhaarController.text.length >= 4 ? _aadhaarController.text.substring(_aadhaarController.text.length - 4) : '0000',
                      aadhaarOtp: _kycOtpController.text,
                      consentTimestamp: DateTime.now().toIso8601String(),
                      consentIp: '192.168.1.1',
                      selfieHash: 'demohash1234567890',
                    );
                    if (res['kyc_status'] == 'SUCCESS' || res['kyc_status'] == 'completed') {
                      if (mounted) setState(() { _kycStep = 6; });
                    } else {
                      if (mounted) {
                        setState(() => _kycStep = 5);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('KYC Finalization Failed')));
                      }
                    }
                  } : null,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.onboardBluePrimary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                  child: const Text('E-Sign & Complete KYC', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                )),
              ] else ...[
                SizedBox(width: double.infinity, child: OutlinedButton.icon(
                  onPressed: () {
                    // Simulate opening camera and taking a picture
                    setState(() => _livenessSelfieTaken = true);
                  },
                  icon: const Icon(Icons.camera_alt_rounded, color: AppColors.onboardBluePrimary, size: 18),
                  label: const Text('Take Selfie', style: TextStyle(color: AppColors.onboardBluePrimary, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.onboardBluePrimary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                )),
              ]
            ]),
          ),
        ] else if (_kycStep == 6) ...[
          Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.onboardSuccessBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.onboardSuccess.withValues(alpha: 0.3))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.onboardSuccess.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.verified_user_rounded, color: AppColors.onboardSuccess, size: 18)),
                  const SizedBox(width: 12),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('KYC Complete.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onboardSuccess)),
                    Text('Identity verified successfully.', style: TextStyle(fontSize: 11, color: AppColors.onboardSuccess)),
                  ])),
                ]),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: ElevatedButton(
                  onPressed: () => setState(() => _kycStep = 7),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.onboardBluePrimary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                  child: const Text('Proceed to Income Verification', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                )),
              ]),
          ),
        ] else if (_kycStep == 7) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecor,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Link Work Platform', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onboardTextDark)),
              const SizedBox(height: 8),
              const Text('Connect your primary gig platform to verify your daily work hours and income. This enables AI-underwritten, fair insurance premiums.', style: TextStyle(fontSize: 12, color: AppColors.onboardTextBody)),
              const SizedBox(height: 16),
              
              Column(
                children: [
                  _socialLoginButton('Zomato', const Color(0xFFE23744)),
                  const SizedBox(height: 12),
                  _socialLoginButton('Swiggy', const Color(0xFFFC8019)),
                  const SizedBox(height: 12),
                  _socialLoginButton('Blinkit', const Color(0xFFF8CB46)),
                ],
              ),
            ]),
          ),
        ] else if (_kycStep == 8) ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: _cardDecor,
            child: Column(children: [
              const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onboardBluePrimary)),
              const SizedBox(height: 16),
              const Text('Connecting to Aggregator...', style: TextStyle(fontSize: 13, color: AppColors.onboardBluePrimary, fontWeight: FontWeight.w600)),
            ]),
          ),
        ] else if (_kycStep == 9) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecor,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Platform Linked', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onboardTextDark)),
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.onboardSuccessBg, borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.onboardSuccess, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Work history and income successfully synced. Your risk profile has been updated.', style: TextStyle(fontSize: 11, color: AppColors.onboardSuccess, fontWeight: FontWeight.w600))),
                ]),
              ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () {
                   setState(() { _kycVerified = true; });
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.onboardBluePrimary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                child: const Text('Complete Onboarding', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              )),
            ]),
          ),
        ],
        const SizedBox(height: 24),
        
        // Developer Tool Panel
        if (!_kycVerified) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Developer Panel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                ActionChip(
                  label: const Text('Auto-Fill Success', style: TextStyle(fontSize: 10)),
                  onPressed: () {
                    setState(() {
                      _nameController.text = 'Varad Singhal';
                      _panController.text = 'ABCDE1234F';
                      _dobController.text = '1990-01-01';
                      _aadhaarController.text = '999999999999';
                    });
                  },
                ),
                ActionChip(
                  label: const Text('Auto-Fill Failed PAN', style: TextStyle(fontSize: 10)),
                  onPressed: () {
                    setState(() {
                      _panController.text = 'XXXXX0000X';
                      _nameController.text = 'Varad Singhal';
                      _dobController.text = '1990-01-01';
                    });
                  },
                ),
                ActionChip(
                  label: const Text('Fast-Track Verified', style: TextStyle(fontSize: 10)),
                  onPressed: () {
                    setState(() {
                      _kycStep = 9;
                      _kycVerified = true;
                    });
                  },
                ),
              ])
            ]),
          )
        ],
        const SizedBox(height: 16),
      ]),
    );
  }

  // ─── STEP 3: Risk Assessment Inputs ──────────────────────────────

  Widget _buildRiskStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.onboardBlueSoft, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Icon(Icons.auto_awesome, color: AppColors.onboardBluePrimary, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text('These inputs feed our AI engine to calculate a fair, personalized premium just for you.', style: TextStyle(fontSize: 12, color: AppColors.onboardBluePrimary, height: 1.4))),
          ]),
        ),
        const SizedBox(height: 20),

        // Daily Travel Distance
        _label('Daily Travel Distance'),
        Container(padding: const EdgeInsets.all(14), decoration: _cardDecor, child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Icon(Icons.route_rounded, color: AppColors.onboardBluePrimary, size: 20), const SizedBox(width: 8),
              Text('${_dailyTravelKm.toInt()} km/day', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.onboardTextDark)),
            ]),
            _riskChip(_dailyTravelKm < 30 ? 'Low' : _dailyTravelKm < 60 ? 'Moderate' : 'High'),
          ]),
          Slider(value: _dailyTravelKm, min: 5, max: 150, divisions: 29, activeColor: AppColors.onboardBluePrimary, inactiveColor: AppColors.onboardBorder, onChanged: (v) => setState(() => _dailyTravelKm = v)),
        ])),
        const SizedBox(height: 16),

        // Daily Order Volume
        _label('Daily Order Volume'),
        Container(padding: const EdgeInsets.all(14), decoration: _cardDecor, child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Icon(Icons.shopping_bag_rounded, color: AppColors.onboardBluePrimary, size: 20), const SizedBox(width: 8),
              Text('$_dailyOrderVolume orders/day', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.onboardTextDark)),
            ]),
            _riskChip(_dailyOrderVolume < 10 ? 'Low' : _dailyOrderVolume < 25 ? 'Moderate' : 'High'),
          ]),
          Slider(value: _dailyOrderVolume.toDouble(), min: 2, max: 50, divisions: 24, activeColor: AppColors.onboardBluePrimary, inactiveColor: AppColors.onboardBorder, onChanged: (v) => setState(() => _dailyOrderVolume = v.toInt())),
        ])),
        const SizedBox(height: 16),

        // Working Hours
        _label('Daily Working Hours'),
        Container(padding: const EdgeInsets.all(14), decoration: _cardDecor, child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Icon(Icons.schedule_rounded, color: AppColors.onboardBluePrimary, size: 20), const SizedBox(width: 8),
              Text('${_dailyHours.toInt()} hours/day', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.onboardTextDark)),
            ]),
            _riskChip(_dailyHours >= 10 ? 'Heavy' : _dailyHours >= 6 ? 'Regular' : 'Light'),
          ]),
          Slider(value: _dailyHours, min: 2, max: 14, divisions: 12, activeColor: AppColors.onboardBluePrimary, inactiveColor: AppColors.onboardBorder, onChanged: (v) => setState(() => _dailyHours = v)),
        ])),
        const SizedBox(height: 16),

        _dropdown('Estimated Weekly Income', _weeklyIncomeRange, _incomeRanges, Icons.account_balance_wallet_rounded, (v) => setState(() => _weeklyIncomeRange = v!)),
        const SizedBox(height: 16),

        _label('Prior Insurance?'),
        Row(children: [
          Expanded(child: _toggleButton('No, first time', !_hadPriorInsurance, () => setState(() => _hadPriorInsurance = false))),
          const SizedBox(width: 12),
          Expanded(child: _toggleButton('Yes, I do', _hadPriorInsurance, () => setState(() => _hadPriorInsurance = true))),
        ]),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _riskChip(String label) {
    final color = label == 'Low' || label == 'Light' ? AppColors.onboardSuccess : label == 'High' || label == 'Heavy' ? AppColors.onboardWarning : AppColors.onboardBluePrimary;
    final bg = label == 'Low' || label == 'Light' ? AppColors.onboardSuccessBg : label == 'High' || label == 'Heavy' ? AppColors.onboardWarningBg : AppColors.onboardBlueSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _toggleButton(String text, bool active, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: active ? AppColors.onboardBlueSoft : AppColors.onboardCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? AppColors.onboardBluePrimary : AppColors.onboardBorder),
      ),
      child: Center(child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: active ? AppColors.onboardBluePrimary : AppColors.onboardTextMuted))),
    ));
  }

  // ─── STEP 4: Zone ────────────────────────────────────────────────

  Widget _buildZoneStep() {
    final zones = _cityZones[_selectedCity]!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.onboardBlueSoft, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.onboardBluePrimary, size: 18), const SizedBox(width: 10),
            Expanded(child: Text('Your zone affects your risk score. Area historic conditions like floods, road quality, and accident rates are factored in.', style: TextStyle(fontSize: 12, color: AppColors.onboardBluePrimary))),
          ]),
        ),
        const SizedBox(height: 16),
        ...zones.map((zone) {
          final isSelected = _selectedZone == zone;
          final zp = PremiumEngine.getZoneProfile(zone);
          final isHighRisk = zp != null && zp.floodRiskScore > 0.6;
          return Padding(padding: const EdgeInsets.only(bottom: 8), child: GestureDetector(
            onTap: () => setState(() => _selectedZone = zone),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.onboardBlueSoft : AppColors.onboardCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isSelected ? AppColors.onboardBluePrimary : AppColors.onboardBorder, width: isSelected ? 1.5 : 1),
                boxShadow: isSelected ? [BoxShadow(color: AppColors.onboardBluePrimary.withValues(alpha: 0.08), blurRadius: 8)] : null,
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: (isSelected ? AppColors.onboardBluePrimary : AppColors.onboardTextMuted).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.location_on_rounded, color: isSelected ? AppColors.onboardBluePrimary : AppColors.onboardTextMuted, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(zone, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isSelected ? AppColors.onboardTextDark : AppColors.onboardTextBody)),
                  if (zp != null) Text('Flood: ${(zp.floodRiskScore * 100).toInt()}% · AQI: ${zp.avgAqi} · Rain: ${zp.predictedRainNextWeek}mm', style: const TextStyle(fontSize: 10, color: AppColors.onboardTextMuted)),
                ])),
                if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.onboardBluePrimary, size: 22)
                else if (isHighRisk) _riskChip('High Risk'),
              ]),
            ),
          ));
        }),
      ]),
    );
  }

  // ─── STEP 5: AI Premium ──────────────────────────────────────────

  Future<void> _runPremiumSimulation() async {
    setState(() { _isCalculatingPremium = true; _calculationStep = 1; });
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _calculationStep = 2);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _calculationStep = 3);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _calculationStep = 4);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final result = PremiumEngine.calculate(
      zone: _selectedZone, city: _selectedCity, vehicleType: _vehicleType,
      experienceWeeks: _hadPriorInsurance ? 10 : 0, claimCount: 0,
      driverAge: int.tryParse(_ageController.text) ?? 25,
      dailyTravelKm: _dailyTravelKm, dailyOrderVolume: _dailyOrderVolume,
      dailyHours: _dailyHours,
    );
    setState(() { _calculatedPremium = result; _calculationStep = 5; });
  }

  Widget _buildPlanStep() {
    if (_calculatedPremium == null || _calculationStep == 5) {
      return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: AppColors.onboardCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.onboardBorder),
            boxShadow: [BoxShadow(color: AppColors.onboardBluePrimary.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 8))]),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(gradient: AppColors.onboardGradient, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            const Text('AI Policy Engine', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.onboardTextDark)),
            const SizedBox(height: 10),
            Text('Our AI analyzes your age, travel distance, order volume, zone history, and weather to build a policy uniquely priced for you.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.onboardTextBody, height: 1.5)),
            const SizedBox(height: 28),
            if (_isCalculatingPremium) ...[
              if (_calculationStep < 5)
                const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.onboardBluePrimary, strokeWidth: 2)),
              const SizedBox(height: 16),
              _simStep('Analyzing age & travel profile', _calculationStep >= 1),
              _simStep('Evaluating area historic conditions', _calculationStep >= 2),
              _simStep('Processing order volume risk', _calculationStep >= 3),
              _simStep('Computing personalized premium', _calculationStep >= 4),
              if (_calculationStep == 5) ...[
                const SizedBox(height: 24),
                SizedBox(width: double.infinity, child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() { _isCalculatingPremium = false; _calculationStep = 0; });
                  },
                  icon: const Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 18),
                  label: const Text('Review Policy', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 15)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.onboardSuccess, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                )),
              ]
            ] else
              SizedBox(width: double.infinity, child: ElevatedButton.icon(
                onPressed: _runPremiumSimulation,
                icon: const Icon(Icons.memory, color: Colors.white, size: 18),
                label: const Text('Generate My Policy', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 15)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.onboardBluePrimary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
              )),
          ]),
        ),
      ]));
    }

    final r = _calculatedPremium!;
    final incomeMap = {'₹1000-3000': 2000, '₹3000-5000': 4000, '₹5000-8000': 6500, '₹8000+': 9000};
    final maxPayout = ((incomeMap[_weeklyIncomeRange] ?? 4000) * 0.85).round();

    return SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      // Premium card
      Container(
        width: double.infinity, padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(gradient: AppColors.onboardGradient, borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          Text(r.recommendedTier, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text('₹${r.totalPremium.toInt()}', style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w800, color: Colors.white)),
          const Text('per week', style: TextStyle(fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
            child: Text('Max Payout: ₹$maxPayout/wk · ${r.coverageHoursPerDay}h/day coverage', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500))),
        ]),
      ),
      const SizedBox(height: 16),

      // Risk score
      Container(padding: const EdgeInsets.all(16), decoration: _cardDecor, child: Row(children: [
        _buildRiskGauge(r.riskScore),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Risk Score: ${r.riskScore.toInt()}/100', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onboardTextDark)),
          Text(r.riskLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _riskColor(r.riskScore))),
          const SizedBox(height: 4),
          Text(r.tierReason, style: const TextStyle(fontSize: 11, color: AppColors.onboardTextMuted)),
        ])),
      ])),
      const SizedBox(height: 16),

      // Factor breakdown
      const Text('Premium Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onboardTextDark)),
      const SizedBox(height: 10),
      ...r.factors.map((f) {
        final isDisc = f.amount < 0;
        final isZero = f.amount == 0;
        final color = isDisc ? AppColors.onboardSuccess : isZero ? AppColors.onboardTextMuted : (f.type == 'base' ? AppColors.onboardTextDark : AppColors.onboardWarning);
        return Container(
          margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.onboardCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.onboardBorder)),
          child: Row(children: [
            Icon(isDisc ? Icons.trending_down_rounded : isZero ? Icons.remove_rounded : Icons.add_circle_outline_rounded, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(f.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
              Text(f.info, style: const TextStyle(fontSize: 10, color: AppColors.onboardTextMuted)),
            ])),
            Text(isZero ? '₹0' : '${isDisc ? "" : "+"}₹${f.amount.abs().toInt()}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          ]),
        );
      }),
      const SizedBox(height: 8),

      // Renewal note
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.onboardBlueSoft, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(Icons.autorenew_rounded, color: AppColors.onboardBluePrimary, size: 20), const SizedBox(width: 10),
          Expanded(child: Text('After 1 week, your policy auto-renews with an updated premium based on your driving performance, delivery success rate & incident history.', style: TextStyle(fontSize: 11, color: AppColors.onboardBluePrimary, height: 1.4))),
        ]),
      ),
      const SizedBox(height: 16),

      // IRDAI Consent Checkbox
      GestureDetector(
        onTap: () {
          setState(() {
            _irdaiConsent = !_irdaiConsent;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _irdaiConsent ? AppColors.onboardSuccessBg : AppColors.onboardCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _irdaiConsent ? AppColors.onboardSuccess : AppColors.onboardBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _irdaiConsent ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                color: _irdaiConsent ? AppColors.onboardSuccess : AppColors.onboardTextMuted,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'I agree to the IRDAI Micro-Insurance Guidelines',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _irdaiConsent ? AppColors.onboardSuccess : AppColors.onboardTextDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'I consent to the use of parametric trigger data (weather, location, AQI) for automated claim adjudication and payout calculations as per IRDAI Sandbox regulations.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.onboardTextBody,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        _showKfdBottomSheet(context);
                      },
                      child: Text(
                        'View Key Features Document (KFD)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onboardBluePrimary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
    ]));
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
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onboardTextDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'IRDAI Micro-Insurance Parametric Policy',
              style: TextStyle(fontSize: 14, color: AppColors.onboardTextMuted),
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
                  backgroundColor: AppColors.onboardBluePrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('I Understand', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
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
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onboardTextDark)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(fontSize: 13, color: AppColors.onboardTextBody, height: 1.5)),
        ],
      ),
    );
  }

  void _showDocumentPreview(BuildContext context) {
    final name = _nameController.text.isEmpty ? 'The Undersigned' : _nameController.text;
    final aadhaar = _aadhaarController.text;
    final maskedAadhaar = aadhaar.length == 12 ? 'XXXX-XXXX-${aadhaar.substring(8)}' : 'XXXX-XXXX-XXXX';
    final date = DateTime.now().toLocal().toString().split(' ')[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFFF7F5F0), // Off-white paper feel
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 24),
                const SizedBox(width: 12),
                const Expanded(child: Text('GigKavach e-Agreement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87))),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(child: Text('MASTER INSURANCE POLICY AGREEMENT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, decoration: TextDecoration.underline, letterSpacing: 1.2))),
                      const SizedBox(height: 24),
                      Text('Date: $date', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
                      const SizedBox(height: 16),
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(fontSize: 12, height: 1.6, color: Colors.black87),
                          children: [
                            const TextSpan(text: 'This agreement is executed between '),
                            const TextSpan(text: 'GigKavach Technologies Pvt. Ltd.', style: TextStyle(fontWeight: FontWeight.w700)),
                            const TextSpan(text: ' (hereinafter referred to as the "Insurer") and \n\n'),
                            const TextSpan(text: 'Name: ', style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: '$name\n', style: const TextStyle(fontStyle: FontStyle.italic)),
                            const TextSpan(text: 'Aadhaar ID: ', style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: '$maskedAadhaar\n\n', style: const TextStyle(fontStyle: FontStyle.italic)),
                            const TextSpan(text: '(hereinafter referred to as the "Policyholder").\n\n'),
                            const TextSpan(text: 'WHEREAS the Policyholder is engaged as a gig-economy worker, and WHEREAS the Insurer provides parametric income-protection insurance.\n\n'),
                            const TextSpan(text: '1. TERMS OF COVERAGE\n', style: TextStyle(fontWeight: FontWeight.w700)),
                            const TextSpan(text: 'The Insurer agrees to compensate the Policyholder for loss of income arising directly from predefined parametric triggers (including but not limited to severe weather, flooding, and extreme heat) matching the thresholds defined by the IRDAI Sandbox guidelines.\n\n'),
                            const TextSpan(text: '2. DIGITAL CONSENT & KYC\n', style: TextStyle(fontWeight: FontWeight.w700)),
                            const TextSpan(text: 'By affixing an electronic signature via Aadhaar OTP, the Policyholder consents to the fetching of their demographic details from UIDAI/DigiLocker and authorises the Insurer to process this data for underwriting purposes.\n\n'),
                            const TextSpan(text: '3. AUTO-ADJUDICATION\n', style: TextStyle(fontWeight: FontWeight.w700)),
                            const TextSpan(text: 'Claims will be auto-adjudicated based on verified third-party API data (e.g., IMD, OpenWeather) corresponding to the Policyholder\'s declared working zone.\n\n'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(height: 40, width: 100, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black54)))),
                              const SizedBox(height: 4),
                              const Text('Insurer Signature', style: TextStyle(fontSize: 10, color: Colors.black54)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(height: 40, width: 100, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black54)))),
                              const SizedBox(height: 4),
                              const Text('Policyholder E-Sign', style: TextStyle(fontSize: 10, color: Colors.black54)),
                              Text('Pending OTP', style: TextStyle(fontSize: 9, color: Colors.red[300], fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                   final url = Uri.parse('${GigKavachApiService.baseUrl}/auth/policy/DEMO-1234/pdf');
                   if (await canLaunchUrl(url)) {
                     await launchUrl(url, mode: LaunchMode.externalApplication);
                   } else {
                     if (context.mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open browser.')));
                     }
                   }
                },
                icon: const Icon(Icons.download_rounded, color: Colors.white),
                label: const Text('Download Original PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.onboardBluePrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _simStep(String text, bool done) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [
      Icon(done ? Icons.check_circle : Icons.circle_outlined, size: 14, color: done ? AppColors.onboardSuccess : AppColors.onboardTextMuted),
      const SizedBox(width: 8),
      Text(text, style: TextStyle(fontSize: 12, color: done ? AppColors.onboardSuccess : AppColors.onboardTextMuted)),
    ]));
  }

  Widget _buildRiskGauge(double score) {
    return SizedBox(width: 64, height: 64, child: Stack(alignment: Alignment.center, children: [
      SizedBox(width: 64, height: 64, child: CircularProgressIndicator(
        value: score / 100, strokeWidth: 6, backgroundColor: AppColors.onboardBorder,
        valueColor: AlwaysStoppedAnimation(_riskColor(score)),
      )),
      Text('${score.toInt()}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _riskColor(score))),
    ]));
  }

  Color _riskColor(double score) {
    if (score < 30) return AppColors.onboardSuccess;
    if (score < 55) return AppColors.onboardBluePrimary;
    if (score < 75) return AppColors.onboardWarning;
    return AppColors.onboardDanger;
  }

  Widget _socialLoginButton(String name, Color brandColor) {
    return InkWell(
      onTap: () async {
        setState(() { _kycStep = 8; }); // Loading state
        // 1. Link platform
        final sessionRes = await GigKavachApiService.linkPlatform(name);
        final sessionId = sessionRes['session_id'];
        
        if (sessionId != null) {
          // 2. Verify login (mock OTP)
          await GigKavachApiService.verifyPlatformLogin(sessionId, '9999999999', '123456');
          
          // 3. Sync data
          await GigKavachApiService.syncPlatformData(sessionId);
        }
        
        if (mounted) {
          setState(() { _kycStep = 9; }); // Success state
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02), 
              blurRadius: 4, 
              offset: const Offset(0, 2)
            )
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            SizedBox(
              width: 24,
              height: 24,
              child: SvgPicture.string(_getLogoSvg(name)),
            ),
            Expanded(
              child: Text(
                'Continue with $name', 
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.w600, 
                  color: AppColors.onboardTextDark
                ),
              ),
            ),
            const SizedBox(width: 36), // to balance the 24px logo
          ],
        ),
      ),
    );
  }

  String _getLogoSvg(String platform) {
    if (platform == 'Zomato') {
      return '''
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <rect width="100" height="100" rx="20" fill="#CB202D"/>
  <text x="50" y="70" font-family="Arial" font-weight="900" font-style="italic" font-size="65" fill="white" text-anchor="middle">Z</text>
</svg>
      ''';
    } else if (platform == 'Swiggy') {
      return '''
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <path d="M50 0 C 80 0 100 20 100 50 C 100 80 80 100 50 100 C 20 100 0 80 0 50 C 0 20 20 0 50 0 Z" fill="#FC8019"/>
  <text x="50" y="72" font-family="Arial" font-weight="900" font-size="65" fill="white" text-anchor="middle">S</text>
</svg>
      ''';
    } else if (platform == 'Blinkit') {
      return '''
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <rect width="100" height="100" rx="20" fill="#F8CB46"/>
  <text x="50" y="75" font-family="Arial" font-weight="900" font-size="75" fill="#0F8C3B" text-anchor="middle">b</text>
</svg>
      ''';
    }
    return '';
  }
}
