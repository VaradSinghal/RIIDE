import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class SignInScreen extends StatefulWidget {
  final void Function(BuildContext) onSignInComplete;

  const SignInScreen({super.key, required this.onSignInComplete});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isVerifying = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  BoxDecoration get _cardDecor => BoxDecoration(
    color: AppColors.onboardCard,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.onboardBorder),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF1565C0).withValues(alpha: 0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      )
    ],
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.onboardTextBody,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.onboardBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.onboardBlueSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.onboardBluePrimary,
              size: 20,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppColors.onboardGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.lock_person_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onboardTextDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to access your policy and earnings.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.onboardTextBody,
                ),
              ),
              const SizedBox(height: 32),

              _label('Phone Number'),
              Container(
                decoration: _cardDecor,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(right: BorderSide(color: AppColors.onboardBorder)),
                      ),
                      child: const Text(
                        '+91',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.onboardTextDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10)
                        ],
                        style: const TextStyle(fontSize: 15, color: AppColors.onboardTextDark),
                        decoration: const InputDecoration(
                          hintText: 'Enter 10-digit number',
                          hintStyle: TextStyle(color: AppColors.onboardTextMuted),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        ),
                        onChanged: (_) => setState(() {}),
                        enabled: !_otpSent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (!_otpSent)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _phoneController.text.length == 10
                        ? () async {
                            setState(() => _otpSent = true);
                            await GigKavachApiService.requestOtp('+91${_phoneController.text}');
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.onboardBluePrimary,
                      disabledBackgroundColor: AppColors.onboardBorder,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Send OTP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              if (_otpSent) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.sms_rounded, color: AppColors.onboardBluePrimary, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Enter OTP',
                            style: TextStyle(
                              color: AppColors.onboardBluePrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => setState(() {
                              _otpSent = false;
                              _otpController.clear();
                            }),
                            child: const Text(
                              'Change Number',
                              style: TextStyle(
                                color: AppColors.onboardBlueLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6)
                        ],
                        style: const TextStyle(
                          fontSize: 24,
                          color: AppColors.onboardTextDark,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 12,
                        ),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          hintText: '• • • • • •',
                          hintStyle: TextStyle(
                            color: AppColors.onboardTextMuted,
                            letterSpacing: 12,
                          ),
                          border: InputBorder.none,
                        ),
                        onChanged: (val) async {
                          if (val.length == 6 && !_isVerifying) {
                            setState(() => _isVerifying = true);
                            final result = await GigKavachApiService.login(
                              '+91${_phoneController.text}',
                              otp: val,
                            );
                            if (result.containsKey('access_token')) {
                              if (mounted) widget.onSignInComplete(context);
                            } else {
                              setState(() => _isVerifying = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Invalid OTP. Please try again.')),
                                );
                              }
                            }
                          }
                        },
                        enabled: !_isVerifying,
                      ),
                      if (_isVerifying)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onboardBluePrimary,
                              ),
                            ),
                          ),
                        )
                      else
                        const Center(
                          child: Text(
                            'Enter any 6-digit code for demo',
                            style: TextStyle(fontSize: 11, color: AppColors.onboardTextMuted),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
