import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef PasswordResetSender = Future<void> Function(String email);

/// Password recovery screen.
/// An injectable sender makes the complete UI testable without emailing users.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.sendResetEmail});
  final PasswordResetSender? sendResetEmail;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_sending || !(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);

    try {
      final send = widget.sendResetEmail ??
          (String email) => FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      await send(_emailController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
          'If this email has a FitnessFlex account, a password reset link will arrive shortly. Check your inbox and spam folder.',
        )),
      );
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyFirebaseMessage(error.code))),
      );
    } catch (error, stackTrace) {
      // Avoid exposing implementation details, minified JS exception types,
      // or Firebase response bodies to end users. Log for developer diagnosis.
      debugPrint('Password reset failed unexpectedly: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
          'We could not send the reset email. Please try again shortly or contact support if this continues.',
        )),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Please enter your email';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String _friendlyFirebaseMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Connection unavailable. Check your internet and try again.';
      case 'operation-not-allowed':
        return 'Password resets are currently unavailable. Please contact support.';
      case 'unauthorized-domain':
        return 'This site is not authorised for password recovery. Please contact support.';
      default:
        return 'Unable to send a reset email right now. Please try again later.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('RESET YOUR PASSWORD', style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11, fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    )),
                    const SizedBox(height: 14),
                    Text('Get back on track.',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800, letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Enter your email address and we’ll send you a link to reset your password.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                      validator: _validateEmail,
                      onFieldSubmitted: (_) => _resetPassword(),
                      enabled: !_sending,
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _sending ? null : _resetPassword,
                        child: _sending
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Send Reset Link'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
