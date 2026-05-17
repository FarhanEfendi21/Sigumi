import 'package:flutter/material.dart';
import 'package:sigumi/config/theme_extensions.dart';

class ShadcnMapButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const ShadcnMapButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip = '',
  });

  @override
  State<ShadcnMapButton> createState() => _ShadcnMapButtonState();
}

class _ShadcnMapButtonState extends State<ShadcnMapButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: Tooltip(
        message: widget.tooltip,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.bgPrimary.withAlpha(240),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.borderColor,
                width: context.borderWidth,
              ),
              boxShadow: context.cardShadow,
            ),
            child: Icon(
              widget.icon,
              size: 22,
              color: context.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class MapControls extends StatelessWidget {
  final VoidCallback onLocateMerapi;
  final VoidCallback onLocateUser;

  const MapControls({
    super.key,
    required this.onLocateMerapi,
    required this.onLocateUser,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShadcnMapButton(
          icon: Icons.landscape_rounded,
          tooltip: 'Ke Merapi',
          onTap: onLocateMerapi,
        ),
        const SizedBox(height: 12),
        ShadcnMapButton(
          icon: Icons.my_location_rounded,
          tooltip: 'Lokasi Saya',
          onTap: onLocateUser,
        ),
      ],
    );
  }
}
