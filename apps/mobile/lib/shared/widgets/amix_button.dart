import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AmixButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;
  final double? width;

  const AmixButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = isLoading
        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
              Text(label),
            ],
          );

    final style = isOutlined
        ? OutlinedButton.styleFrom(
            foregroundColor: foregroundColor ?? AppColors.primary,
            side: BorderSide(color: foregroundColor ?? AppColors.primary),
            minimumSize: Size(width ?? double.infinity, 52),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.primary,
            foregroundColor: foregroundColor ?? Colors.white,
            minimumSize: Size(width ?? double.infinity, 52),
          );

    return isOutlined
        ? OutlinedButton(onPressed: isLoading ? null : onPressed, style: style, child: child)
        : ElevatedButton(onPressed: isLoading ? null : onPressed, style: style, child: child);
  }
}
