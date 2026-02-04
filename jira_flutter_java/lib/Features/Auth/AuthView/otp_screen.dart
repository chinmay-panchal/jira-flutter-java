import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../AuthViewModel/auth_view_model.dart';
import 'reset_pass_screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final otpController = TextEditingController();

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
            Form(
              key: _formKey,
              child: TextFormField(
                controller: otpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Enter OTP",
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

                      // Clear any previous errors
                      authVm.clearError();

                      // Verify OTP and get result
                      final success = await authVm.verifyOtp(
                        otpController.text.trim(),
                      );

                      if (!mounted) return;

                      // Handle failure case
                      if (!success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              authVm.errorMessage ?? 'Invalid OTP. Please try again.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return; // STOP here - don't navigate
                      }

                      // Handle success case
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('OTP verified successfully!'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );

                      // Navigate to reset password screen
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