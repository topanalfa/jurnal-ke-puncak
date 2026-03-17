import 'package:hive/hive.dart';

part 'hike_model.g.dart';

/// Represents GPS coordinates
@HiveType(typeId: 20)
class LocationData extends HiveObject {
  @HiveField(0)
  final double latitude;

  @HiveField(1)
  final double longitude;

  @HiveField(2)
  final DateTime? timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.timestamp,
  });

  LocationData copyWith({
    double? latitude,
    double? longitude,
    DateTime? timestamp,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  bool get isValid => latitude != 0 && longitude != 0;

  String get displayText {
    if (!isValid) return 'Location not recorded';
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  @override
  String toString() =>
      'LocationData(lat: $latitude, lng: $longitude, time: $timestamp)';
}

@HiveType(typeId: 0)
class HikeModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final int duration; // in minutes

  @HiveField(4)
  final double distance; // in km

  @HiveField(5)
  final String moodBefore;

  @HiveField(6)
  final String moodAfter;

  @HiveField(7)
  final String notes;

  @HiveField(8)
  final List<String> photos; // List of image paths/URLs

  @HiveField(9)
  final LocationData? startLocation;

  @HiveField(10)
  final LocationData? endLocation;

  HikeModel({
    required this.id,
    required this.title,
    required this.date,
    required this.duration,
    required this.distance,
    required this.moodBefore,
    required this.moodAfter,
    required this.notes,
    required this.photos,
    this.startLocation,
    this.endLocation,
  });

  HikeModel copyWith({
    String? id,
    String? title,
    DateTime? date,
    int? duration,
    double? distance,
    String? moodBefore,
    String? moodAfter,
    String? notes,
    List<String>? photos,
    LocationData? startLocation,
    LocationData? endLocation,
  }) {
    return HikeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      distance: distance ?? this.distance,
      moodBefore: moodBefore ?? this.moodBefore,
      moodAfter: moodAfter ?? this.moodAfter,
      notes: notes ?? this.notes,
      photos: photos ?? this.photos,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
    );
  }

  @override
  String toString() {
    return 'HikeModel(id: $id, title: $title, date: $date, duration: $duration, distance: $distance, moodBefore: $moodBefore, moodAfter: $moodAfter, notes: $notes, photos: $photos, start: $startLocation, end: $endLocation)';
  }
}
