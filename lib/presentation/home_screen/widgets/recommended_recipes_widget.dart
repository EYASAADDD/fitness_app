import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_image_widget.dart';

class RecommendedRecipesWidget extends StatelessWidget {
  final List<String> userDiseases;
  final bool isTablet;

  const RecommendedRecipesWidget({
    super.key,
    required this.userDiseases,
    this.isTablet = false,
  });

  static final List<Map<String, dynamic>> _allRecipes = [
    {
      'id': 'r001',
      'name': 'Healthy Salad',
      'calories': 220,
      'prepTime': 15,
      'tags': ['Healthy', 'Low-Carb', 'Vegan'],
      'suitableFor': ['diabetes', 'hypertension', 'obesity'],
      'avoidFor': <String>[],
      'imageUrl':
          'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=400',
      'semanticLabel':
          'Fresh green salad with cherry tomatoes and cucumber in a white bowl',
    },
    {
      'id': 'r002',
      'name': 'Grilled Chicken Bowl',
      'calories': 320,
      'prepTime': 25,
      'tags': ['High-Protein', 'Low-Carb'],
      'suitableFor': ['diabetes', 'obesity'],
      'avoidFor': <String>[],
      'imageUrl':
          'https://images.pixabay.com/photo/2017/12/09/08/18/pizza-3007395_1280.jpg',
      'semanticLabel':
          'Grilled chicken breast with quinoa and steamed broccoli in a bowl',
    },
    {
      'id': 'r003',
      'name': 'Oatmeal with Berries',
      'calories': 280,
      'prepTime': 10,
      'tags': ['Heart-Friendly', 'High-Fiber'],
      'suitableFor': ['hypertension', 'cholesterol', 'heart'],
      'avoidFor': ['diabetes'],
      'imageUrl':
          'https://images.unsplash.com/photo-1666395998775-ec924523e802',
      'semanticLabel':
          'Warm oatmeal topped with blueberries and strawberries in a gray bowl',
    },
    {
      'id': 'r004',
      'name': 'Salmon with Vegetables',
      'calories': 380,
      'prepTime': 30,
      'tags': ['Omega-3', 'Heart-Friendly'],
      'suitableFor': ['heart', 'hypertension', 'anemia'],
      'avoidFor': <String>[],
      'imageUrl':
          'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=400&auto=format',
      'semanticLabel':
          'Baked salmon fillet with roasted zucchini and cherry tomatoes',
    },
    {
      'id': 'r005',
      'name': 'Lentil Soup',
      'calories': 190,
      'prepTime': 35,
      'tags': ['Vegan', 'High-Fiber', 'Diabetic-Friendly'],
      'suitableFor': ['diabetes', 'anemia', 'hypertension', 'obesity'],
      'avoidFor': <String>[],
      'imageUrl':
          'https://images.pexels.com/photos/539451/pexels-photo-539451.jpeg?auto=compress&cs=tinysrgb&w=400',
      'semanticLabel':
          'Red lentil soup with cumin and fresh herbs in a ceramic bowl',
    },
  ];

  List<Map<String, dynamic>> get _filteredRecipes {
    final lowerDiseases = userDiseases.map((d) => d.toLowerCase()).toList();
    return _allRecipes.where((r) {
      final avoidFor = List<String>.from(r['avoidFor'] as List);
      for (final disease in lowerDiseases) {
        if (avoidFor.contains(disease)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final recipes = _filteredRecipes;

    if (recipes.isEmpty) {
      return Container(
        height: 160,
        decoration: AppTheme.cardDecoration,
        child: const Center(
          child: Text('No recipes available for your conditions'),
        ),
      );
    }

    if (isTablet) {
      return Column(
        children: recipes
            .map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RecipeListCard(recipe: r),
              ),
            )
            .toList(),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: recipes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _RecipeCard(recipe: recipes[i]),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Map<String, dynamic> recipe;

  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final tags = List<String>.from(recipe['tags'] as List);
    return Container(
      width: 160,
      decoration: AppTheme.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: CustomImageWidget(
              imageUrl: recipe['imageUrl'] as String,
              width: 160,
              height: 100,
              fit: BoxFit.cover,
              semanticLabel: recipe['semanticLabel'] as String,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe['name'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${recipe['calories']} kcal • ${recipe['prepTime']} min',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  children: tags
                      .take(2)
                      .map(
                        (t) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.tagBlue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            t,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.tagBlueDark,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeListCard extends StatelessWidget {
  final Map<String, dynamic> recipe;

  const _RecipeListCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final tags = List<String>.from(recipe['tags'] as List);
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CustomImageWidget(
              imageUrl: recipe['imageUrl'] as String,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              semanticLabel: recipe['semanticLabel'] as String,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe['name'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${recipe['calories']} kcal • ${recipe['prepTime']} min',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  children: tags
                      .take(3)
                      .map(
                        (t) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.tagBlue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            t,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.tagBlueDark,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.favorite_border_rounded,
              color: AppTheme.textHint,
              size: 20,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
