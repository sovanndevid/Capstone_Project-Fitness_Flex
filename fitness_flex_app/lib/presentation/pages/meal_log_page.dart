import 'package:flutter/material.dart';
import 'package:fitness_flex_app/data/models/meal.dart';
import 'package:fitness_flex_app/data/models/food_item.dart';
import 'package:fitness_flex_app/data/repositories/nutrition_repository.dart';
import 'package:fitness_flex_app/core/utils/string_extensions.dart';
import 'package:fitness_flex_app/data/models/ausnut_service.dart';

class MealLogPage extends StatefulWidget {
  final NutritionRepository nutritionRepository;
  final String mealType; // ensure this exists
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
  final TextEditingController _servingController = TextEditingController(
    text: '1',
  );
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
    _mealType = widget.mealType.toLowerCase(); // honor passed type
  }

  @override
  void dispose() {
    _servingController.dispose();
    _searchController.dispose();
    _customFoodController.dispose();
    super.dispose();
  }

  void _updateNutritionValues() {
    setState(() {});
  }

  /// 🔹 Enrich AUSNUT search results with details in background
  Future<void> _enrichAUSNUTResults(List<FoodItem> foods) async {
    for (final food in foods) {
      if (food.source == "AUSNUT" && food.calories == 0) {
        try {
          final details = await AUSNUTService.getFoodDetails(food.id);
          if (mounted) {
            setState(() {
              final index = _searchResults.indexWhere((f) => f.id == food.id);
              if (index != -1) {
                _searchResults[index] = details;
              }
            });
          }
        } catch (e) {
          print("⚠️ Failed to enrich AUSNUT food: $e");
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

    setState(() {
      _isSearching = true;
    });

    final results = await widget.nutritionRepository.searchFood(query);

    // 🔹 Client-side relevance sorting
    final lowerQuery = query.toLowerCase();
    results.sort((a, b) {
      final aName = a.name.toLowerCase();
      final bName = b.name.toLowerCase();

      // 1. Exact startsWith match first
      if (aName.startsWith(lowerQuery) && !bName.startsWith(lowerQuery)) {
        return -1;
      }
      if (!aName.startsWith(lowerQuery) && bName.startsWith(lowerQuery)) {
        return 1;
      }

      // 2. Word contains
      if (aName.contains(" $lowerQuery") && !bName.contains(" $lowerQuery")) {
        return -1;
      }
      if (!aName.contains(" $lowerQuery") && bName.contains(" $lowerQuery")) {
        return 1;
      }

      // 3. Fallback alphabetical
      return aName.compareTo(bName);
    });

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });

    // 🔹 Enrich AUSNUT results after sorting
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
      if (_showCustomFoodForm) {
        _selectedFood = null;
      }
    });
  }

  void _logMeal() async {
    if (_selectedFood == null && !_showCustomFoodForm) return;

    final servingSize = double.tryParse(_servingController.text) ?? 1;
    String mealName;
    double calories, protein, carbs, fat;

    if (_showCustomFoodForm) {
      mealName = _customFoodController.text.isNotEmpty
          ? _customFoodController.text
          : 'Custom Meal';
      calories = 200 * servingSize;
      protein = 15 * servingSize;
      carbs = 25 * servingSize;
      fat = 8 * servingSize;
    } else {
      final servingFactor = servingSize / _selectedFood!.servingSize;
      mealName = _selectedFood!.name;
      calories = _selectedFood!.calories * servingFactor;
      protein = _selectedFood!.protein * servingFactor;
      carbs = _selectedFood!.carbs * servingFactor;
      fat = _selectedFood!.fat * servingFactor;
    }

    final meal = Meal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: mealName,
      description: _showCustomFoodForm
          ? 'Custom food'
          : '${_selectedFood!.brand} (${_selectedFood!.source})',
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedMealType.capitalize()} logged'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            try {
              await widget.nutritionRepository.deleteMeal(meal.id);
              widget.onMealAdded?.call();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Meal removed')));
            } catch (_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to remove meal')),
              );
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
    // build Meal object with mealType: _mealType
    // await widget.nutritionRepository.addMeal(meal);
    widget.onMealAdded?.call();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Log ${_selectedMealType.capitalize()}'),
        actions: [
          if (_selectedFood != null || _showCustomFoodForm)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _selectedFood = null;
                  _showCustomFoodForm = false;
                  _servingController.text = '1';
                  _customFoodController.clear();
                });
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedMealType,
                decoration: const InputDecoration(
                  labelText: 'Meal Type',
                  border: OutlineInputBorder(),
                ),
                items: ['breakfast', 'lunch', 'dinner', 'snack']
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.capitalize()),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedMealType = value);
                  }
                },
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
                      color: _showCustomFoodForm
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    onPressed: _toggleCustomFoodForm,
                    tooltip: _showCustomFoodForm
                        ? 'Search food'
                        : 'Add custom food',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_showCustomFoodForm) _buildCustomFoodForm(),

              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: _selectedFood == null && !_showCustomFoodForm
                    ? _buildSearchResults()
                    : _selectedFood != null
                    ? _buildFoodDetails()
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

  Widget _buildCustomFoodForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Custom Food',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _customFoodController,
          decoration: const InputDecoration(
            labelText: 'Food Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _servingController,
          decoration: const InputDecoration(
            labelText: 'Serving Size',
            border: OutlineInputBorder(),
            suffixText: 'g',
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        const Text(
          'Estimated Nutrition (per serving):',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNutritionFact('200', 'kcal', Colors.orange),
            _buildNutritionFact('15', 'g protein', Colors.blue),
            _buildNutritionFact('25', 'g carbs', Colors.green),
            _buildNutritionFact('8', 'g fat', Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fastfood, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No results found'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _toggleCustomFoodForm,
              child: const Text('Add as custom food'),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Search for food to log'),
            const Text(
              'Example: chicken, rice, banana',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _toggleCustomFoodForm,
              child: const Text('Or add custom food'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final food = _searchResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.restaurant),
            title: Text(food.name),
            subtitle: Text(
              "${food.calories} kcal per ${food.servingSize}${food.servingUnit}\nSource: ${food.source}",
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

  Widget _buildFoodDetails() {
    final servingSize = double.tryParse(_servingController.text) ?? 1;
    final servingFactor = servingSize / _selectedFood!.servingSize;

    final calories = _selectedFood!.calories * servingFactor;
    final protein = _selectedFood!.protein * servingFactor;
    final carbs = _selectedFood!.carbs * servingFactor;
    final fat = _selectedFood!.fat * servingFactor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedFood!.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        if (_selectedFood!.brand.isNotEmpty)
          Text(_selectedFood!.brand, style: TextStyle(color: Colors.grey[600])),
        if (_selectedFood!.source.isNotEmpty)
          Text(
            'Source: ${_selectedFood!.source}',
            style: const TextStyle(color: Colors.grey),
          ),
        const SizedBox(height: 20),
        TextField(
          controller: _servingController,
          decoration: InputDecoration(
            labelText: 'Serving Size (${_selectedFood!.servingUnit})',
            suffixText: _selectedFood!.servingUnit,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        const Text(
          'Nutrition Facts:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNutritionFact(
              calories.toStringAsFixed(0),
              'kcal',
              Colors.orange,
            ),
            _buildNutritionFact(
              protein.toStringAsFixed(1),
              'g protein',
              Colors.blue,
            ),
            _buildNutritionFact(
              carbs.toStringAsFixed(1),
              'g carbs',
              Colors.green,
            ),
            _buildNutritionFact(fat.toStringAsFixed(1), 'g fat', Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _buildNutritionFact(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
