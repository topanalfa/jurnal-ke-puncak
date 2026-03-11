import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/hike_model.dart';
import '../repositories/hike_repository.dart';

// Provider for HikeRepository
final hikeRepositoryProvider = Provider<HikeRepository>((ref) {
  final repository = HikeRepository();
  ref.onDispose(() {
    // Cleanup if needed
  });
  return repository;
});

// AsyncNotifier for managing hike list state
class HikeListAsyncNotifier extends AsyncNotifier<List<HikeModel>> {
  HikeRepository get _repository => ref.read(hikeRepositoryProvider);

  @override
  Future<List<HikeModel>> build() async {
    await _repository.init();
    return _repository.getAllHikes();
  }

  // Add a new hike
  Future<void> addHike(HikeModel hike) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.addHike(hike);
      return _repository.getAllHikes();
    });
  }

  // Update an existing hike
  Future<void> updateHike(HikeModel hike) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateHike(hike);
      return _repository.getAllHikes();
    });
  }

  // Delete a hike
  Future<void> deleteHike(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteHike(id);
      return _repository.getAllHikes();
    });
  }

  // Refresh the hike list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return _repository.getAllHikes();
    });
  }
}

// Provider for hike list
final hikeListProvider =
    AsyncNotifierProvider<HikeListAsyncNotifier, List<HikeModel>>(
  HikeListAsyncNotifier.new,
);

// Provider for a single hike by ID
final hikeProvider = Provider.family<HikeModel?, String>((ref, id) {
  final hikesAsync = ref.watch(hikeListProvider);
  return hikesAsync.when(
    data: (hikes) => hikes.firstWhere(
      (hike) => hike.id == id,
      orElse: () => HikeModel(
        id: '',
        title: '',
        date: DateTime.now(),
        duration: 0,
        distance: 0,
        moodBefore: '',
        moodAfter: '',
        notes: '',
        photos: [],
      ),
    ),
    loading: () => null,
    error: (_, __) => null,
  );
});

// Provider for mood options
final moodOptionsProvider = Provider<List<String>>((ref) {
  return [
    'Energetic',
    'Calm',
    'Tired',
    'Excited',
    'Peaceful',
    'Relaxed',
    'Challenged',
    'Refreshed',
  ];
});
