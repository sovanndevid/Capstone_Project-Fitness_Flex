import 'package:flutter/material.dart';

class WorkoutCard extends StatelessWidget {
  final String title;
  final String category;
  final String description;
  final String duration;
  final String calories;
  final String difficulty;
  final VoidCallback onTap;
  final bool isLiked;
  final VoidCallback onLike;

  const WorkoutCard({
    super.key,
    required this.title,
    required this.category,
    required this.description,
    required this.duration,
    required this.calories,
    required this.difficulty,
    required this.onTap,
    required this.isLiked,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.blue.withOpacity(0.2),
        highlightColor: Colors.blue.withOpacity(0.1),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : null,
                    ),
                    onPressed: () {
                      print('IconButton pressed in WorkoutCard');
                      onLike();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(duration, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  const SizedBox(width: 16),
                  Icon(Icons.local_fire_department, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('$calories cal', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  const SizedBox(width: 16),
                  Icon(Icons.whatshot, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(difficulty, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  final List<bool> _isLikedList = [false, false];

  void _toggleLike(int index) {
    setState(() {
      _isLikedList[index] = !_isLikedList[index];
      print('Workout $index liked: ${_isLikedList[index]}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workouts'),
        centerTitle: false,
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Categories Section
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Categories',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryChip('Strength'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Cardio'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Yoga & Flexibility'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Popular Workouts Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Popular Workouts',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            WorkoutCard(
              title: "Full Body Strength",
              category: "Strength Training",
              description:
                  "Complete full body workout targeting all major muscle groups with compound exercises",
              duration: "45 min",
              calories: "320",
              difficulty: "Intermediate",
              isLiked: _isLikedList[0],
              onLike: () => _toggleLike(0),
              onTap: () {},
            ),
            WorkoutCard(
              title: "Morning Yoga Flow",
              category: "Yoga & Flexibility",
              description:
                  "Gentle yoga routine to start your day with stretching and breathing",
              duration: "30 min",
              calories: "180",
              difficulty: "Beginner",
              isLiked: _isLikedList[1],
              onLike: () => _toggleLike(1),
              onTap: () {},
            ),
            const SizedBox(height: 16),

            // All Workouts Button
            Center(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('All Workouts'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    return Chip(label: Text(label), backgroundColor: Colors.grey[200]);
  }
}
