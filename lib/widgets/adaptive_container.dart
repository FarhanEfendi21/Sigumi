import 'package:flutter/material.dart';
import '../config/theme_extensions.dart';

/// Container yang adaptive terhadap high contrast mode
class AdaptiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? customColor;
  final bool useSurface;
  final bool showBorder;
  
  const AdaptiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.customColor,
    this.useSurface = true,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: customColor ?? (useSurface ? context.bgSurface : context.bgPrimary),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: showBorder ? Border.all(
          color: context.borderColor,
          width: context.borderWidth,
        ) : null,
        boxShadow: context.cardShadow,
      ),
      child: child,
    );
  }
}

/// Card yang adaptive terhadap high contrast mode
class AdaptiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  
  const AdaptiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = AdaptiveContainer(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      child: child,
    );
    
    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: card,
        ),
      );
    }
    
    return card;
  }
}
