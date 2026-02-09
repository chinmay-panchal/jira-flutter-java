import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../AuthViewModel/auth_view_model.dart';
import 'otp_screen.dart';

class ForgotPassChoiceScreen extends StatefulWidget {
  const ForgotPassChoiceScreen({super.key});

  @override
  State<ForgotPassChoiceScreen> createState() => _ForgotPassChoiceScreenState();
}

class _ForgotPassChoiceScreenState extends State<ForgotPassChoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  bool isEmailLoading = false;
  bool isMobileLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
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
            const Image(image: AssetImage("assets/images/forgot-pass.jpg")),
            const SizedBox(height: 32),
            Text(
              "Reset Password",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Enter your email to receive OTP",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),

            Form(
              key: _formKey,
              child: TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: "Email",
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(v)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 56,
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isEmailLoading || isMobileLoading
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;

                        setState(() => isEmailLoading = true);

                        final email = emailController.text.trim();

                        await authVm.sendOtp(email);

                        setState(() => isEmailLoading = false);

                        if (!mounted) return;

                        if (authVm.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(authVm.errorMessage!),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OtpScreen(),
                            ),
                          );
                        }
                      },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.primary, width: 2),
                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: isEmailLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      )
                    : Icon(Icons.email, color: colorScheme.primary),
                label: Text(
                  "Send OTP via Email",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 56,
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isEmailLoading || isMobileLoading
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;

                        setState(() => isMobileLoading = true);

                        final email = emailController.text.trim();

                        final success = await authVm.checkUserAndGetMobile(
                          email,
                        );

                        if (!mounted) {
                          setState(() => isMobileLoading = false);
                          return;
                        }

                        if (!success) {
                          setState(() => isMobileLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                authVm.errorMessage ?? 'User not found',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        await authVm.sendPhoneOtpForReset(
                          context: context,
                          onCodeSent: () {
                            if (mounted) {
                              setState(() => isMobileLoading = false);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OtpScreen(
                                    phoneNumber: authVm.userMobileNumber ?? '',
                                  ),
                                ),
                              );
                            }
                          },
                          onError: () {
                            if (mounted) {
                              setState(() => isMobileLoading = false);
                            }
                          },
                        );

                        if (authVm.errorMessage != null && mounted) {
                          setState(() => isMobileLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(authVm.errorMessage!),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.secondary, width: 2),
                  backgroundColor: colorScheme.secondary.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: isMobileLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.secondary,
                        ),
                      )
                    : Icon(Icons.phone_android, color: colorScheme.secondary),
                label: Text(
                  "Send OTP via Mobile",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.secondary,
                  ),
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
