import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitness_flex_app/navigation/app_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Basic info
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();

  // Passwords
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // TDEE inputs
  final _weightController = TextEditingController(); // kg
  final _heightController = TextEditingController(); // cm
  String _gender = 'male';
  String _activity = 'moderate';
  String _nutritionGoal = 'maintain'; // bulk / cut / maintain
  DateTime? _selectedDate; // DOB
  String? _selectedFitnessGoal;

  // Calculated macros preview
  Map<String, dynamic>? _previewMacros;

  // Loading state
  bool _submitting = false;

  // Animation
  late final AnimationController _fadeCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();

  final List<String> fitnessGoals = const [
    'Weight Loss',
    'Muscle Gain',
    'Endurance',
    'General Fitness',
    'Body Toning',
  ];

  final Map<String, double> _activityMultipliers = const {
    "sedentary": 1.2,
    "light": 1.375,
    "moderate": 1.55,
    "active": 1.725,
    "very_active": 1.9,
  };

  void _syncFitnessToNutrition(String? fitness) {
    if (fitness == null) return;
    switch (fitness) {
      case 'Weight Loss':
        _nutritionGoal = 'cut';
        break;
      case 'Muscle Gain':
        _nutritionGoal = 'bulk';
        break;
      default:
        _nutritionGoal = 'maintain';
    }
  }

  int? _ageFromDob(DateTime? dob) {
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age < 0 ? 0 : age;
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(DateTime.now().year - 20),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _calculateMacros() {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select your Date of Birth")),
      );
      return;
    }
    if (_weightController.text.trim().isEmpty || _heightController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in weight and height")),
      );
      return;
    }

    final age = _ageFromDob(_selectedDate) ?? 0;
    final weight = double.tryParse(_weightController.text.trim()) ?? 0; // kg
    final height = double.tryParse(_heightController.text.trim()) ?? 0; // cm
    if (weight <= 0 || height <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid positive numbers for weight/height")),
      );
      return;
    }

    // Mifflin–St Jeor BMR
    double bmr = _gender == "male"
        ? (10 * weight + 6.25 * height - 5 * age + 5)
        : (10 * weight + 6.25 * height - 5 * age - 161);

    double tdee = bmr * (_activityMultipliers[_activity] ?? 1.55);

    // Goal adjustment
    if (_nutritionGoal == "bulk") tdee += 400;
    if (_nutritionGoal == "cut") tdee -= 400;

    // Macros
    final protein = 2 * weight; // g/day
    final fat = (tdee * 0.25) / 9; // g/day
    final carbs = (tdee - (protein * 4 + fat * 9)) / 4; // g/day

    setState(() {
      _previewMacros = {
        "calories": tdee.round(),
        "protein": protein.round(),
        "fat": fat.round(),
        "carbs": carbs.round(),
      };
    });
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    if (_previewMacros == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please tap Calculate to preview macros first")),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final auth = FirebaseAuth.instance;
      final cred = await auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final uid = cred.user!.uid;

      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "firstName": _firstNameController.text.trim(),
        "lastName": _lastNameController.text.trim(),
        "email": _emailController.text.trim(),
        "dob": _selectedDate?.toIso8601String(),
        "fitnessGoal": _selectedFitnessGoal,
        "gender": _gender,
        "weightKg": _weightController.text.trim(),
        "heightCm": _heightController.text.trim(),
        "activity": _activity,
        "nutritionGoal": _nutritionGoal,
        "createdAt": DateTime.now().toIso8601String(),
        "macros": _previewMacros,
      });

      await cred.user!.sendEmailVerification();

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRouter.verifyEmail);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registration failed: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = const Color(0xFF3F7BFF);
    final gradientTop = isDark ? const Color(0xFF0E1220) : const Color(0xFFEFF3FF);
    final gradientBottom = isDark ? const Color(0xFF101427) : const Color(0xFFFFFFFF);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, AppRouter.login);
        return false;
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              // Background gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [gradientTop, gradientBottom],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Subtle blobs
              Positioned(top: -90, left: -60, child: _Blob(color: primary.withOpacity(.16), size: 240)),
              Positioned(bottom: -70, right: -40, child: _Blob(color: Colors.amber.withOpacity(.14), size: 200)),
              Positioned(top: 160, right: -60, child: _Blob(color: Colors.purple.withOpacity(.10), size: 150)),

              SafeArea(
                child: FadeTransition(
                  opacity: _fadeCtrl,
                  child: LayoutBuilder(
                    builder: (context, ctr) {
                      final wide = ctr.maxWidth > 700;
                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(wide ? 48 : 24, 20, wide ? 48 : 24, 24),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 820),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top bar with refreshed logo badge
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => Navigator.pushReplacementNamed(context, AppRouter.login),
                                      icon: const Icon(Icons.arrow_back_rounded),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.black.withOpacity(.05),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const _LogoBadge(), // NEW logo
                                    const SizedBox(width: 10),
                                    Text(
                                      'Create Account',
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Start your fitness journey today',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withOpacity(.72),
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 22),

                                Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      // ========== Section: Basic Info ==========
                                      _SectionHeader(icon: Icons.person_rounded, title: 'Basic Information'),
                                      _GlassCard(
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _RoundedField(
                                                    controller: _firstNameController,
                                                    label: 'First Name',
                                                    prefixIcon: Icons.badge_outlined,
                                                    validator: (v) =>
                                                        (v == null || v.trim().isEmpty) ? 'Enter first name' : null,
                                                  ),
                                                ),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                  child: _RoundedField(
                                                    controller: _lastNameController,
                                                    label: 'Last Name',
                                                    prefixIcon: Icons.badge,
                                                    validator: (v) =>
                                                        (v == null || v.trim().isEmpty) ? 'Enter last name' : null,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 14),
                                            _RoundedField(
                                              controller: _emailController,
                                              label: 'Email',
                                              keyboardType: TextInputType.emailAddress,
                                              prefixIcon: Icons.email_rounded,
                                              validator: (v) {
                                                final x = v?.trim() ?? '';
                                                if (x.isEmpty) return 'Enter your email';
                                                final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(x);
                                                if (!ok) return 'Enter a valid email';
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 14),
                                            // DOB
                                            _RoundedTapField(
                                              label: 'Date of Birth',
                                              prefixIcon: Icons.calendar_today_rounded,
                                              valueText: _selectedDate != null
                                                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                                  : 'Select your date of birth',
                                              onTap: () => _selectDate(context),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // ========== Section: Fitness Profile ==========
                                      const SizedBox(height: 14),
                                      _SectionHeader(icon: Icons.local_fire_department_rounded, title: 'Fitness Profile'),
                                      _GlassCard(
                                        child: Column(
                                          children: [
                                            // Fitness Goal
                                            _RoundedDropdown<String>(
                                              label: 'Fitness Goal',
                                              prefixIcon: Icons.fitness_center_rounded,
                                              value: _selectedFitnessGoal,
                                              items: fitnessGoals,
                                              onChanged: (val) {
                                                setState(() {
                                                  _selectedFitnessGoal = val;
                                                  _syncFitnessToNutrition(val);
                                                });
                                              },
                                              validator: (v) =>
                                                  (v == null || v.isEmpty) ? 'Select your fitness goal' : null,
                                            ),
                                            const SizedBox(height: 14),

                                            // Gender + Activity
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _RoundedDropdown<String>(
                                                    label: 'Gender',
                                                    prefixIcon: Icons.person_outline_rounded,
                                                    value: _gender,
                                                    items: const ['male', 'female'],
                                                    onChanged: (val) => setState(() => _gender = val ?? 'male'),
                                                  ),
                                                ),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                  child: _RoundedDropdown<String>(
                                                    label: 'Activity Level',
                                                    prefixIcon: Icons.directions_run_rounded,
                                                    value: _activity,
                                                    items: const [
                                                      'sedentary',
                                                      'light',
                                                      'moderate',
                                                      'active',
                                                      'very_active',
                                                    ],
                                                    onChanged: (val) => setState(() => _activity = val ?? 'moderate'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 14),

                                            // Weight + Height
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _RoundedField(
                                                    controller: _weightController,
                                                    label: 'Weight (kg)',
                                                    prefixIcon: Icons.monitor_weight_rounded,
                                                    keyboardType:
                                                        const TextInputType.numberWithOptions(decimal: true),
                                                    inputFormatters: [
                                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                                    ],
                                                    validator: (v) =>
                                                        (v == null || v.trim().isEmpty) ? 'Enter weight' : null,
                                                  ),
                                                ),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                  child: _RoundedField(
                                                    controller: _heightController,
                                                    label: 'Height (cm)',
                                                    prefixIcon: Icons.height_rounded,
                                                    keyboardType:
                                                        const TextInputType.numberWithOptions(decimal: true),
                                                    inputFormatters: [
                                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                                                    ],
                                                    validator: (v) =>
                                                        (v == null || v.trim().isEmpty) ? 'Enter height' : null,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 14),

                                            // Nutrition goal (synced default)
                                            _RoundedDropdown<String>(
                                              label: 'Nutrition Goal',
                                              prefixIcon: Icons.restaurant_rounded,
                                              value: _nutritionGoal,
                                              items: const ['bulk', 'cut', 'maintain'],
                                              onChanged: (val) => setState(() => _nutritionGoal = val ?? 'maintain'),
                                            ),

                                            const SizedBox(height: 16),

                                            // Calculate button
                                            SizedBox(
                                              width: double.infinity,
                                              height: 52,
                                              child: OutlinedButton(
                                                onPressed: _calculateMacros,
                                                style: OutlinedButton.styleFrom(
                                                  shape: const StadiumBorder(),
                                                  side: BorderSide(
                                                      color: Theme.of(context).dividerColor.withOpacity(.5)),
                                                ),
                                                child: const Text(
                                                  'Calculate',
                                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                                ),
                                              ),
                                            ),

                                            // Macros preview
                                            if (_previewMacros != null) ...[
                                              const SizedBox(height: 16),
                                              _MacrosCard(macros: _previewMacros!),
                                            ],
                                          ],
                                        ),
                                      ),

                                      // ========== Section: Security ==========
                                      const SizedBox(height: 14),
                                      _SectionHeader(icon: Icons.lock_rounded, title: 'Security'),
                                      _GlassCard(
                                        child: Column(
                                          children: [
                                            _RoundedField(
                                              controller: _passwordController,
                                              label: 'Password',
                                              prefixIcon: Icons.lock_outline_rounded,
                                              obscure: _obscurePassword,
                                              suffix: IconButton(
                                                onPressed: () =>
                                                    setState(() => _obscurePassword = !_obscurePassword),
                                                icon: Icon(
                                                  _obscurePassword
                                                      ? Icons.visibility_rounded
                                                      : Icons.visibility_off_rounded,
                                                ),
                                              ),
                                              validator: (v) {
                                                final x = v ?? '';
                                                if (x.isEmpty) return 'Enter a password';
                                                if (x.length < 6) return 'Password must be at least 6 characters';
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 14),
                                            _RoundedField(
                                              controller: _confirmPasswordController,
                                              label: 'Confirm Password',
                                              prefixIcon: Icons.lock_outline_rounded,
                                              obscure: _obscureConfirmPassword,
                                              suffix: IconButton(
                                                onPressed: () => setState(
                                                    () => _obscureConfirmPassword = !_obscureConfirmPassword),
                                                icon: Icon(
                                                  _obscureConfirmPassword
                                                      ? Icons.visibility_rounded
                                                      : Icons.visibility_off_rounded,
                                                ),
                                              ),
                                              validator: (v) {
                                                final x = v ?? '';
                                                if (x.isEmpty) return 'Confirm your password';
                                                if (x != _passwordController.text) return 'Passwords do not match';
                                                return null;
                                              },
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 18),

                                      // Create Account
                                      SizedBox(
                                        width: double.infinity,
                                        height: 56,
                                        child: ElevatedButton(
                                          onPressed: _submitting ? null : _createAccount,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primary,
                                            foregroundColor: Colors.white,
                                            shape: const StadiumBorder(),
                                            elevation: 0,
                                          ),
                                          child: AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 220),
                                            child: _submitting
                                                ? const SizedBox(
                                                    key: ValueKey('spinner'),
                                                    height: 24,
                                                    width: 24,
                                                    child: CircularProgressIndicator(
                                                        strokeWidth: 2.6, color: Colors.white),
                                                  )
                                                : const Text(
                                                    'Create Account',
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

                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Already have an account?',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.color
                                                  ?.withOpacity(.9),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pushReplacementNamed(context, AppRouter.login),
                                            child: const Text('Sign In'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
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
      ),
    );
  }
}

// ==================== Reusable UI Pieces ====================

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF141A2B) : Colors.white).withOpacity(.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(.06)),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

// Refreshed rounded logo badge (indigo→violet gradient, inner ring, dumbbell+spark)
class _LogoBadge extends StatelessWidget {
  const _LogoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9B5EFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // soft inner ring
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(.18),
              border: Border.all(color: Colors.white.withOpacity(.35), width: 1),
            ),
          ),
          const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 20),
          const Positioned(
            right: 10,
            top: 10,
            child: Icon(Icons.star_rounded, color: Colors.white, size: 10),
          ),
        ],
      ),
    );
  }
}

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
    this.inputFormatters,
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
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
      inputFormatters: inputFormatters,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: fill,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: cs.onSurface.withOpacity(.80)) : null,
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        hintStyle: TextStyle(color: cs.onSurfaceVariant),
        labelStyle: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.black.withOpacity(.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: cs.primary.withOpacity(.9), width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: cs.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: cs.error, width: 1.6),
        ),
      ),
    );
  }
}

// Tappable rounded "field" (for DOB picker)
class _RoundedTapField extends StatelessWidget {
  const _RoundedTapField({
    required this.label,
    required this.valueText,
    required this.onTap,
    this.prefixIcon,
  });

  final String label;
  final String valueText;
  final VoidCallback onTap;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? const Color(0xFF1A2135) : const Color(0xFFF4F6FB);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
          filled: true,
          fillColor: fill,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: cs.onSurface.withOpacity(.80)) : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.black.withOpacity(.06)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(color: cs.primary.withOpacity(.9), width: 1.6),
          ),
        ),
        child: Text(
          valueText,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: valueText.startsWith('Select') ? cs.onSurfaceVariant : cs.onSurface,
          ),
        ),
      ),
    );
  }
}

class _RoundedDropdown<T> extends StatelessWidget {
  const _RoundedDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.prefixIcon,
  });

  final String label;
  final T? value;
  final List<T> items;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? const Color(0xFF1A2135) : const Color(0xFFF4F6FB);

    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      dropdownColor: fill,
      iconEnabledColor: cs.onSurface.withOpacity(.80),
      items: items.map((e) {
        return DropdownMenuItem<T>(
          value: e,
          child: Text(
            e.toString(),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      style: TextStyle(
        color: cs.onSurface,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: fill,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: cs.onSurface.withOpacity(.80)) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.black.withOpacity(.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: cs.primary.withOpacity(.9), width: 1.6),
        ),
      ),
      borderRadius: BorderRadius.circular(18),
    );
  }
}

class _MacrosCard extends StatelessWidget {
  const _MacrosCard({required this.macros});
  final Map<String, dynamic> macros;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Calories', '${macros['calories']} kcal', Icons.local_fire_department_rounded),
      ('Protein', '${macros['protein']} g', Icons.fitness_center_rounded),
      ('Carbs', '${macros['carbs']} g', Icons.rice_bowl_rounded),
      ('Fat', '${macros['fat']} g', Icons.water_drop_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(.85),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items
            .map(
              (x) => Expanded(
                child: _BadgeStat(title: x.$1, value: x.$2, icon: x.$3),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _BadgeStat extends StatelessWidget {
  const _BadgeStat({required this.title, required this.value, required this.icon});
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 18),
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
          Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withOpacity(.55), blurRadius: 50, spreadRadius: -14)],
        ),
      ),
    );
  }
}
