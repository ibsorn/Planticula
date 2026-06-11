import 'dart:convert';
import 'package:http/http.dart' as http;

/// Weather data from Open-Meteo API (free, no API key required)
class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1';

  final http.Client _client;

  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  /// Get current weather and 7-day forecast for given coordinates
  Future<WeatherData> getWeather(double latitude, double longitude) async {
    final uri = Uri.parse(
      '$_baseUrl/forecast?latitude=$latitude&longitude=$longitude'
      '&current=temperature_2m,relative_humidity_2m,precipitation,weather_code'
      '&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,weather_code'
      '&timezone=auto&forecast_days=7',
    );

    final response = await _client.get(uri).timeout(
      const Duration(seconds: 10),
    );

    if (response.statusCode != 200) {
      throw WeatherException('Error fetching weather: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    return WeatherData.fromJson(data);
  }

  void dispose() {
    _client.close();
  }
}

class WeatherData {
  final CurrentWeather current;
  final List<DailyForecast> daily;

  const WeatherData({required this.current, required this.daily});

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>;

    final dates = (daily['time'] as List<dynamic>).cast<String>();
    final maxTemps = (daily['temperature_2m_max'] as List<dynamic>).cast<num>();
    final minTemps = (daily['temperature_2m_min'] as List<dynamic>).cast<num>();
    final precip = (daily['precipitation_sum'] as List<dynamic>).cast<num>();
    final codes = (daily['weather_code'] as List<dynamic>).cast<int>();

    final dailyForecasts = <DailyForecast>[];
    for (int i = 0; i < dates.length; i++) {
      dailyForecasts.add(DailyForecast(
        date: DateTime.parse(dates[i]),
        maxTemp: maxTemps[i].toDouble(),
        minTemp: minTemps[i].toDouble(),
        precipitationMm: precip[i].toDouble(),
        weatherCode: codes[i],
      ));
    }

    return WeatherData(
      current: CurrentWeather(
        temperature: (current['temperature_2m'] as num).toDouble(),
        humidity: (current['relative_humidity_2m'] as num).toDouble(),
        precipitationMm: (current['precipitation'] as num).toDouble(),
        weatherCode: current['weather_code'] as int,
      ),
      daily: dailyForecasts,
    );
  }

  /// Total precipitation expected in the next N days
  double precipitationNextDays(int days) {
    return daily.take(days).fold(0.0, (sum, d) => sum + d.precipitationMm);
  }

  /// Whether it will rain significantly in the next N days (>2mm)
  bool willRainSoon({int days = 3}) {
    return precipitationNextDays(days) > 2.0;
  }

  /// Average max temperature for the next N days
  double avgMaxTempNextDays(int days) {
    final subset = daily.take(days).toList();
    if (subset.isEmpty) return 25;
    return subset.fold(0.0, (sum, d) => sum + d.maxTemp) / subset.length;
  }

  /// Weather description for current conditions
  String get currentDescription => _weatherCodeToDescription(current.weatherCode);

  /// Whether it's currently raining
  bool get isRaining => current.precipitationMm > 0;
}

class CurrentWeather {
  final double temperature;
  final double humidity;
  final double precipitationMm;
  final int weatherCode;

  const CurrentWeather({
    required this.temperature,
    required this.humidity,
    required this.precipitationMm,
    required this.weatherCode,
  });
}

class DailyForecast {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final double precipitationMm;
  final int weatherCode;

  const DailyForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.precipitationMm,
    required this.weatherCode,
  });

  bool get willRain => precipitationMm > 1.0;
  String get description => _weatherCodeToDescription(weatherCode);
}

class WeatherException implements Exception {
  final String message;
  const WeatherException(this.message);
  @override
  String toString() => message;
}

/// WMO Weather interpretation codes to human-readable description
String _weatherCodeToDescription(int code) {
  if (code == 0) return 'Despejado';
  if (code <= 3) return 'Parcialmente nublado';
  if (code <= 49) return 'Niebla';
  if (code <= 59) return 'Llovizna';
  if (code <= 69) return 'Lluvia';
  if (code <= 79) return 'Nieve';
  if (code <= 84) return 'Chubascos';
  if (code <= 99) return 'Tormenta';
  return 'Desconocido';
}
