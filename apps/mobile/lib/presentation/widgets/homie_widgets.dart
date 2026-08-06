import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../domain/models/homie_models.dart';

final money = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '\u20B9',
  decimalDigits: 0,
);

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isDark ? .08 : .68),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? .12 : .72),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? .18 : .07),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class GradientScaffold extends StatelessWidget {
  const GradientScaffold({
    super.key,
    required this.child,
    this.floatingActionButton,
  });

  final Widget child;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF120F0D),
                    Color(0xFF2A1710),
                    Color(0xFF12241B)
                  ]
                : const [
                    Color(0xFFFFF8F1),
                    Color(0xFFFFECE0),
                    Color(0xFFEAF7EF)
                  ],
          ),
        ),
        child: SafeArea(child: child),
      ),
    );
  }
}

class ParticipantStack extends StatelessWidget {
  const ParticipantStack({
    super.key,
    required this.participants,
    this.size = 34,
  });

  final List<Participant> participants;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: size + (participants.length - 1) * (size * .62),
      height: size,
      child: Stack(
        children: [
          for (final entry in participants.asMap().entries)
            Positioned(
              left: entry.key * size * .62,
              child: Avatar(participant: entry.value, size: size),
            ),
        ],
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.participant, this.size = 38});

  final Participant participant;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Color(participant.color),
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).scaffoldBackgroundColor,
              width: 2,
            ),
          ),
          child: Text(
            participant.avatar,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: size * .34,
            ),
          ),
        ),
        if (participant.isOnline)
          Positioned(
            right: 1,
            bottom: 1,
            child: Container(
              width: size * .24,
              height: size * .24,
              decoration: BoxDecoration(
                color: const Color(0xFF26C281),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: icon == null
          ? null
          : Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : HomieTheme.orange,
            ),
      label: Text(label, overflow: TextOverflow.ellipsis),
      labelStyle: TextStyle(
        color: selected ? Colors.white : null,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor:
          selected ? HomieTheme.orange : Theme.of(context).colorScheme.surface,
      side: BorderSide(
        color: selected
            ? HomieTheme.orange
            : Theme.of(context).dividerColor.withOpacity(.18),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.isError = false,
    this.onRetry,
    this.onDismiss,
  });

  final String message;
  final IconData icon;
  final bool isError;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        border: Border.all(color: color.withOpacity(.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (onRetry != null)
            IconButton(
              tooltip: 'Retry',
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
            ),
          if (onDismiss != null)
            IconButton(
              tooltip: 'Dismiss',
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
  }
}

class FoodImage extends StatelessWidget {
  const FoodImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final String url;
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.restaurant_rounded)),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: url.isEmpty
            ? fallback
            : Image.network(
                '$url?auto=format&fit=crop&w=500&q=70',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : fallback,
              ),
      ),
    );
  }
}

String tagLabel(DietaryTag tag) {
  return switch (tag) {
    DietaryTag.veg => 'Veg',
    DietaryTag.nonVeg => 'Non-veg',
    DietaryTag.spicy => 'Spicy',
    DietaryTag.healthy => 'Healthy',
    DietaryTag.dessert => 'Desserts',
    DietaryTag.lateNight => 'Late night',
    DietaryTag.party => 'Party',
  };
}
