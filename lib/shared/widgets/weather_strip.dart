import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

/// Plain data for one day in the [WeatherStrip].
class WeatherStripDay {
  final String label; // e.g. "Vie"
  final int weatherCode; // WMO code from Open-Meteo
  final double maxTemp;
  final double precipitationMm;

  const WeatherStripDay({
    required this.label,
    required this.weatherCode,
    required this.maxTemp,
    required this.precipitationMm,
  });
}

/// Horizontal 5-7 day forecast strip: emoji + temperature + rain drop.
class WeatherStrip extends StatelessWidget {
  final List<WeatherStripDay> days;

  /// Optional tint for texts (when placed inside a HeroBanner).
  final Color? foreground;

  const WeatherStrip({super.key, required this.days, this.foreground});

  /// WMO weather code to a playful emoji.
  static String emojiFor(int code) {
    if (code == 0) return '☀️';
    if (code <= 2) return '⛅';
    if (code == 3) return '☁️';
    if (code <= 49) return '🌫️';
    if (code <= 69) return '🌧️';
    if (code <= 79) return '❄️';
    if (code <= 84) return '🌦️';
    return '⛈️';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = foreground ?? theme.colorScheme.onSurface;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final day in days)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                day.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: fg.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppDimens.xs),
              Text(emojiFor(day.weatherCode),
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(height: AppDimens.xs),
              Text(
                '${day.maxTemp.round()}°',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(
                height: 14,
                child: day.precipitationMm > 1.0
                    ? const Text(
                        '💧',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.water,
                        ),
                      )
                    : null,
              ),
            ],
          ),
      ],
    );
  }
}
