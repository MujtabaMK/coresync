import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      showErrorSnackBar(context, 'Please enter your phone number');
      return;
    }

    // Ensure the number starts with '+'
    final formattedPhone = phone.startsWith('+') ? phone : '+$phone';

    setState(() => _isLoading = true);

    final authRepository = context.read<AuthCubit>().repository;

    await authRepository.verifyPhoneNumber(
      phoneNumber: formattedPhone,
      onVerificationCompleted: (credential) async {
        // Auto-sign-in on Android when the SMS is auto-detected
        try {
          final userCredential =
              await authRepository.signInWithCredential(credential);
          if (userCredential.user != null) {
            await authRepository.createUserDocument(userCredential.user!);
            if (mounted) context.go('/todo');
          }
        } catch (e) {
          if (mounted) {
            showErrorSnackBar(context, 'Auto verification failed: $e');
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
      onVerificationFailed: (error) {
        if (mounted) {
          setState(() => _isLoading = false);
          showErrorSnackBar(
            context,
            error.message ?? 'Phone verification failed',
          );
        }
      },
      onCodeSent: (verificationId, resendToken) {
        if (mounted) {
          setState(() => _isLoading = false);
          context.go('/otp', extra: {
            'verificationId': verificationId,
            'phoneNumber': formattedPhone,
          });
        }
      },
      onCodeAutoRetrievalTimeout: (verificationId) {
        // Timeout for auto-retrieval; no action needed
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome to CoreSync',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your phone number to get started',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+1234567890',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  onSubmitted: (_) => _sendOtp(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Send OTP'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
