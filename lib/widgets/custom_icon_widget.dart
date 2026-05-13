import 'package:flutter/material.dart';

class CustomIconWidget extends StatelessWidget {
  final String iconName;
  final double size;
  final Color? color;

  const CustomIconWidget({
    super.key,
    required this.iconName,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, IconData> iconMap = {
      'home': Icons.home,
      'home_outlined': Icons.home_outlined,
      'search': Icons.search,
      'search_outlined': Icons.search_outlined,
      'person': Icons.person,
      'person_outline': Icons.person_outline,
      'camera_alt': Icons.camera_alt,
      'camera_alt_outlined': Icons.camera_alt_outlined,
      'restaurant_menu': Icons.restaurant_menu,
      'restaurant_menu_outlined': Icons.restaurant_menu_outlined,
      'arrow_back_ios_rounded': Icons.arrow_back_ios_rounded,
      'edit': Icons.edit,
      'settings': Icons.settings,
      'favorite': Icons.favorite,
      'check': Icons.check,
      'close': Icons.close,
      'add': Icons.add,
      'remove': Icons.remove,
      'help_outline': Icons.help_outline,
    };

    return Icon(
      iconMap[iconName] ?? Icons.help_outline,
      size: size,
      color: color ?? Colors.grey,
      semanticLabel: iconName,
    );
  }
}
