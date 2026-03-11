import 'package:hive/hive.dart';
import '../../models/hike_model.dart';

class HikeRepository {
  static const String _boxName = 'hikes';

  late Box<HikeModel> _box;

  Future<void> init() async {
    _box = await Hive.openBox<HikeModel>(_boxName);
  }

  // Create - Add a new hike
  Future<String> addHike(HikeModel hike) async {
    await _box.put(hike.id, hike);
    return hike.id;
  }

  // Read - Get all hikes
  List<HikeModel> getAllHikes() {
    return _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Read - Get a single hike by id
  HikeModel? getHikeById(String id) {
    return _box.get(id);
  }

  // Update - Update an existing hike
  Future<void> updateHike(HikeModel hike) async {
    await _box.put(hike.id, hike);
  }

  // Delete - Delete a hike by id
  Future<void> deleteHike(String id) async {
    await _box.delete(id);
  }

  // Delete all hikes
  Future<void> clearAll() async {
    await _box.clear();
  }

  // Watch for changes
  Stream<List<HikeModel>> watchHikes() {
    return _box.watch().map((_) => getAllHikes());
  }
}
