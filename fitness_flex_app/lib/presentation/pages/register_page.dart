import 'package:flutter/material.dart';
import 'package:fitness_flex_app/navigation/app_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_flex_app/presentation/pages/verify_email_page.dart';


class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // NEW: Needed for TDEE
  final _weightController = TextEditingController(); // kg
  final _heightController = TextEditingController(); // cm
  String _gender = 'male';
  String _activity = 'moderate';
  String _nutritionGoal = 'maintain'; // bulk / cut / maintain

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  DateTime? _selectedDate; // DOB (used to compute age)
  String? _selectedFitnessGoal;

  // Macros preview
  Map<String, dynamic>? _previewMacros;

  final List<String> fitnessGoals = [
    'Weight Loss',
    'Muscle Gain',
    'Endurance',
    'General Fitness',
    'Body Toning',
  ];

  final _activityMultipliers = const {
    "sedentary": 1.2,
    "light": 1.375,
    "moderate": 1.55,
    "active": 1.725,
    "very_active": 1.9,
  };

  // Map your fitness goal -> nutrition goal default
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _calculateMacros() {
    // Validate required inputs
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select your Date of Birth")),
      );
      return;
    }
    if (_weightController.text.trim().isEmpty ||
        _heightController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in weight and height")),
      );
      return;
    }

    final age = _ageFromDob(_selectedDate) ?? 0;
    final weight = double.tryParse(_weightController.text.trim()) ?? 0; // kg
    final height = double.tryParse(_heightController.text.trim()) ?? 0; // cm

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

  try {
    final auth = FirebaseAuth.instance;
    final userCredential = await auth.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    final uid = userCredential.user!.uid;

    // Save profile + macros
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

    // Send verification email
    await userCredential.user!.sendEmailVerification();

    if (mounted) {
      // ✅ Instead of going to Home, go to VerifyEmailPage
      Navigator.pushReplacementNamed(context, AppRouter.verifyEmail);
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Registration failed: $e")),
    );
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Layout preserved; only added the extra inputs + preview card
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),
              Text('Create Account', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 8),
              Text('Start your fitness journey today', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 30),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Names row (unchanged)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(labelText: 'First Name'),
                            validator: (value) => value == null || value.isEmpty ? 'Please enter your first name' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(labelText: 'Last Name'),
                            validator: (value) => value == null || value.isEmpty ? 'Please enter your last name' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Email (unchanged)
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter your email';
                        if (!value.contains('@')) return 'Please enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // DOB (unchanged, used to compute age)
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _selectedDate != null
                              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                              : 'Select your date of birth',
                          style: TextStyle(color: _selectedDate != null ? Colors.black : Colors.grey[600]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Fitness Goal (unchanged, but sync to nutrition goal)
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Fitness Goal',
                        prefixIcon: Icon(Icons.fitness_center),
                      ),
                      value: _selectedFitnessGoal,
                      items: fitnessGoals.map((String goal) {
                        return DropdownMenuItem<String>(
                          value: goal,
                          child: Text(goal),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedFitnessGoal = newValue;
                          _syncFitnessToNutrition(newValue);
                        });
                      },
                      validator: (value) => value == null || value.isEmpty ? 'Please select your fitness goal' : null,
                    ),
                    const SizedBox(height: 20),

                    // NEW: Weight (kg)
                    TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(labelText: 'Weight (kg)', prefixIcon: Icon(Icons.monitor_weight)),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.isEmpty) ? 'Enter your weight' : null,
                    ),
                    const SizedBox(height: 20),

                    // NEW: Height (cm)
                    TextFormField(
                      controller: _heightController,
                      decoration: const InputDecoration(labelText: 'Height (cm)', prefixIcon: Icon(Icons.height)),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.isEmpty) ? 'Enter your height' : null,
                    ),
                    const SizedBox(height: 20),

                    // NEW: Gender
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.person)),
                      value: _gender,
                      items: const ['male', 'female']
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (val) => setState(() => _gender = val ?? 'male'),
                    ),
                    const SizedBox(height: 20),

                    // NEW: Activity level
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Activity Level', prefixIcon: Icon(Icons.directions_run)),
                      value: _activity,
                      items: const ['sedentary', 'light', 'moderate', 'active', 'very_active']
                          .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                          .toList(),
                      onChanged: (val) => setState(() => _activity = val ?? 'moderate'),
                    ),
                    const SizedBox(height: 20),

                    // NEW: Nutrition goal (bulk/cut/maintain)
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Nutrition Goal', prefixIcon: Icon(Icons.restaurant)),
                      value: _nutritionGoal,
                      items: const ['bulk', 'cut', 'maintain']
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (val) => setState(() => _nutritionGoal = val ?? 'maintain'),
                    ),
                    const SizedBox(height: 20),

                    // Passwords (unchanged)
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter a password';
                        if (value.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ),
                      obscureText: _obscureConfirmPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please confirm your password';
                        if (value != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Calculate button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _calculateMacros,
                        child: const Text('Calculate'),
                      ),
                    ),

                    // Preview card appears after calculation
                    if (_previewMacros != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        margin: const EdgeInsets.all(4),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Recommended Macros", style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Text("Calories: ${_previewMacros!['calories']} kcal"),
                              Text("Protein: ${_previewMacros!['protein']} g"),
                              Text("Carbs: ${_previewMacros!['carbs']} g"),
                              Text("Fat: ${_previewMacros!['fat']} g"),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Create Account (saves to Firebase + goes to nutrition page)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _createAccount,
                        child: const Text('Create Account'),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account?"),
                        TextButton(
                          onPressed: () => Navigator.pushReplacementNamed(context, AppRouter.login),
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
  }
}
