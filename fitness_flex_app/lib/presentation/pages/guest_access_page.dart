import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fitness_flex_app/core/themes/app_theme.dart';
import 'package:fitness_flex_app/navigation/app_router.dart';

/// Starts a real anonymous Firebase account so existing app pages and their
/// Firestore repositories use an isolated users/{uid} record tree.
class GuestAccessPage extends StatefulWidget {
  const GuestAccessPage({super.key, this.startSession, this.onSuccess});
  final Future<void> Function()? startSession;
  final VoidCallback? onSuccess;
  @override
  State<GuestAccessPage> createState() => _GuestAccessPageState();
}

class _GuestAccessPageState extends State<GuestAccessPage> {
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }
  Future<void> _start() async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      if (widget.startSession != null) {
        await widget.startSession!();
      } else {
        final auth = FirebaseAuth.instance;
        if (auth.currentUser == null) {
          final credentials = await auth.signInAnonymously();
          if (credentials.user == null) {
            throw StateError('Anonymous authentication returned no user');
          }
        }
      }
      if (!mounted) return;
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        Navigator.pushNamedAndRemoveUntil(context, AppRouter.home, (_) => false);
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => _error = switch (error.code) {
        'operation-not-allowed' =>
          'Guest access has not been enabled for this Firebase project. '
          'The developer needs to enable Anonymous under Authentication → Sign-in method.',
        'network-request-failed' =>
          'Unable to connect to Firebase. Check your connection and retry.',
        'too-many-requests' =>
          'Too many attempts right now. Please try again later.',
        _ => 'Guest sign-in is unavailable (' + error.code + '). Please retry or use offline preview.',
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error =
          'Unable to start a guest session. Please retry or use offline preview.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Continue as Guest')),
    body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 510),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 66, height: 66,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.person_outline, size: 35,
                color: AppTheme.primaryColor)),
            const SizedBox(height: 18),
            Text('Your workout. No password.',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            const Text(
              'Guest mode uses the full FitnessFlex application. '
              'Your activity is stored under a separate anonymous Firebase account.',
              style: TextStyle(height: 1.5)),
            const SizedBox(height: 10),
            const Text(
              'Important: Guest records are tied to this browser session. '
              'Signing out, resetting browser storage or switching to a new account '
              'can make them inaccessible. Guest data is not automatically transferred '
              'when you later sign in.',
              style: TextStyle(fontSize: 12, color: AppTheme.greyColor,
                height: 1.5)),
            if (_busy) ...[
              const SizedBox(height: 23),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 10),
              const Center(child: Text('Starting your guest session…')),
            ],
            if (_error != null) ...[
              const SizedBox(height: 20),
              Text(_error!, style: const TextStyle(
                color: Colors.redAccent, height: 1.5)),
              const SizedBox(height: 14),
              FilledButton(onPressed: _busy ? null : _start,
                child: const Text('Retry Guest Access')),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.pushReplacementNamed(
                  context, AppRouter.guestPreview),
                child: const Text('Open limited offline preview'),
              ),
            ],
          ]),
      ),
    ))),
  );
}
