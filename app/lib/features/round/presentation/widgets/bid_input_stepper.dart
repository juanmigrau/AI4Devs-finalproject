import 'package:flutter/material.dart';
import 'package:la_pocha/core/theme/app_theme.dart';

class BidInputStepper extends StatelessWidget {
  const BidInputStepper({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onConfirm,
    required this.canConfirm,
    this.isSubmitting = false,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final VoidCallback onConfirm;
  final bool canConfirm;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
          color: AppTheme.primary,
          disabledColor: AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
          color: AppTheme.primary,
          disabledColor: AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
        ),
        if (isSubmitting)
          const SizedBox(
            width: 36,
            height: 36,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          IconButton(
            onPressed: canConfirm ? onConfirm : null,
            icon: const Icon(Icons.check_circle_outline),
            color: AppTheme.primary,
            disabledColor: AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }
}
