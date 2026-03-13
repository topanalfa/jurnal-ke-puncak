import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/hike_provider.dart';
import '../../shared/theme/app_theme.dart';

// View mode enum
enum JournalViewMode {
  calendar,
  list,
}

// Provider for view mode
final journalViewModeProvider = StateProvider<JournalViewMode>((ref) {
  return JournalViewMode.calendar;
});

// Provider for search query
final journalSearchQueryProvider = StateProvider<String>((ref) => '');

// Provider for selected date (calendar mode)
final journalSelectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

class JournalPage extends ConsumerStatefulWidget {
  const JournalPage({super.key});

  @override
  ConsumerState<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends ConsumerState<JournalPage> {
  late CalendarFormat _calendarFormat;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.month;
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewMode = ref.watch(journalViewModeProvider);
    final searchQuery = ref.watch(journalSearchQueryProvider);
    final selectedDate = ref.watch(journalSelectedDateProvider);
    final hikesAsync = ref.watch(hikeListProvider);

    // Filter hikes based on search query and selected date (in calendar mode)
    final filteredHikes = hikesAsync.whenData((hikes) {
      final filtered = hikes.where((hike) {
        // Search filter
        if (searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          final titleMatch = hike.title.toLowerCase().contains(query);
          final notesMatch = hike.notes.toLowerCase().contains(query);
          if (!titleMatch && !notesMatch) return false;
        }

        // Calendar mode: filter by selected date
        if (viewMode == JournalViewMode.calendar) {
          return _isSameDay(hike.date, selectedDate);
        }

        return true;
      }).toList();

      // Sort by date descending (newest first)
      filtered.sort((a, b) => b.date.compareTo(a.date));
      return filtered;
    });

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header with greeting
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.sageGreen,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.sageGreen,
                      AppTheme.mossGreen.withOpacity(0.7),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.warmWhite.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.book,
                                color: AppTheme.warmWhite,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Trail Journal',
                                    style: TextStyle(
                                      color: AppTheme.warmWhite,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  Text(
                                    'Your hiking memories',
                                    style: TextStyle(
                                      color: AppTheme.warmWhite.withOpacity(0.9),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
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
            actions: [
              // View toggle button
              _buildViewToggleButton(viewMode),
              const SizedBox(width: 8),
            ],
          ),

          // Search and calendar controls
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Search bar
                  _buildSearchBar(searchQuery),
                  const SizedBox(height: 16),

                  // Calendar widget for calendar mode
                  if (viewMode == JournalViewMode.calendar) ...[
                    _buildCalendarView(),
                    const SizedBox(height: 16),
                    _buildSelectedDateHeader(selectedDate),
                  ],
                ],
              ),
            ),
          ),

          // Content based on view mode
          if (viewMode == JournalViewMode.calendar)
            filteredHikes.when(
              data: (hikes) {
                if (hikes.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _buildEmptyCalendarState(),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildHikeCard(hikes[index]),
                      childCount: hikes.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (error, stack) => SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      'Error: $error',
                      style: TextStyle(color: AppTheme.barkBrown),
                    ),
                  ),
                ),
              ),
            )
          else
            // List view mode
            filteredHikes.when(
              data: (hikes) {
                if (hikes.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _buildEmptyListState(searchQuery),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildHikeCard(hikes[index]),
                      childCount: hikes.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (error, stack) => SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      'Error: $error',
                      style: TextStyle(color: AppTheme.barkBrown),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton(JournalViewMode currentMode) {
    return Container(
      margin: const EdgeInsets.only(right: 16, top: 12),
      decoration: BoxDecoration(
        color: AppTheme.warmWhite.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewModeButton(
            icon: Icons.calendar_month,
            isActive: currentMode == JournalViewMode.calendar,
            onTap: () {
              ref.read(journalViewModeProvider.notifier).state =
                  JournalViewMode.calendar;
            },
          ),
          _ViewModeButton(
            icon: Icons.list,
            isActive: currentMode == JournalViewMode.list,
            onTap: () {
              ref.read(journalViewModeProvider.notifier).state =
                  JournalViewMode.list;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(String query) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.barkBrown.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          ref.read(journalSearchQueryProvider.notifier).state = value;
        },
        decoration: InputDecoration(
          hintText: 'Search hikes by title or notes...',
          hintStyle: TextStyle(color: AppTheme.dirtBrown.withOpacity(0.6)),
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.mossGreen,
          ),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    ref.read(journalSearchQueryProvider.notifier).state = '';
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarView() {
    final selectedDate = ref.watch(journalSelectedDateProvider);
    final hikesAsync = ref.watch(hikeListProvider);

    return hikesAsync.when(
      data: (hikes) {
        // Get set of dates that have hikes
        final hikeDates = hikes.map((h) {
          return DateTime(h.date.year, h.date.month, h.date.day);
        }).toSet();

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.warmWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.barkBrown.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: selectedDate,
            selectedDayPredicate: (day) {
              return _isSameDay(day, selectedDate);
            },
            calendarFormat: _calendarFormat,
            onDaySelected: (selectedDay, focusedDay) {
              ref.read(journalSelectedDateProvider.notifier).state = selectedDay;
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              ref.read(journalSelectedDateProvider.notifier).state = focusedDay;
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppTheme.forestGreen,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: AppTheme.mossGreen,
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(color: AppTheme.warmWhite),
              selectedTextStyle: const TextStyle(color: AppTheme.warmWhite),
              defaultTextStyle: TextStyle(color: AppTheme.barkBrown),
              weekendTextStyle: TextStyle(color: AppTheme.forestGreen),
              markerDecoration: BoxDecoration(
                color: AppTheme.forestGreen,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              titleTextStyle: TextStyle(
                color: AppTheme.barkBrown,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: AppTheme.forestGreen,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: AppTheme.forestGreen,
              ),
              decoration: BoxDecoration(
                color: AppTheme.cream.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: AppTheme.dirtBrown,
                fontWeight: FontWeight.w600,
              ),
              weekendStyle: TextStyle(
                color: AppTheme.forestGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
            eventLoader: (day) {
              final dayDate = DateTime(day.year, day.month, day.day);
              return hikeDates.contains(dayDate) ? [''] : [];
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Error loading calendar'),
    );
  }

  Widget _buildSelectedDateHeader(DateTime selectedDate) {
    final formatter = DateFormat('EEEE, MMMM d, yyyy');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.forestGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.forestGreen.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            color: AppTheme.forestGreen,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            formatter.format(selectedDate),
            style: TextStyle(
              color: AppTheme.barkBrown,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHikeCard(dynamic hike) {
    final formatter = DateFormat('MMM dd, yyyy');
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          context.go('/hike/${hike.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.sageGreen.withOpacity(0.4),
                          AppTheme.mossGreen.withOpacity(0.4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getMoodIcon(hike.moodAfter),
                      color: AppTheme.forestGreen,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hike.title,
                          style: TextStyle(
                            color: AppTheme.barkBrown,
                            fontSize: 16,
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
                              size: 13,
                              color: AppTheme.dirtBrown,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formatter.format(hike.date),
                              style: TextStyle(
                                color: AppTheme.dirtBrown,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppTheme.mossGreen,
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    hike.notes,
                    style: TextStyle(
                      color: AppTheme.barkBrown.withOpacity(0.8),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatChip(
                    '${hike.distance.toStringAsFixed(1)} km',
                    Icons.straighten,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    '${hike.duration} min',
                    Icons.schedule,
                  ),
                  if (hike.photos.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _buildStatChip(
                      '${hike.photos.length}',
                      Icons.photo_camera,
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

  Widget _buildStatChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.sageGreen.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: AppTheme.forestGreen,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.forestGreen,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCalendarState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.cream,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy,
              size: 48,
              color: AppTheme.mossGreen.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No hikes on this day',
            style: TextStyle(
              color: AppTheme.barkBrown,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a different day or add a new hike',
            style: TextStyle(
              color: AppTheme.dirtBrown,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyListState(String query) {
    final hasSearch = query.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.cream,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasSearch ? Icons.search_off : Icons.hiking,
              size: 48,
              color: AppTheme.mossGreen.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            hasSearch ? 'No results found' : 'No hikes yet',
            style: TextStyle(
              color: AppTheme.barkBrown,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch ? 'Try a different search term' : 'Start your first adventure',
            style: TextStyle(
              color: AppTheme.dirtBrown,
              fontSize: 14,
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _ViewModeButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ViewModeButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.warmWhite.withOpacity(0.4)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isActive ? AppTheme.warmWhite : AppTheme.warmWhite.withOpacity(0.6),
          size: 20,
        ),
      ),
    );
  }
}
