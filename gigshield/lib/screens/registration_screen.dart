import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

import '../services/supabase_service.dart';
import '../services/premium_engine.dart';
import '../services/api_service.dart';

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
  final _aadhaarController = TextEditingController();
  bool _kycVerified = false;
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
      case 1: return _nameController.text.length >= 2 && _ageController.text.isNotEmpty && (int.tryParse(_ageController.text) ?? 0) >= 18 && _kycVerified;
      case 2: return true;
      case 3: return _selectedZone.isNotEmpty;
      case 4: return _calculatedPremium != null;
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
        _inputField('Full Name', _nameController, Icons.person_rounded),
        const SizedBox(height: 16),
        _inputField('Age', _ageController, Icons.cake_rounded, keyboardType: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)], hint: 'e.g. 28'),
        if (_ageController.text.isNotEmpty && (int.tryParse(_ageController.text) ?? 0) < 18)
          Padding(padding: const EdgeInsets.only(top: 6), child: Text('Must be 18 or older', style: TextStyle(fontSize: 11, color: AppColors.onboardDanger))),
        const SizedBox(height: 16),
        _dropdown('City', _selectedCity, _cities, Icons.location_city_rounded, (v) => setState(() { _selectedCity = v!; _selectedZone = _cityZones[_selectedCity]!.first; })),
        const SizedBox(height: 16),
        _dropdown('Platform', _selectedPlatform, _platforms, Icons.delivery_dining_rounded, (v) => setState(() => _selectedPlatform = v!)),
        const SizedBox(height: 16),
        _dropdown('Vehicle', _vehicleType, _vehicles, Icons.two_wheeler_rounded, (v) => setState(() => _vehicleType = v!)),
        const SizedBox(height: 16),
        
        // KYC Section
        _label('Identity Verification (DigiLocker)'),
        _inputField('Aadhaar Number', _aadhaarController, Icons.badge_rounded, keyboardType: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(12)], hint: '12-digit Aadhaar'),
        const SizedBox(height: 12),
        if (!_kycVerified) SizedBox(width: double.infinity, child: OutlinedButton(
          onPressed: _aadhaarController.text.length == 12 ? () async {
            final res = await GigKavachApiService.verifyKyc('aadhaar', _aadhaarController.text);
            if (res['status'] == 'verified') {
              setState(() => _kycVerified = true);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('KYC Failed')));
            }
          } : null,
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.onboardBluePrimary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
          child: const Text('Verify Identity', style: TextStyle(color: AppColors.onboardBluePrimary, fontWeight: FontWeight.w600)),
        )),
        if (_kycVerified) Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.onboardSuccessBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.onboardSuccess.withValues(alpha: 0.3))),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.onboardSuccess.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.verified_user_rounded, color: AppColors.onboardSuccess, size: 18)),
              const SizedBox(width: 12),
              const Expanded(child: Text('Identity Verified successfully via DigiLocker.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.onboardSuccess))),
            ]),
        ),
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
    setState(() { _calculatedPremium = result; _isCalculatingPremium = false; _calculationStep = 0; });
  }

  Widget _buildPlanStep() {
    if (_calculatedPremium == null) {
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
              const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.onboardBluePrimary, strokeWidth: 2)),
              const SizedBox(height: 16),
              _simStep('Analyzing age & travel profile', _calculationStep >= 1),
              _simStep('Evaluating area historic conditions', _calculationStep >= 2),
              _simStep('Processing order volume risk', _calculationStep >= 3),
              _simStep('Computing personalized premium', _calculationStep >= 4),
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
    ]));
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
}
