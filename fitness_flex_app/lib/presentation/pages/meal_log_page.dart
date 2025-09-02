import 'package:flutter/material.dart';
import 'package:fitness_flex_app/data/models/meal.dart';
import 'package:fitness_flex_app/data/models/food_item.dart';
import 'package:fitness_flex_app/data/repositories/nutrition_repository.dart';
import 'package:fitness_flex_app/core/utils/string_extensions.dart';

class MealLogPage extends StatefulWidget {
  final NutritionRepository nutritionRepository;
  final String mealType;
  final VoidCallback onMealAdded;

  const MealLogPage({
    super.key,
    required this.nutritionRepository,
    required this.mealType,
    required this.onMealAdded,
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

  @override
  void initState() {
    super.initState();
    _servingController.addListener(_updateNutritionValues);
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
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
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
      // Custom food
      mealName = _customFoodController.text.isNotEmpty
          ? _customFoodController.text
          : 'Custom Meal';
      // Default nutrition values for custom food
      calories = 200 * servingSize;
      protein = 15 * servingSize;
      carbs = 25 * servingSize;
      fat = 8 * servingSize;
    } else {
      // Database food
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
      description: _showCustomFoodForm ? 'Custom food' : _selectedFood!.brand,
      imageUrl: '🍽️',
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      date: DateTime.now(),
      mealType: widget.mealType,
      servingSize: servingSize.toInt(),
    );

    await widget.nutritionRepository.addMeal(meal);
    widget.onMealAdded();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.mealType.capitalize()} logged successfully!'),
        duration: const Duration(seconds: 2),
      ),
    );

    // Clear form but stay on the page to log another meal
    setState(() {
      _selectedFood = null;
      _showCustomFoodForm = false;
      _searchController.clear();
      _searchResults = [];
      _servingController.text = '1';
      _customFoodController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Log ${widget.mealType.capitalize()}'),
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
        child: Column(
          children: [
            // Search Bar and Custom Food Button
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
                                _searchResults = [];
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

            // Custom Food Form (when enabled)
            if (_showCustomFoodForm) _buildCustomFoodForm(),

            // Search Results or Selected Food
            Expanded(
              child: _selectedFood == null && !_showCustomFoodForm
                  ? _buildSearchResults()
                  : _selectedFood != null
                  ? _buildFoodDetails()
                  : const SizedBox(),
            ),

            // Log Button (only show when food is selected or custom form is filled)
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
              '${food.calories} kcal per ${food.servingSize}${food.servingUnit}',
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
        // Food Name
        Text(
          _selectedFood!.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        if (_selectedFood!.brand.isNotEmpty)
          Text(_selectedFood!.brand, style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 20),

        // Serving Size
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

        // Nutrition Facts
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
