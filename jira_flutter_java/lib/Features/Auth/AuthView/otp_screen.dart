import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../AuthViewModel/auth_view_model.dart';
import 'reset_pass_screen.dart';

class OtpScreen extends StatefulWidget {
  final String? phoneNumber;

  const OtpScreen({super.key, this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _formKey = GlobalKey<FormState>();

  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  String get _otp => _controllers.map((c) => c.text).join();

  bool get _isMobileOtp => widget.phoneNumber != null;

  String getMaskedPhoneNumber() {
    if (widget.phoneNumber == null) return '';
    final phone = widget.phoneNumber!;
    if (phone.length > 4) {
      return '+91 ******${phone.substring(phone.length - 4)}';
    }
    return phone;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Widget _otpBox(int index) {
    return SizedBox(
      width: 48,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 20),
        decoration: const InputDecoration(counterText: ''),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          }
          if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
        validator: (v) => v == null || v.isEmpty ? '' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 80),
            Text(
              "Jira",
              style: GoogleFonts.calligraffitti(
                fontSize: 48,
                fontWeight: FontWeight.w500,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Image(image: AssetImage("assets/images/forgot_pass.jpg")),
            const SizedBox(height: 32),

            Text(
              "Enter OTP",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),

            if (_isMobileOtp) ...[
              Text(
                "We sent a code to ${getMaskedPhoneNumber()}",
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
              ),
              const SizedBox(height: 24),
            ] else
              const SizedBox(height: 24),

            Form(
              key: _formKey,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, _otpBox),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: authVm.isLoading
                    ? null
                    : () async {
                        if (_otp.length != 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('OTP must be 6 digits'),
                            ),
                          );
                          return;
                        }

                        authVm.clearError();

                        final success = _isMobileOtp
                            ? await authVm.verifyPhoneOtp(_otp)
                            : await authVm.verifyOtp(_otp);

                        if (!mounted) return;

                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                authVm.errorMessage ?? 'Invalid OTP',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ResetPasswordScreen(),
                          ),
                        );
                      },
                child: authVm.isLoading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : const Text("Verify OTP", style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
