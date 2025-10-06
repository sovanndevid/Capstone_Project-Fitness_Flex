import 'package:flutter/material.dart';
import 'package:fitness_flex_app/data/models/meal.dart';
import 'package:fitness_flex_app/data/models/food_item.dart';
import 'package:fitness_flex_app/data/repositories/nutrition_repository.dart';
import 'package:fitness_flex_app/core/utils/string_extensions.dart';
import 'package:fitness_flex_app/data/models/ausnut_service.dart';

class MealLogPage extends StatefulWidget {
  final NutritionRepository nutritionRepository;
  final String mealType;
  final VoidCallback? onMealAdded;

  const MealLogPage({
    super.key,
    required this.nutritionRepository,
    required this.mealType,
    this.onMealAdded,
  });

  @override
  State<MealLogPage> createState() => _MealLogPageState();
}

class _MealLogPageState extends State<MealLogPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _servingController = TextEditingController(text: '1');
  final TextEditingController _customFoodController = TextEditingController();

  List<FoodItem> _searchResults = [];
  FoodItem? _selectedFood;
  bool _isSearching = false;
  bool _showCustomFoodForm = false;

  late String _selectedMealType;
  late String _mealType;

  @override
  void initState() {
    super.initState();
    _servingController.addListener(_updateNutritionValues);
    _selectedMealType = widget.mealType;
    _mealType = widget.mealType.toLowerCase();
  }

  @override
  void dispose() {
    _servingController.dispose();
    _searchController.dispose();
    _customFoodController.dispose();
    super.dispose();
  }

  void _updateNutritionValues() => setState(() {});

  Future<void> _enrichAUSNUTResults(List<FoodItem> foods) async {
    for (final food in foods) {
      if (food.source == "AUSNUT" && food.calories == 0) {
        try {
          final details = await AUSNUTService.getFoodDetails(food.id);
          if (!mounted) return;
          final index = _searchResults.indexWhere((f) => f.id == food.id);
          if (index != -1) {
            setState(() => _searchResults[index] = details);
          }
        } catch (e) {
          debugPrint("⚠️ Failed to enrich AUSNUT food: $e");
        }
      }
    }
  }

  void _searchFood(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);

    final results = await widget.nutritionRepository.searchFood(query);

    final lowerQuery = query.toLowerCase();
    results.sort((a, b) {
      final aName = a.name.toLowerCase();
      final bName = b.name.toLowerCase();
      if (aName.startsWith(lowerQuery) && !bName.startsWith(lowerQuery)) return -1;
      if (!aName.startsWith(lowerQuery) && bName.startsWith(lowerQuery)) return 1;
      if (aName.contains(" $lowerQuery") && !bName.contains(" $lowerQuery")) return -1;
      if (!aName.contains(" $lowerQuery") && bName.contains(" $lowerQuery")) return 1;
      return aName.compareTo(bName);
    });

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });

    _enrichAUSNUTResults(results);
  }

  void _selectFood(FoodItem food) {
    setState(() {
      _selectedFood = food;
      _searchController.clear();
      _searchResults = [];
      _showCustomFoodForm = false;
    });
  }

  void _toggleCustomFoodForm() {
    setState(() {
      _showCustomFoodForm = !_showCustomFoodForm;
      if (_showCustomFoodForm) _selectedFood = null;
    });
  }

  void _logMeal() async {
    if (_selectedFood == null && !_showCustomFoodForm) return;

    final servingSize = double.tryParse(_servingController.text) ?? 1;
    String mealName;
    double calories, protein, carbs, fat;

    if (_showCustomFoodForm) {
      mealName = _customFoodController.text.isNotEmpty ? _customFoodController.text : 'Custom Meal';
      calories = 200 * servingSize;
      protein = 15 * servingSize;
      carbs = 25 * servingSize;
      fat = 8 * servingSize;
    } else {
      final factor = servingSize / _selectedFood!.servingSize;
      mealName = _selectedFood!.name;
      calories = _selectedFood!.calories * factor;
      protein = _selectedFood!.protein * factor;
      carbs = _selectedFood!.carbs * factor;
      fat = _selectedFood!.fat * factor;
    }

    final meal = Meal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: mealName,
      description: _showCustomFoodForm ? 'Custom food' : '${_selectedFood!.brand} (${_selectedFood!.source})',
      imageUrl: '🍽️',
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      date: DateTime.now(),
      mealType: _selectedMealType,
      servingSize: servingSize.toInt(),
    );

    await widget.nutritionRepository.addMeal(meal);
    widget.onMealAdded?.call();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedMealType.capitalize()} logged'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            try {
              await widget.nutritionRepository.deleteMeal(meal.id);
              widget.onMealAdded?.call();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Meal removed')),
                );
              }
            } catch (_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to remove meal')),
                );
              }
            }
          },
        ),
      ),
    );

    setState(() {
      _selectedFood = null;
      _showCustomFoodForm = false;
      _searchController.clear();
      _searchResults = [];
      _servingController.text = '1';
      _customFoodController.clear();
    });
  }

  Future<void> _saveMeal() async {
    widget.onMealAdded?.call();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Log ${_selectedMealType.capitalize()}'),
        // AppTheme already sets centerTitle, bg/fg colors.
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedMealType,
                decoration: const InputDecoration(
                  labelText: 'Meal Type',
                  // no border override → uses global InputDecorationTheme (filled, rounded)
                ),
                items: const ['breakfast', 'lunch', 'dinner', 'snack']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type.capitalize())))
                    .toList(),
                onChanged: (value) => setState(() => _selectedMealType = value ?? _selectedMealType),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search food',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchResults = []);
                                },
                              )
                            : null,
                      ),
                      onChanged: _searchFood,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      _showCustomFoodForm ? Icons.search : Icons.add,
                      color: _showCustomFoodForm ? theme.colorScheme.primary : null,
                    ),
                    onPressed: _toggleCustomFoodForm,
                    tooltip: _showCustomFoodForm ? 'Search food' : 'Add custom food',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_showCustomFoodForm) _buildCustomFoodForm(theme),

              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: _selectedFood == null && !_showCustomFoodForm
                    ? _buildSearchResults(theme)
                    : _selectedFood != null
                        ? _buildFoodDetails(theme)
                        : const SizedBox(),
              ),

              if (_selectedFood != null || _showCustomFoodForm) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _logMeal,
                    child: const Text('Log Meal'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomFoodForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Custom Food',
          style: theme.textTheme.displayMedium?.copyWith(
            fontSize: 18,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _customFoodController,
          decoration: const InputDecoration(
            labelText: 'Food Name',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _servingController,
          decoration: const InputDecoration(
            labelText: 'Serving Size',
            suffixText: 'g',
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        Text(
          'Estimated Nutrition (per serving):',
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNutritionFact(theme, '200', 'kcal', theme.colorScheme.secondary),
            _buildNutritionFact(theme, '15', 'g protein', theme.colorScheme.primary),
            _buildNutritionFact(theme, '25', 'g carbs', theme.colorScheme.tertiaryContainer.withOpacity(.90)),
            _buildNutritionFact(theme, '8', 'g fat', theme.colorScheme.error),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchResults(ThemeData theme) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return _EmptyState(
        icon: Icons.fastfood,
        title: 'No results found',
        actionLabel: 'Add as custom food',
        onAction: _toggleCustomFoodForm,
      );
    }

    if (_searchResults.isEmpty) {
      return _EmptyState(
        icon: Icons.search,
        title: 'Search for food to log',
        subtitle: 'Example: chicken, rice, banana',
        actionOutlinedLabel: 'Or add custom food',
        onAction: _toggleCustomFoodForm,
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final food = _searchResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(Icons.restaurant, color: theme.colorScheme.primary),
            title: Text(food.name, style: theme.textTheme.bodyLarge),
            subtitle: Text(
              "${food.calories} kcal per ${food.servingSize}${food.servingUnit}\nSource: ${food.source}",
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(.6)),
            ),
            trailing: Text(
              '${food.protein}P ${food.carbs}C ${food.fat}F',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () => _selectFood(food),
          ),
        );
      },
    );
  }

  Widget _buildFoodDetails(ThemeData theme) {
    final servingSize = double.tryParse(_servingController.text) ?? 1;
    final factor = servingSize / _selectedFood!.servingSize;

    final calories = _selectedFood!.calories * factor;
    final protein = _selectedFood!.protein * factor;
    final carbs = _selectedFood!.carbs * factor;
    final fat = _selectedFood!.fat * factor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_selectedFood!.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        if (_selectedFood!.brand.isNotEmpty)
          Text(_selectedFood!.brand, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(.6))),
        if (_selectedFood!.source.isNotEmpty)
          Text('Source: ${_selectedFood!.source}',
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(.6))),
        const SizedBox(height: 20),
        TextField(
          controller: _servingController,
          decoration: InputDecoration(
            labelText: 'Serving Size (${_selectedFood!.servingUnit})',
            suffixText: _selectedFood!.servingUnit,
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        Text('Nutrition Facts:', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNutritionFact(theme, calories.toStringAsFixed(0), 'kcal', theme.colorScheme.secondary),
            _buildNutritionFact(theme, protein.toStringAsFixed(1), 'g protein', theme.colorScheme.primary),
            _buildNutritionFact(
              theme,
              carbs.toStringAsFixed(1),
              'g carbs',
              theme.colorScheme.tertiaryContainer.withOpacity(.90),
            ),
            _buildNutritionFact(theme, fat.toStringAsFixed(1), 'g fat', theme.colorScheme.error),
          ],
        ),
      ],
    );
  }

  Widget _buildNutritionFact(ThemeData theme, String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(.6))),
      ],
    );
  }
}

/* ---------- Small empty-state helper aligned with theme ---------- */
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final String? actionOutlinedLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.actionOutlinedLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: theme.colorScheme.onSurface.withOpacity(.35)),
          const SizedBox(height: 16),
          Text(title, style: theme.textTheme.bodyLarge),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(.6))),
            ),
          const SizedBox(height: 16),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!))
          else if (actionOutlinedLabel != null)
            OutlinedButton(onPressed: onAction, child: Text(actionOutlinedLabel!)),
        ],
      ),
    );
  }
}
