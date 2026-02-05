import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jira_flutter_java/Features/Auth/AuthView/reset_pass_screen.dart';
import 'package:provider/provider.dart';
import '../AuthViewModel/auth_view_model.dart';
import 'mobile_reset_pass_screen.dart';

class MobileOtpScreen extends StatefulWidget {
  final String phoneNumber;

  const MobileOtpScreen({super.key, required this.phoneNumber});

  @override
  State<MobileOtpScreen> createState() => _MobileOtpScreenState();
}

class _MobileOtpScreenState extends State<MobileOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final otpController = TextEditingController();

  String getMaskedPhoneNumber() {
    final phone = widget.phoneNumber;
    if (phone.length > 4) {
      final lastFourDigits = phone.substring(phone.length - 4);
      return '+91 ******$lastFourDigits';
    }
    return phone;
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

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
              ),
            ),
            const SizedBox(height: 16),
            const Image(image: AssetImage("assets/images/forgot_pass.jpg")),
            const SizedBox(height: 32),
            const Text(
              "Enter OTP",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "We sent a code to ${getMaskedPhoneNumber()}",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: otpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Enter 6-digit OTP",
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                validator: (v) =>
                    v == null || v.length != 6 ? 'OTP must be 6 digits' : null,
              ),
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: authVm.isLoading
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;

                      authVm.clearError();

                      final success = await authVm.verifyPhoneOtp(
                        otpController.text.trim(),
                      );

                      if (!mounted) return;

                      if (!success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(authVm.errorMessage ?? 'Invalid OTP'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('OTP verified successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ResetPasswordScreen(),
                        ),
                      );
                    },
              child: Container(
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(),
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: authVm.isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        "Verify OTP",
                        style: TextStyle(color: Colors.black),
                      ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
