class AppConstants {
  // App Info
  static const String appName = 'Planticula';
  static const String appVersion = '0.1.0';

  // Routes
  static const String routeSplash = '/';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeHome = '/home';
  static const String routeToday = '/today';
  static const String routePlants = '/plants';
  static const String routePlantDetail = '/plants/:id';
  static const String routePlantEditor = '/plants/editor';
  static const String routePlantIdentification = '/plants/identify';
  static const String routeProfile = '/profile';
  static const String routePestAlerts = '/pest-alerts';
  static const String routeReportPest = '/pest-alerts/report';
  static const String routePestAlertDetail = '/pest-alerts/:id';
  static const String routeMarketplace = '/marketplace';
  static const String routeCreateListing = '/marketplace/create';
  static const String routeListingDetail = '/listing/:id';
  static const String routeTools = '/tools';
  static const String routeSoilAnalysis = '/soil-analysis';
  static const String routeSoilAnalysisDetail = '/soil-analysis/:id';
  static const String routeGuides = '/guides';

  // Storage Keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyAccessToken = 'access_token';
  static const String keyUserId = 'user_id';

  // Pagination
  static const int defaultPageSize = 20;

  // Image Quality
  static const int imageQuality = 85;
  static const double maxImageWidth = 1920;
  static const double maxImageHeight = 1920;

  // Timeouts
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;

  // Transplant schedule sentinel: plant should never be transplanted in this phase
  // (e.g. root vegetables and short-cycle crops that are harvested directly)
  static const int neverTransplant = 999;

  // --- WateringCalculator thresholds ---
  /// Number of forecast days used for weather averaging
  static const int weatherForecastDays = 3;
  /// High temperature threshold in °C (triggers more frequent watering)
  static const double tempHighThresholdC = 30.0;
  /// Low temperature threshold in °C (triggers less frequent watering / heating adjustment)
  static const double tempLowThresholdC = 10.0;
  /// Heavy rain threshold in mm (postpone watering significantly)
  static const double rainHeavyMm = 5.0;
  /// Light rain threshold in mm (minor watering adjustment)
  static const double rainLightMm = 2.0;
  /// Low humidity threshold % (trigger more frequent watering for humidity-loving plants)
  static const double humidityLowPct = 40.0;
  /// Watering frequency multiplier when indoor humidity is low due to heating
  static const double indoorHeatingMultiplier = 0.9;
  /// Watering frequency multiplier when outdoor humidity is low
  static const double lowHumidityWateringMultiplier = 0.8;
  /// Minimum allowed watering frequency in days
  static const int wateringFrequencyMinDays = 1;
  /// Maximum allowed watering frequency in days
  static const int wateringFrequencyMaxDays = 60;
  /// Water amount multiplier for seedling stage
  static const double seedlingWaterMultiplier = 0.4;
  /// Water amount multiplier for juvenile stage
  static const double juvenileWaterMultiplier = 0.7;
  /// Water amount multiplier for drought-tolerant species
  static const double droughtTolerantWaterMultiplier = 0.7;
  /// Water amount multiplier for humidity-loving species
  static const double humidityLovingWaterMultiplier = 1.2;
  /// Minimum water amount per session in ml
  static const int waterMlMin = 20;
  /// Maximum water amount per session in ml
  static const int waterMlMax = 5000;
  /// Threshold in ml above which amount is displayed in liters
  static const int waterMlLiterThreshold = 1000;
  /// Lower bound of the displayed water range (factor)
  static const double waterRangeLowerFactor = 0.8;
  /// Upper bound of the displayed water range (factor)
  static const double waterRangeUpperFactor = 1.2;

  // --- TransplantCalculator thresholds ---
  /// Months overdue before a transplant is considered urgent
  static const int transplantUrgentMonths = 3;
  /// Months until due before showing an upcoming transplant warning
  static const int transplantUpcomingMonths = 1;

  // Private constructor to prevent instantiation
  AppConstants._();
}
