import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

class HealthConditionsGridWidget extends StatelessWidget {
  final Set<String> selectedDiseases;
  final ValueChanged<String> onToggle;

  const HealthConditionsGridWidget({
    super.key,
    required this.selectedDiseases,
    required this.onToggle,
  });

  static const List<Map<String, dynamic>> _conditions = [
    {
      'id': 'diabetes',
      'label': 'Diabetes',
      'icon': Icons.bloodtype_outlined,
      'emoji': '🩸',
    },
    {
      'id': 'hypertension',
      'label': 'Hypertension',
      'icon': Icons.trending_up_rounded,
      'emoji': '📈',
    },
    {
      'id': 'hypotension',
      'label': 'Hypotension',
      'icon': Icons.trending_down_rounded,
      'emoji': '📉',
    },
    {
      'id': 'cholesterol',
      'label': 'Cholesterol',
      'icon': Icons.favorite_border_rounded,
      'emoji': '🫀',
    },
    {
      'id': 'anemia',
      'label': 'Anemia',
      'icon': Icons.water_drop_outlined,
      'emoji': '💉',
    },
    {
      'id': 'obesity',
      'label': 'Obesity',
      'icon': Icons.scale_outlined,
      'emoji': '⚖️',
    },
    {
      'id': 'heart',
      'label': 'Heart Problems',
      'icon': Icons.monitor_heart_outlined,
      'emoji': '❤️',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Health Conditions',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Select all that apply to personalize your food recommendations',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3.2,
            ),
            itemCount: _conditions.length,
            itemBuilder: (context, i) {
              final condition = _conditions[i];
              final id = condition['id'] as String;
              final isSelected = selectedDiseases.contains(id);
              return _ConditionCard(
                label: condition['label'] as String,
                icon: condition['icon'] as IconData,
                emoji: condition['emoji'] as String,
                isSelected: isSelected,
                onTap: () => onToggle(id),
              );
            },
          ),
          if (selectedDiseases.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${selectedDiseases.length} condition${selectedDiseases.length > 1 ? 's' : ''} selected — recipes and food scores will be personalized.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.primaryBlueDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConditionCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _ConditionCard({
    required this.label,
    required this.icon,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ConditionCard> createState() => _ConditionCardState();
}

class _ConditionCardState extends State<_ConditionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.95,
      upperBound: 1.0,
    )..value = 1.0;
    _scaleAnimation = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => _controller.reverse(),
      onTapUp: (details) {
        _controller.forward();
        widget.onTap();
      },
      onTapCancel: () => _controller.forward(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppTheme.primaryBlue.withAlpha(20)
                : AppTheme.bgPage,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? AppTheme.primaryBlue
                  : AppTheme.borderLight,
              width: widget.isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: widget.isSelected
                        ? AppTheme.primaryBlueDark
                        : AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: widget.isSelected
                    ? Container(
                        key: const ValueKey('checked'),
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 11,
                        ),
                      )
                    : Container(
                        key: const ValueKey('unchecked'),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.borderLight,
                            width: 1.5,
                          ),
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
