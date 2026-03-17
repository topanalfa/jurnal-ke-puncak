import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/providers/hike_provider.dart';
import '../../models/hike_model.dart';
import '../../shared/theme/app_theme.dart';

class LogHikePage extends ConsumerStatefulWidget {
  const LogHikePage({super.key});

  @override
  ConsumerState<LogHikePage> createState() => _LogHikePageState();
}

class _LogHikePageState extends ConsumerState<LogHikePage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  int _moodBeforeValue = 3;
  int _moodAfterValue = 3;
  String _selectedMoodBefore = 'Calm';
  String _selectedMoodAfter = 'Calm';
  List<String> _photos = [];
  bool _isSaving = false;

  // GPS tracking
  LocationData? _startLocation;
  LocationData? _endLocation;

  final List<String> _moodLabels = [
    'Low Energy',
    'Tired',
    'Calm',
    'Energetic',
    'Excited',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _distanceController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _photos.add(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );
      if (photo != null) {
        setState(() {
          _photos.add(photo.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to take photo: $e')),
        );
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  /// Check location permission status
  Future<LocationPermission> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return LocationPermission.denied;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  /// Capture current GPS location
  Future<LocationData?> _captureLocation() async {
    bool isLoadingDialogShown = false;

    try {
      final permission = await _checkLocationPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showLocationPermissionDialog();
        }
        return null;
      }

      if (!mounted) return null;

      // Show loading dialog
      isLoadingDialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _LocationLoadingDialog(),
      );

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      // Close loading dialog
      if (mounted && isLoadingDialogShown) {
        Navigator.of(context).pop();
        isLoadingDialogShown = false;
      }

      if (!mounted) return null;

      final locationData = LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );

      return locationData;
    } catch (e) {
      // Only close dialog if it was actually shown
      if (mounted && isLoadingDialogShown) {
        Navigator.of(context).pop();
      }
      if (mounted) {
        _showLocationErrorDialog(e.toString());
      }
      return null;
    }
  }

  /// Capture start location
  Future<void> _captureStartLocation() async {
    final location = await _captureLocation();
    if (location != null && mounted) {
      setState(() {
        _startLocation = location;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.location_on, color: AppTheme.warmWhite, size: 20),
              SizedBox(width: 8),
              Text('Start location captured'),
            ],
          ),
          backgroundColor: AppTheme.forestGreen,
        ),
      );
    }
  }

  /// Capture end location
  Future<void> _captureEndLocation() async {
    final location = await _captureLocation();
    if (location != null && mounted) {
      setState(() {
        _endLocation = location;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.flag, color: AppTheme.warmWhite, size: 20),
              SizedBox(width: 8),
              Text('End location captured'),
            ],
          ),
          backgroundColor: AppTheme.mossGreen,
        ),
      );
    }
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_off, color: AppTheme.forestGreen),
            const SizedBox(width: 8),
            const Text('Location Permission'),
          ],
        ),
        content: const Text(
          'Location permission is required to capture GPS coordinates. Please enable it in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showLocationErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.barkBrown),
            const SizedBox(width: 8),
            const Text('Location Error'),
          ],
        ),
        content: Text('Failed to get your location: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Calculate distance between start and end locations in km using Haversine formula
  double _calculateDistanceBetweenPoints() {
    if (_startLocation == null || _endLocation == null) return 0.0;

    const double earthRadius = 6371; // km
    final double lat1 = _startLocation!.latitude * (math.pi / 180);
    final double lat2 = _endLocation!.latitude * (math.pi / 180);
    final double lon1 = _startLocation!.longitude * (math.pi / 180);
    final double lon2 = _endLocation!.longitude * (math.pi / 180);

    final double dLat = lat2 - lat1;
    final double dLon = lon2 - lon1;

    final double sinDLat = math.sin(dLat / 2);
    final double sinDLon = math.sin(dLon / 2);

    final double a =
        sinDLat * sinDLat + math.cos(lat1) * math.cos(lat2) * sinDLon * sinDLon;
    final double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  Future<void> _saveHike() async {
    if (_isSaving) return; // Prevent double-tap
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final hike = HikeModel(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        date: _selectedDate,
        duration: int.tryParse(_durationController.text) ?? 0,
        distance: double.tryParse(_distanceController.text) ?? 0.0,
        moodBefore: _selectedMoodBefore,
        moodAfter: _selectedMoodAfter,
        notes: _notesController.text.trim(),
        photos: _photos,
        startLocation: _startLocation,
        endLocation: _endLocation,
      );

      await ref.read(hikeListProvider.notifier).addHike(hike);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hike saved successfully!'),
            backgroundColor: AppTheme.forestGreen,
          ),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save hike: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.forestGreen,
              onPrimary: AppTheme.warmWhite,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final moodOptions = ref.watch(moodOptionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Hike'),
        backgroundColor: AppTheme.forestGreen,
        foregroundColor: AppTheme.warmWhite,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field with icon
              _buildFormField(
                label: 'Trail Name',
                controller: _titleController,
                icon: Icons.terrain,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a trail name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Date picker
              _buildDateField(),
              const SizedBox(height: 20),

              // Duration field
              _buildNumberField(
                label: 'Duration (minutes)',
                controller: _durationController,
                icon: Icons.schedule,
                hint: '60',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter duration';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Distance field
              _buildNumberField(
                label: 'Distance (km)',
                controller: _distanceController,
                icon: Icons.straighten,
                hint: '5.0',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter distance';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // GPS Location Tracking Section
              _buildLocationSection(),
              const SizedBox(height: 24),

              // Mood Before section
              _buildMoodSection(
                title: 'How did you feel before hike?',
                value: _moodBeforeValue,
                moodLabels: _moodLabels,
                onChanged: (value) {
                  setState(() {
                    _moodBeforeValue = value;
                    _selectedMoodBefore = moodOptions[
                        (value - 1).clamp(0, moodOptions.length - 1)];
                  });
                },
              ),
              const SizedBox(height: 24),

              // Mood After section
              _buildMoodSection(
                title: 'How do you feel now?',
                value: _moodAfterValue,
                moodLabels: _moodLabels,
                onChanged: (value) {
                  setState(() {
                    _moodAfterValue = value;
                    _selectedMoodAfter = moodOptions[
                        (value - 1).clamp(0, moodOptions.length - 1)];
                  });
                },
              ),
              const SizedBox(height: 24),

              // Notes field
              _buildNotesField(),
              const SizedBox(height: 24),

              // Photo section
              _buildPhotoSection(),
              const SizedBox(height: 32),

              // Save button
              _buildSaveButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.gps_fixed, color: AppTheme.forestGreen),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'GPS Tracking (optional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.barkBrown,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Location buttons row
        Row(
          children: [
            Expanded(
              child: _buildLocationButton(
                icon: Icons.radio_button_checked,
                label: 'Start',
                subtitle:
                    _startLocation?.displayText ?? 'Tap to set start point',
                color: AppTheme.forestGreen,
                isSet: _startLocation?.isValid ?? false,
                onTap: _captureStartLocation,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLocationButton(
                icon: Icons.flag,
                label: 'Finish',
                subtitle: _endLocation?.displayText ?? 'Tap to set end point',
                color: AppTheme.mossGreen,
                isSet: _endLocation?.isValid ?? false,
                onTap: _captureEndLocation,
              ),
            ),
          ],
        ),

        // Show calculated distance if both points are set
        if (_startLocation?.isValid == true &&
            _endLocation?.isValid == true) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.sageGreen.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.straighten, color: AppTheme.forestGreen, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GPS Distance',
                        style: TextStyle(
                          color: AppTheme.dirtBrown,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(_calculateDistanceBetweenPoints()).toStringAsFixed(2)} km',
                        style: const TextStyle(
                          color: AppTheme.forestGreen,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required bool isSet,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSet ? color.withOpacity(0.15) : AppTheme.warmWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSet ? color : AppTheme.sageGreen.withOpacity(0.3),
            width: isSet ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.barkBrown.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: AppTheme.dirtBrown,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.barkBrown,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Container(
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
          child: TextFormField(
            controller: controller,
            validator: validator,
            decoration: InputDecoration(
              filled: false,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(icon, color: AppTheme.forestGreen),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.barkBrown,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Container(
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
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: validator,
            decoration: InputDecoration(
              filled: false,
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(icon, color: AppTheme.forestGreen),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.barkBrown,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
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
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: AppTheme.forestGreen),
                const SizedBox(width: 12),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.barkBrown,
                      ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: AppTheme.dirtBrown),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodSection({
    required String title,
    required int value,
    required List<String> moodLabels,
    required Function(int) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.emoji_emotions_outlined, color: AppTheme.forestGreen),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.barkBrown,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.cream,
                AppTheme.warmWhite,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.barkBrown.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Mood label
              Text(
                moodLabels[value - 1],
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.forestGreen,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              // Slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.forestGreen,
                  inactiveTrackColor: AppTheme.sageGreen.withOpacity(0.3),
                  thumbColor: AppTheme.forestGreen,
                  overlayColor: AppTheme.forestGreen.withOpacity(0.2),
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 14),
                  trackHeight: 8,
                ),
                child: Slider(
                  value: value.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  onChanged: (newValue) => onChanged(newValue.toInt()),
                ),
              ),
              // Mood indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (index) {
                  final isSelected = value == (index + 1);
                  return Icon(
                    Icons.circle,
                    size: 12,
                    color: isSelected
                        ? AppTheme.forestGreen
                        : AppTheme.sageGreen.withOpacity(0.3),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.edit_note_outlined, color: AppTheme.forestGreen),
            const SizedBox(width: 8),
            Text(
              'Notes (optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.barkBrown,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
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
          child: TextFormField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(
              filled: false,
              hintText: 'Share your thoughts about this hike...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_camera_outlined, color: AppTheme.forestGreen),
            const SizedBox(width: 8),
            Text(
              'Photos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.barkBrown,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_photos.isEmpty)
          _buildEmptyPhotoGrid()
        else
          _buildPhotoGrid(),
      ],
    );
  }

  Widget _buildEmptyPhotoGrid() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _pickImage,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.cream,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.sageGreen.withOpacity(0.3),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 32,
                    color: AppTheme.mossGreen,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add Photos',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.barkBrown,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: _takePhoto,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.cream,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.sageGreen.withOpacity(0.3),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 32,
                    color: AppTheme.mossGreen,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Take Photo',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.barkBrown,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoGrid() {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _photos.length + 1,
          itemBuilder: (context, index) {
            if (index == _photos.length) {
              // Add photo button
              return InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cream,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.sageGreen.withOpacity(0.3),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 32,
                    color: AppTheme.mossGreen,
                  ),
                ),
              );
            }

            // Photo preview
            return Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppTheme.cream,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(_photos[index]),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
                // Remove button
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removePhoto(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.barkBrown,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: AppTheme.warmWhite,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveHike,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.warmWhite),
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Saving...' : 'Save Hike'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.forestGreen,
          foregroundColor: AppTheme.warmWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

/// Loading dialog for location capture
class _LocationLoadingDialog extends StatelessWidget {
  const _LocationLoadingDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: AppTheme.forestGreen,
          ),
          const SizedBox(height: 16),
          Text(
            'Getting your location...',
            style: TextStyle(color: AppTheme.barkBrown),
          ),
        ],
      ),
    );
  }
}
