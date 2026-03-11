import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_theme.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? lottieAsset;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.lottieAsset,
    this.icon,
    this.onAction,
    this.actionLabel,
  });

  factory EmptyStateWidget.noHikes({VoidCallback? onAction}) {
    return EmptyStateWidget(
      title: 'No hikes yet',
      subtitle: 'Start your first adventure today',
      icon: Icons.hiking,
      onAction: onAction,
      actionLabel: 'Log First Hike',
    );
  }

  factory EmptyStateWidget.noPhotos() {
    return const EmptyStateWidget(
      title: 'No photos',
      subtitle: 'Add some memories to your hike',
      icon: Icons.photo_library_outlined,
    );
  }

  factory EmptyStateWidget.noNotes() {
    return const EmptyStateWidget(
      title: 'No notes',
      subtitle: 'Write about your experience',
      icon: Icons.edit_note_outlined,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (lottieAsset != null)
            Lottie.asset(
              lottieAsset!,
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            )
          else
            _buildIconContainer(),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.barkBrown,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.dirtBrown,
                ),
            textAlign: TextAlign.center,
          ),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 24),
            _buildActionButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildIconContainer() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.cream,
            AppTheme.sageGreen.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(80),
        boxShadow: [
          BoxShadow(
            color: AppTheme.forestGreen.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative leaf icon
          Positioned(
            top: 10,
            right: 20,
            child: Transform.rotate(
              angle: 0.5,
              child: Icon(
                Icons.eco,
                size: 32,
                color: AppTheme.sageGreen.withOpacity(0.4),
              ),
            ),
          ),
          Positioned(
            bottom: 15,
            left: 15,
            child: Transform.rotate(
              angle: -0.3,
              child: Icon(
                Icons.eco,
                size: 24,
                color: AppTheme.sageGreen.withOpacity(0.3),
              ),
            ),
          ),
          // Main icon
          Center(
            child: Icon(
              icon ?? Icons.park_outlined,
              size: 64,
              color: AppTheme.mossGreen.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return ElevatedButton.icon(
      onPressed: onAction,
      icon: const Icon(Icons.add),
      label: Text(actionLabel!),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.forestGreen,
        foregroundColor: AppTheme.warmWhite,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

/// Card widget with earthy styling
class EarthyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? elevation;

  const EarthyCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.onLongPress,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveElevation = elevation ?? 2.0;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.barkBrown.withOpacity(0.06),
            blurRadius: 12 * effectiveElevation / 2,
            offset: Offset(0, effectiveElevation),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Stats chip with earthy styling
class StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;

  const StatChip({
    super.key,
    required this.label,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.forestGreen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: effectiveColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: effectiveColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: effectiveColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Section header with leaf accent
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Accent bar
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.forestGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.barkBrown,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        // Leaf accent
        Transform.rotate(
          angle: 0.2,
          child: Icon(
            Icons.eco,
            size: 24,
            color: AppTheme.sageGreen.withOpacity(0.5),
          ),
        ),
        if (onSeeAll != null) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              'See all',
              style: TextStyle(
                color: AppTheme.forestGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Mood indicator widget
class MoodIndicator extends StatelessWidget {
  final String mood;

  const MoodIndicator({super.key, required this.mood});

  IconData get _moodIcon {
    switch (mood.toLowerCase()) {
      case 'energetic':
        return Icons.bolt;
      case 'calm':
        return Icons.spa;
      case 'tired':
        return Icons.battery_alert;
      case 'excited':
        return Icons.celebration;
      case 'peaceful':
        return Icons.self_improvement;
      case 'relaxed':
        return Icons.beach_access;
      case 'challenged':
        return Icons.trending_up;
      case 'refreshed':
        return Icons.refresh;
      default:
        return Icons.sentiment_satisfied;
    }
  }

  Color get _moodColor {
    switch (mood.toLowerCase()) {
      case 'energetic':
      case 'excited':
        return AppTheme.amberAccent;
      case 'calm':
      case 'peaceful':
      case 'relaxed':
        return AppTheme.sageGreen;
      case 'tired':
        return AppTheme.dirtBrown;
      case 'challenged':
        return AppTheme.forestGreen;
      case 'refreshed':
        return Colors.lightBlue;
      default:
        return AppTheme.forestGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _moodColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _moodColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Icon(
        _moodIcon,
        color: _moodColor,
        size: 22,
      ),
    );
  }
}
