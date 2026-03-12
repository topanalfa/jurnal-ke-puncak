import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import '../../data/providers/hike_provider.dart';
import '../../models/hike_model.dart';
import '../../shared/theme/app_theme.dart';

class HikeDetailPage extends ConsumerWidget {
  final String hikeId;

  const HikeDetailPage({super.key, required this.hikeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hike = ref.watch(hikeProvider(hikeId));

    if (hike == null || hike.id.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hiking_outlined,
                size: 64,
                color: AppTheme.mossGreen,
              ),
              const SizedBox(height: 16),
              Text(
                'Hike not found',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.barkBrown,
                    ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero image header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppTheme.forestGreen,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Main photo or gradient fallback
                  if (hike.photos.isNotEmpty)
                    Positioned.fill(
                      child: Image.file(
                        File(hike.photos.first),
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, error, stackTrace) {
                          return _buildGradientHeader(hike);
                        },
                      ),
                    )
                  else
                    _buildGradientHeader(hike),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                  // Back button
                  Positioned(
                    top: 50,
                    left: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.warmWhite.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => context.go('/home'),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppTheme.barkBrown,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  // Title and date
                  _buildTitleSection(context, hike),
                  const SizedBox(height: 24),

                  // Stats row
                  _buildStatsRow(context, hike),
                  const SizedBox(height: 24),

                  // Mood section
                  _buildMoodSection(context, hike),
                  const SizedBox(height: 24),

                  // Map snapshot
                  _buildMapSection(context),
                  const SizedBox(height: 24),

                  // Notes section
                  if (hike.notes.isNotEmpty) ...[
                    _buildNotesSection(context, hike),
                    const SizedBox(height: 24),
                  ],

                  // Photo gallery
                  if (hike.photos.length > 1)
                    _buildPhotoGallery(context, hike),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      // Floating delete button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _confirmDelete(context, ref, hike),
        backgroundColor: AppTheme.barkBrown,
        foregroundColor: AppTheme.warmWhite,
        icon: const Icon(Icons.delete_outline),
        label: const Text('Delete'),
      ),
    );
  }

  Widget _buildGradientHeader(HikeModel hike) {
    return Container(
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.terrain_outlined,
              size: 80,
              color: AppTheme.warmWhite.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              hike.title,
              style: const TextStyle(
                color: AppTheme.warmWhite,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context, HikeModel hike) {
    final formatter = DateFormat('MMMM dd, yyyy • HH:mm');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Accent bar
        Container(
          width: 60,
          height: 4,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.forestGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Title
        Text(
          hike.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.barkBrown,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        // Date
        Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppTheme.dirtBrown,
            ),
            const SizedBox(width: 8),
            Text(
              formatter.format(hike.date),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.dirtBrown,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context, HikeModel hike) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.straighten,
            label: 'Distance',
            value: '${hike.distance.toStringAsFixed(1)} km',
            color: AppTheme.forestGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.schedule,
            label: 'Duration',
            value: '${hike.duration} min',
            color: AppTheme.mossGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.photo_library_outlined,
            label: 'Photos',
            value: '${hike.photos.length}',
            color: AppTheme.amberAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.barkBrown.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 28,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.dirtBrown,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.barkBrown,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSection(BuildContext context, HikeModel hike) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.cream,
            AppTheme.warmWhite,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.forestGreen.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_emotions_outlined,
                color: AppTheme.forestGreen,
              ),
              const SizedBox(width: 8),
              Text(
                'Mood Journey',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.barkBrown,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMoodChip(
                  context,
                  label: 'Before',
                  mood: hike.moodBefore,
                  isBefore: true,
                ),
              ),
              const SizedBox(width: 12),
              // Arrow icon
              Transform.rotate(
                angle: 0.3,
                child: Icon(
                  Icons.arrow_forward,
                  color: AppTheme.sageGreen.withOpacity(0.5),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMoodChip(
                  context,
                  label: 'After',
                  mood: hike.moodAfter,
                  isBefore: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodChip(
    BuildContext context, {
    required String label,
    required String mood,
    required bool isBefore,
  }) {
    final moodIcon = _getMoodIcon(mood);
    final moodColor = _getMoodColor(mood);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: moodColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: moodColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.dirtBrown,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Icon(
            moodIcon,
            size: 36,
            color: moodColor,
          ),
          const SizedBox(height: 8),
          Text(
            mood,
            style: TextStyle(
              color: moodColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
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

  Color _getMoodColor(String mood) {
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

  Widget _buildMapSection(BuildContext context) {
    // Static map placeholder - can integrate Google Maps Static API later
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.cream,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.barkBrown.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Static map image placeholder
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                'https://api.mapbox.com/styles/v1/mapbox/outdoors-v11/static/-6.2000,106.8166,12,0,0/600x400?access_token=placeholder',
                fit: BoxFit.cover,
                errorBuilder: (ctx, error, stackTrace) {
                  return Container(
                    color: AppTheme.cream,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 48,
                          color: AppTheme.forestGreen.withOpacity(0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Map view',
                          style: TextStyle(
                            color: AppTheme.barkBrown.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          // Map overlay info
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.warmWhite.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: AppTheme.forestGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Jakarta, Indonesia',
                    style: TextStyle(
                      color: AppTheme.barkBrown,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context, HikeModel hike) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.barkBrown.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_note_outlined,
                color: AppTheme.forestGreen,
              ),
              const SizedBox(width: 8),
              Text(
                'Notes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.barkBrown,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cream.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.format_quote,
                  color: AppTheme.forestGreen.withOpacity(0.5),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hike.notes,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.barkBrown,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery(BuildContext context, HikeModel hike) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
              'Photo Gallery (${hike.photos.length})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.barkBrown,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 150,
          ),
          itemCount: hike.photos.length,
          itemBuilder: (ctx, index) {
            return InkWell(
              onTap: () => _showPhotoViewer(context, hike.photos, index),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.cream,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.barkBrown.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(
                    File(hike.photos[index]),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showPhotoViewer(BuildContext context, List<String> photos, int initialIndex) {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.fade,
        child: PhotoViewerPage(
          photos: photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    HikeModel hike,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.delete_outline,
              color: AppTheme.barkBrown,
            ),
            const SizedBox(width: 12),
            Text(
              'Delete Hike',
              style: const TextStyle(color: AppTheme.barkBrown),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${hike.title}"? This action cannot be undone.',
          style: const TextStyle(color: AppTheme.barkBrown),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.barkBrown,
              foregroundColor: AppTheme.warmWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(hikeListProvider.notifier).deleteHike(hike.id);
      if (context.mounted) {
        context.go('/home');
      }
    }
  }
}

// Photo viewer page for full-screen viewing
class PhotoViewerPage extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const PhotoViewerPage({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<PhotoViewerPage> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    if (_pageController.page?.round() != _currentIndex) {
      setState(() {
        _currentIndex = _pageController.page?.round() ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Photo viewer
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            itemBuilder: (ctx, index) {
              return PhotoZoomable(
                imageProvider: FileImage(File(widget.photos[index])),
              );
            },
          ),
          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: AppTheme.warmWhite,
                        size: 28,
                      ),
                    ),
                    Text(
                      '${_currentIndex + 1} / ${widget.photos.length}',
                      style: const TextStyle(
                        color: AppTheme.warmWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Simple zoomable photo widget
class PhotoZoomable extends StatefulWidget {
  final ImageProvider imageProvider;

  const PhotoZoomable({super.key, required this.imageProvider});

  @override
  State<PhotoZoomable> createState() => _PhotoZoomableState();
}

class _PhotoZoomableState extends State<PhotoZoomable> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (_) {},
      onScaleUpdate: (details) {
        setState(() {
          _scale = details.scale.clamp(1.0, 4.0);
        });
      },
      onScaleEnd: (_) {
        setState(() {
          if (_scale < 1.1) _scale = 1.0;
        });
      },
      child: Transform.scale(
        scale: _scale,
        child: Center(
          child: Image(
            image: widget.imageProvider,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
