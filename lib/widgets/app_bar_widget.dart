import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Reusable AppBar with optional back button and actions
class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final Widget? leading;
  final Color? backgroundColor;

  const AppBarWidget({
    super.key,
    required this.title,
    this.actions,
    this.showBack = false,
    this.leading,
    this.backgroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ?? (isDark ? AppTheme.bgPage : Colors.white);
    final fg = isDark ? AppTheme.textPrimary : const Color(0xFF111111);

    return AppBar(
      backgroundColor: bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: showBack,
      leading: leading ??
          (showBack
              ? IconButton(
                  icon: Icon(Icons.arrow_back_ios_rounded, size: 20, color: fg),
                  onPressed: () => Navigator.pop(context),
                )
              : null),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
      actions: actions,
    );
  }
}
