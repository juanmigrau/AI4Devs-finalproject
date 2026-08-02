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
    return IconButton(
      onPressed: onTap,
      tooltip: 'Designar repartidor',
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      padding: EdgeInsets.zero,
      iconSize: isSelected ? 28 : 24,
      icon: Icon(
        isSelected ? Icons.style : Icons.style_outlined,
        color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
      ),
    );
  }
}
