import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_provider.dart';
import '../theme/app_theme.dart';

class CustomizationMiniCard extends StatelessWidget {
  final String title;
  final Color primaryColor;
  final Color secondaryColor;
  final VoidCallback? onTap;
  final bool isSelected;

  const CustomizationMiniCard({
    super.key,
    required this.title,
    required this.primaryColor,
    required this.secondaryColor,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Container(
            width: 51,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [primaryColor, secondaryColor],
              ),
              border:
                  isSelected ? Border.all(color: Colors.white, width: 3) : null,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomizationScrollableCards extends StatelessWidget {
  const CustomizationScrollableCards({super.key});

  static final List<Map<String, dynamic>> themes = [
    {
      'title': 'Ocean',
      'primary': const Color(0xFF2196F3),
      'secondary': const Color(0xFF1976D2),
    },
    {
      'title': 'Forest',
      'primary': const Color(0xFF4CAF50),
      'secondary': const Color(0xFF388E3C),
    },
    {
      'title': 'Sunset',
      'primary': const Color(0xFFFF9800),
      'secondary': const Color(0xFFE65100),
    },
    {
      'title': 'Rose',
      'primary': const Color(0xFFE91E63),
      'secondary': const Color(0xFFC2185B),
    },
    {
      'title': 'Purple',
      'primary': const Color(0xFF9C27B0),
      'secondary': const Color(0xFF7B1FA2),
    },
    {
      'title': 'Teal',
      'primary': const Color(0xFF009688),
      'secondary': const Color(0xFF00695C),
    },
    {
      'title': 'Indigo',
      'primary': const Color(0xFF3F51B5),
      'secondary': const Color(0xFF303F9F),
    },
    {
      'title': 'Default',
      'primary': AppColors.gray600,
      'secondary': AppColors.gray800,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Expanded(
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: themes.length,
          itemBuilder: (context, index) {
            final theme = themes[index];
            return CustomizationMiniCard(
              title: theme['title'],
              primaryColor: theme['primary'],
              secondaryColor: theme['secondary'],
              isSelected: index == 0, // Default selection for now
              onTap: () {
                // Handle theme selection
                Provider.of<GameProvider>(context, listen: false)
                    .exitCustomizationMode();

                // Here you can add logic to apply the selected theme
                debugPrint('Selected theme: ${theme['title']}');
              },
            );
          },
        ),
      ),
    );
  }
}
