import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../AuthViewModel/auth_view_model.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
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
            const Image(image: AssetImage("assets/images/reset-pass.avif")),
            const SizedBox(height: 32),
            Text(
              "OTP Verified Successfully!",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "We'll send you a password reset link to your email. Click the button below to receive it.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: authVm.isLoading
                    ? null
                    : () async {
                        await authVm.resetPassword();

                        if (authVm.errorMessage != null && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(authVm.errorMessage!),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }

                        if (authVm.errorMessage == null && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Password reset email sent! Check your inbox.',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );

                          Navigator.popUntil(context, (r) => r.isFirst);
                        }
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
                    : const Text(
                        "Send Reset Link to Email",
                        style: TextStyle(fontSize: 16),
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
