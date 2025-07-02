// File: waiter_app/lib/Components/custom_button.dart
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String titleText;
  final VoidCallback? onTap;
  final IconData? leadingIcon;
  final double? iconSize;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isOutlined;
  final MainAxisSize mainAxisSize;
  final EdgeInsetsGeometry? padding;
  final double? borderRadiusValue;
  final TextStyle? textStyle;

  const CustomButton({
    super.key,
    required this.titleText,
    this.onTap,
    this.leadingIcon,
    this.iconSize,
    this.backgroundColor,
    this.foregroundColor,
    this.isOutlined = false,
    this.mainAxisSize = MainAxisSize.min,
    this.padding,
    this.borderRadiusValue,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color effectiveBackgroundColor = backgroundColor ?? (isOutlined ? Colors.transparent : theme.elevatedButtonTheme.style?.backgroundColor?.resolve({}) ?? theme.primaryColor);
    final Color effectiveForegroundColor = foregroundColor ?? (isOutlined ? theme.primaryColor : theme.elevatedButtonTheme.style?.foregroundColor?.resolve({}) ?? theme.colorScheme.onPrimary);
    final BorderSide? borderSide = isOutlined ? BorderSide(color: foregroundColor ?? theme.primaryColor, width: 1.5) : null;
    
    final TextStyle defaultButtonTextStyle = theme.elevatedButtonTheme.style?.textStyle?.resolve({}) ?? theme.textTheme.labelLarge ?? const TextStyle();
    final TextStyle effectiveTextStyle = defaultButtonTextStyle.merge(textStyle);

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: effectiveBackgroundColor,
        foregroundColor: effectiveForegroundColor,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: effectiveTextStyle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusValue ?? 8),
          side: borderSide ?? BorderSide.none,
        ),
        minimumSize: mainAxisSize == MainAxisSize.max ? const Size(double.infinity, 48) : null,
      ),
      onPressed: onTap,
      child: Row(
        mainAxisSize: mainAxisSize,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: iconSize ?? 18, color: effectiveTextStyle.color),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              titleText,
              overflow: TextOverflow.ellipsis,
              style: effectiveTextStyle,
            ),
          ),
        ],
      ),
    );
  }
}