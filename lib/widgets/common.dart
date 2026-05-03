import 'package:flutter/material.dart';

import '../theme.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bgTop, AppColors.bgBottom],
        ),
      ),
      child: child,
    );
  }
}

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final VoidCallback? onTap;

  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: card,
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color color;
  final Color? foregroundColor;
  final bool fullWidth;
  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color = AppColors.petal,
    this.foregroundColor,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ??
        (ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : AppColors.ink);
    final btn = FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: fg,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
          Text(label),
        ],
      ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class ScreenScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget> actions;
  final bool showBack;
  final Widget? bottomBar;
  const ScreenScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions = const [],
    this.showBack = true,
    this.bottomBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: title == null
            ? null
            : Text(title!, style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: showBack && Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: actions,
      ),
      body: GradientBackground(
        child: SafeArea(child: body),
      ),
      bottomNavigationBar: bottomBar,
    );
  }
}
