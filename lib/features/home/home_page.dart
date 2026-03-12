import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/providers/hike_provider.dart';
import '../../shared/theme/app_theme.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  int _getMonthlyHikeCount(List hikes) {
    final now = DateTime.now();
    return hikes.where((hike) {
      final hikeDate = hike.date;
      return hikeDate.year == now.year && hikeDate.month == now.month;
    }).length;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hikesAsync = ref.watch(hikeListProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Earthy header with gradient
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.forestGreen,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.forestGreen,
                      AppTheme.mossGreen,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.warmWhite.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.park,
                                color: AppTheme.warmWhite,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                _getGreeting(),
                                style: const TextStyle(
                                  color: AppTheme.warmWhite,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: hikesAsync.when(
              data: (hikes) {
                if (hikes.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _buildEmptyState(context),
                  );
                }
                final recentHikes = hikes.take(3).toList();
                final monthlyCount = _getMonthlyHikeCount(hikes);

                return SliverList(
                  delegate: SliverChildListDelegate([
                    // Monthly stats card
                    _buildStatsCard(context, monthlyCount),
                    const SizedBox(height: 24),
                    _buildSectionHeader(context, 'Recent Hikes'),
                    const SizedBox(height: 12),
                    // Recent hikes cards
                    ...recentHikes.map((hike) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildHikeCard(context, hike),
                        )),
                  ]),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => SliverToBoxAdapter(
                child: Center(
                  child: Text('Error: $error'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        // Lottie animation would go here
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: AppTheme.cream,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: AppTheme.forestGreen.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.hiking,
            size: 80,
            color: AppTheme.mossGreen.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'No hikes yet',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.barkBrown,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Start your first adventure today',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.dirtBrown,
              ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.forestGreen.withOpacity(0.1),
            AppTheme.sageGreen.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.sageGreen.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.forestGreen.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.forestGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.calendar_month,
              color: AppTheme.warmWhite,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This Month',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.dirtBrown,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count ${count == 1 ? 'Hike' : 'Hikes'}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.forestGreen,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          // Leaf accent
          Transform.rotate(
            angle: 0.3,
            child: Icon(
              Icons.eco,
              size: 32,
              color: AppTheme.sageGreen.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.forestGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.barkBrown,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildHikeCard(BuildContext context, dynamic hike) {
    final formatter = DateFormat('MMM dd, yyyy');
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.barkBrown.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // Navigate to hike details
          context.go('/hike/${hike.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Photo preview or icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.sageGreen.withOpacity(0.3),
                          AppTheme.mossGreen.withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: hike.photos.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Icon(
                              Icons.landscape,
                              color: AppTheme.mossGreen,
                            ),
                          )
                        : Icon(
                            Icons.terrain_outlined,
                            color: AppTheme.mossGreen,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hike.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: AppTheme.barkBrown,
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: AppTheme.dirtBrown,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formatter.format(hike.date),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.dirtBrown,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Mood indicator
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.cream,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getMoodIcon(hike.moodAfter),
                      color: AppTheme.forestGreen,
                      size: 20,
                    ),
                  ),
                ],
              ),
              if (hike.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cream.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.format_quote,
                        size: 16,
                        color: AppTheme.dirtBrown.withOpacity(0.6),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hike.notes,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppTheme.barkBrown,
                                fontStyle: FontStyle.italic,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatChip(
                    context,
                    '${hike.distance.toStringAsFixed(1)} km',
                    Icons.straighten,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    context,
                    '${hike.duration} min',
                    Icons.schedule,
                  ),
                  if (hike.photos.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _buildStatChip(
                      context,
                      '${hike.photos.length} photos',
                      Icons.photo_library,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.sageGreen.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppTheme.forestGreen,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.forestGreen,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  IconData _getMoodIcon(String mood) {
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
}
