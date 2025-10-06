import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_flex_app/navigation/app_router.dart';
import 'package:fitness_flex_app/presentation/pages/forget_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _focusPassword = FocusNode();

  bool _rememberMe = false;
  bool _obscure = true;
  bool _loading = false;

  late final AnimationController _fadeCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
        ..forward();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _focusPassword.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _loading = true);
    try {
      final auth = FirebaseAuth.instance;
      final cred = await auth.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      final user = cred.user;

      if (user != null && user.emailVerified) {
        if (mounted) Navigator.pushReplacementNamed(context, AppRouter.home);
      } else {
        await auth.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please verify your email before logging in.')),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      final msg = _mapAuthError(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Login failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email looks invalid.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
        return 'Incorrect password. Try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment.';
      default:
        return 'Login error: ${e.message ?? e.code}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Palette tuned for light/dark
    final primary = const Color(0xFF3F7BFF);
    final gradientTop = isDark ? const Color(0xFF0E1220) : const Color(0xFFEFF3FF);
    final gradientBottom = isDark ? const Color(0xFF101427) : const Color(0xFFFFFFFF);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // Soft gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [gradientTop, gradientBottom],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Decorative blobs (very soft)
            Positioned(top: -80, left: -50, child: _Blob(color: primary.withOpacity(.16), size: 220)),
            Positioned(bottom: -70, right: -40, child: _Blob(color: Colors.amber.withOpacity(.14), size: 190)),
            Positioned(top: 120, right: -60, child: _Blob(color: Colors.purple.withOpacity(.10), size: 140)),

            SafeArea(
              child: FadeTransition(
                opacity: _fadeCtrl,
                child: LayoutBuilder(
                  builder: (context, ctr) {
                    final wide = ctr.maxWidth > 520;
                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(wide ? 48 : 24, 28, wide ? 48 : 24, 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _LogoBadge(primary: primary),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Fitness Flex',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: .2,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),

                              // Headline
                              Text(
                                'Welcome back 👋',
                                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      height: 1.05,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sign in to continue your fitness journey',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(.72),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 28),

                              // Glass card
                              _GlassCard(
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      // Inputs use a unified, modern style
                                      _RoundedField(
                                        controller: _emailCtrl,
                                        label: 'Email',
                                        keyboardType: TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        prefixIcon: Icons.email_rounded,
                                        onSubmitted: (_) => FocusScope.of(context).requestFocus(_focusPassword),
                                        validator: (v) {
                                          final x = v?.trim() ?? '';
                                          if (x.isEmpty) return 'Please enter your email';
                                          final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(x);
                                          if (!ok) return 'Please enter a valid email';
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 14),
                                      _RoundedField(
                                        controller: _passwordCtrl,
                                        label: 'Password',
                                        focusNode: _focusPassword,
                                        obscure: _obscure,
                                        textInputAction: TextInputAction.done,
                                        onSubmitted: (_) => _signIn(),
                                        prefixIcon: Icons.lock_rounded,
                                        suffix: IconButton(
                                          tooltip: _obscure ? 'Show password' : 'Hide password',
                                          onPressed: () => setState(() => _obscure = !_obscure),
                                          icon: Icon(_obscure
                                              ? Icons.visibility_rounded
                                              : Icons.visibility_off_rounded),
                                        ),
                                        validator: (v) {
                                          final x = v ?? '';
                                          if (x.isEmpty) return 'Please enter your password';
                                          if (x.length < 6) return 'Password must be at least 6 characters';
                                          return null;
                                        },
                                      ),

                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Checkbox.adaptive(
                                            value: _rememberMe,
                                            onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                          ),
                                          const Text('Remember me', style: TextStyle(fontWeight: FontWeight.w600)),
                                          const Spacer(),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                                              );
                                            },
                                            child: const Text('Forgot password?'),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 8),
                                      // Pill primary button
                                      SizedBox(
                                        width: double.infinity,
                                        height: 56,
                                        child: ElevatedButton(
                                          onPressed: _loading ? null : _signIn,
                                          style: ElevatedButton.styleFrom(
                                            elevation: 0,
                                            backgroundColor: primary,
                                            foregroundColor: Colors.white,
                                            shape: const StadiumBorder(),
                                          ),
                                          child: AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 220),
                                            child: _loading
                                                ? const SizedBox(
                                                    key: ValueKey('spinner'),
                                                    height: 24,
                                                    width: 24,
                                                    child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white),
                                                  )
                                                : const Text(
                                                    'Sign In',
                                                    key: ValueKey('label'),
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w800,
                                                      fontSize: 17,
                                                      letterSpacing: .3,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Divider with "or"
                              Row(
                                children: [
                                  const Expanded(child: _Hairline()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text(
                                      'or continue with',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withOpacity(.65),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const Expanded(child: _Hairline()),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Social buttons (rounded)
                              Row(
                                children: [
                                  Expanded(
                                    child: _RoundedOutlineButton(
                                      icon: Icons.g_mobiledata_rounded,
                                      label: 'Google',
                                      onPressed: () {}, // hook later
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _RoundedOutlineButton(
                                      icon: Icons.apple_rounded,
                                      label: 'Apple',
                                      onPressed: () {}, // hook later
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),
                              // Sign up link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account?",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withOpacity(.85),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pushReplacementNamed(context, AppRouter.register),
                                    child: const Text('Sign Up'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- Modern UI pieces --------------------

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(top: 8, bottom: 14),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF141A2B) : Colors.white).withOpacity(.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? .35 : .12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge({required this.primary});
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [primary, const Color(0xFF6AA7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: primary.withOpacity(.28), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: const Icon(Icons.fitness_center_rounded, color: Colors.white),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withOpacity(.55), blurRadius: 50, spreadRadius: -14),
        ],
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.2,
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withOpacity(.45),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// Rounded input with consistent style
class _RoundedField extends StatelessWidget {
  const _RoundedField({
    required this.controller,
    required this.label,
    this.prefixIcon,
    this.suffix,
    this.obscure = false,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscure;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? const Color(0xFF1A2135) : const Color(0xFFF4F6FB);

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: fill,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        hintStyle: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(.55),
        ),
        labelStyle: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(.75),
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.black.withOpacity(.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(.9), width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.6),
        ),
      ),
    );
  }
}

// Rounded outline social button
class _RoundedOutlineButton extends StatelessWidget {
  const _RoundedOutlineButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: const StadiumBorder(),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(.5)),
      ),
    );
  }
}
