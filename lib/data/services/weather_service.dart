import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Weather data model
class WeatherData {
  final String condition;
  final double temperature;
  final String icon;
  final String description;
  final bool isManual; // Indicates manually entered offline

  const WeatherData({
    required this.condition,
    required this.temperature,
    required this.icon,
    required this.description,
    this.isManual = false,
  });

  WeatherData copyWith({
    String? condition,
    double? temperature,
    String? icon,
    String? description,
    bool? isManual,
  }) {
    return WeatherData(
      condition: condition ?? this.condition,
      temperature: temperature ?? this.temperature,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      isManual: isManual ?? this.isManual,
    );
  }
}

/// Service for fetching weather data from Open-Meteo
class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1';

  /// Get current weather for a location
  static Future<WeatherData> getWeather(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?lat=$lat&lon=$lng&current_weather=true'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current_weather'];
        final weatherCode = current['weather_code'] as int;

        final condition = _normalizeWeatherCode(weatherCode);
        final temperature = (current['temperature'] ?? 0).toDouble();

        return WeatherData(
          condition: _getConditionName(condition),
          temperature: temperature,
          icon: _getIconFromCondition(condition),
          description: _getWeatherDescription(condition),
        );
      }

      return const WeatherData(
        condition: 'Unknown',
        temperature: 0,
        icon: 'help_outline',
        description: 'Could not fetch weather',
      );
    } catch (e) {
      return const WeatherData(
        condition: 'Unknown',
        temperature: 0,
        icon: 'help_outline',
        description: 'Could not fetch weather',
      );
    }
  }

  /// Get current location using geolocator
  static Future<Map<String, dynamic>> getCurrentLocationWithWeather() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('Location service is disabled');
      }

      final permission = await _checkLocationPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        throw Exception('Location permission denied: $permission');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final weather = await getWeather(
        position.latitude,
        position.longitude,
      );

      return {
        'lat': position.latitude,
        'lng': position.longitude,
        'weather': weather,
      };
    } catch (e) {
      return {
        'lat': 0.0,
        'lng': 0.0,
        'weather': const WeatherData(
          condition: 'Unknown',
          temperature: 0,
          icon: 'help_outline',
          description: 'Location error',
        ),
      };
    }
  }

  /// Check and request location permission
  static Future<LocationPermission> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return LocationPermission.denied;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      return LocationPermission.denied;
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationPermission.deniedForever;
    }

    return LocationPermission.always;
  }

  /// Manual weather entry for offline use
  static WeatherData createManualWeatherEntry({
    required String condition,
    required double temperature,
    required String notes,
  }) {
    return WeatherData(
      condition: condition,
      temperature: temperature,
      icon: _getIconFromName(condition),
      description: notes,
      isManual: true,
    );
  }
}

/// Normalize Open-Meteo weather code to WeatherCondition enum
WeatherCondition _normalizeWeatherCode(int code) {
  // Open-Meteo WMO weather codes
  // https://open-meteo.com/en/docs
  switch (code) {
    case 0:
      return WeatherCondition.clear;
    case 1:
      return WeatherCondition.partlyCloudy;
    case 2:
      return WeatherCondition.partlyCloudy;
    case 3:
      return WeatherCondition.cloudy;
    case 45:
    case 48:
      return WeatherCondition.fog;
    case 51:
    case 53:
    case 55:
      return WeatherCondition.drizzle;
    case 61:
    case 63:
    case 65:
      return WeatherCondition.rain;
    case 66:
    case 67:
      return WeatherCondition.freezingRain;
    case 71:
    case 73:
    case 75:
      return WeatherCondition.snow;
    case 77:
      return WeatherCondition.snow;
    case 80:
    case 81:
    case 82:
      return WeatherCondition.showerRain;
    case 85:
    case 86:
      return WeatherCondition.snow;
    case 95:
      return WeatherCondition.thunderstorm;
    case 96:
    case 99:
      return WeatherCondition.thunderstorm;
    default:
      return WeatherCondition.clear;
  }
}

/// Weather condition codes
enum WeatherCondition {
  clear,
  cloudy,
  fog,
  rain,
  drizzle,
  thunderstorm,
  snow,
  mist,
  smoke,
  haze,
  dust,
  sand,
  ash,
  squall,
  tornado,
  sunny,
  partlyCloudy,
  partlySunny,
  overcast,
  lightRain,
  heavyRain,
  freezingRain,
  lightSnow,
  heavySnow,
  mixedRainAndSnow,
  hot,
  cold,
  windy,
  showerRain,
}

/// Get icon string from WeatherCondition
String _getIconFromCondition(WeatherCondition condition) {
  switch (condition) {
    case WeatherCondition.clear:
    case WeatherCondition.sunny:
      return 'sunny';
    case WeatherCondition.partlySunny:
    case WeatherCondition.partlyCloudy:
      return 'partly_sunny';
    case WeatherCondition.cloudy:
    case WeatherCondition.overcast:
      return 'cloudy';
    case WeatherCondition.fog:
    case WeatherCondition.mist:
      return 'mist';
    case WeatherCondition.smoke:
      return 'smoke';
    case WeatherCondition.haze:
      return 'haze';
    case WeatherCondition.dust:
      return 'dust';
    case WeatherCondition.sand:
      return 'sand';
    case WeatherCondition.ash:
      return 'ash';
    case WeatherCondition.squall:
      return 'squall';
    case WeatherCondition.tornado:
      return 'tornado';
    case WeatherCondition.thunderstorm:
      return 'thunderstorm';
    case WeatherCondition.snow:
      return 'snow';
    case WeatherCondition.lightSnow:
      return 'light_snow';
    case WeatherCondition.heavySnow:
      return 'heavy_snow';
    case WeatherCondition.mixedRainAndSnow:
      return 'rain_and_snow';
    case WeatherCondition.hot:
      return 'hot';
    case WeatherCondition.cold:
      return 'cold';
    case WeatherCondition.windy:
      return 'windy';
    case WeatherCondition.drizzle:
      return 'drizzle';
    case WeatherCondition.rain:
    case WeatherCondition.lightRain:
    case WeatherCondition.heavyRain:
      return 'rain';
    case WeatherCondition.showerRain:
      return 'shower';
    case WeatherCondition.freezingRain:
      return 'freezing_rain';
  }
}

/// Get icon string from condition name (for manual entry)
String _getIconFromName(String condition) {
  final lowerCondition = condition.toLowerCase();
  switch (lowerCondition) {
    case 'clear':
    case 'sunny':
      return 'sunny';
    case 'partly sunny':
    case 'partly cloudy':
      return 'partly_sunny';
    case 'cloudy':
    case 'overcast':
      return 'cloudy';
    case 'fog':
    case 'mist':
      return 'mist';
    case 'smoke':
      return 'smoke';
    case 'haze':
      return 'haze';
    case 'dust':
      return 'dust';
    case 'sand':
      return 'sand';
    case 'ash':
      return 'ash';
    case 'squall':
      return 'squall';
    case 'tornado':
      return 'tornado';
    case 'thunderstorm':
    case 'storm':
      return 'thunderstorm';
    case 'snow':
    case 'light snow':
    case 'heavy snow':
      return 'snow';
    case 'rain and snow':
    case 'sleet':
      return 'rain_and_snow';
    case 'hot':
      return 'hot';
    case 'cold':
      return 'cold';
    case 'windy':
      return 'windy';
    case 'drizzle':
      return 'drizzle';
    case 'rain':
    case 'light rain':
    case 'heavy rain':
    case 'shower':
    case 'showers':
      return 'rain';
    case 'freezing rain':
      return 'freezing_rain';
    default:
      return 'question_mark';
  }
}

/// Get description string from WeatherCondition
String _getWeatherDescription(WeatherCondition condition) {
  switch (condition) {
    case WeatherCondition.clear:
    case WeatherCondition.sunny:
      return 'Clear sky';
    case WeatherCondition.partlySunny:
    case WeatherCondition.partlyCloudy:
      return 'Partly cloudy';
    case WeatherCondition.cloudy:
      return 'Cloudy';
    case WeatherCondition.overcast:
      return 'Overcast';
    case WeatherCondition.fog:
      return 'Foggy';
    case WeatherCondition.mist:
      return 'Misty';
    case WeatherCondition.smoke:
      return 'Smoky';
    case WeatherCondition.haze:
      return 'Hazy';
    case WeatherCondition.dust:
      return 'Dusty';
    case WeatherCondition.sand:
      return 'Sandy';
    case WeatherCondition.ash:
      return 'Ashy';
    case WeatherCondition.squall:
      return 'Squall';
    case WeatherCondition.tornado:
      return 'Tornado';
    case WeatherCondition.thunderstorm:
      return 'Thunderstorm';
    case WeatherCondition.snow:
      return 'Snowing';
    case WeatherCondition.lightSnow:
      return 'Light snow';
    case WeatherCondition.heavySnow:
      return 'Heavy snow';
    case WeatherCondition.mixedRainAndSnow:
      return 'Rain and snow';
    case WeatherCondition.hot:
      return 'Hot';
    case WeatherCondition.cold:
      return 'Cold';
    case WeatherCondition.windy:
      return 'Windy';
    case WeatherCondition.drizzle:
      return 'Drizzling';
    case WeatherCondition.rain:
      return 'Raining';
    case WeatherCondition.lightRain:
      return 'Light rain';
    case WeatherCondition.heavyRain:
      return 'Heavy rain';
    case WeatherCondition.showerRain:
      return 'Showery rain';
    case WeatherCondition.freezingRain:
      return 'Freezing rain';
  }
}

/// Get condition name string from WeatherCondition
String _getConditionName(WeatherCondition condition) {
  switch (condition) {
    case WeatherCondition.clear:
      return 'Clear';
    case WeatherCondition.sunny:
      return 'Sunny';
    case WeatherCondition.partlySunny:
      return 'Partly Sunny';
    case WeatherCondition.partlyCloudy:
      return 'Partly Cloudy';
    case WeatherCondition.cloudy:
      return 'Cloudy';
    case WeatherCondition.overcast:
      return 'Overcast';
    case WeatherCondition.fog:
      return 'Foggy';
    case WeatherCondition.mist:
      return 'Misty';
    case WeatherCondition.smoke:
      return 'Smoky';
    case WeatherCondition.haze:
      return 'Hazy';
    case WeatherCondition.dust:
      return 'Dusty';
    case WeatherCondition.sand:
      return 'Sandy';
    case WeatherCondition.ash:
      return 'Ashy';
    case WeatherCondition.squall:
      return 'Squall';
    case WeatherCondition.tornado:
      return 'Tornado';
    case WeatherCondition.thunderstorm:
      return 'Thunderstorm';
    case WeatherCondition.snow:
      return 'Snowing';
    case WeatherCondition.lightSnow:
      return 'Light Snow';
    case WeatherCondition.heavySnow:
      return 'Heavy Snow';
    case WeatherCondition.mixedRainAndSnow:
      return 'Rain and Snow';
    case WeatherCondition.hot:
      return 'Hot';
    case WeatherCondition.cold:
      return 'Cold';
    case WeatherCondition.windy:
      return 'Windy';
    case WeatherCondition.drizzle:
      return 'Drizzling';
    case WeatherCondition.rain:
      return 'Raining';
    case WeatherCondition.lightRain:
      return 'Light Rain';
    case WeatherCondition.heavyRain:
      return 'Heavy Rain';
    case WeatherCondition.showerRain:
      return 'Showery Rain';
    case WeatherCondition.freezingRain:
      return 'Freezing Rain';
  }
}
