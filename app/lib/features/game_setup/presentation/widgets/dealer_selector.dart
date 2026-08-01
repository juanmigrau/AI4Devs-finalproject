import 'package:flutter/material.dart';
import 'package:la_pocha/core/theme/app_theme.dart';

class DealerSelector extends StatelessWidget {
  const DealerSelector({
    super.key,
    required this.isSelected,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Tooltip(
        message: 'Designar repartidor',
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            Icons.style,
            size: 28,
            color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
