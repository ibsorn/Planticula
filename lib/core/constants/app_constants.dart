class AppConstants {
  // App Info
  static const String appName = 'Planticula';
  static const String appVersion = '0.1.0';

  // Routes
  static const String routeSplash = '/';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeHome = '/home';
  static const String routePlants = '/plants';
  static const String routePlantDetail = '/plants/:id';
  static const String routeProfile = '/profile';
  static const String routePestAlerts = '/pest-alerts';
  static const String routeReportPest = '/pest-alerts/report';
  static const String routePestAlertDetail = '/pest-alerts/:id';
  static const String routeMarketplace = '/marketplace';
  static const String routeCreateListing = '/marketplace/create';
  static const String routeListingDetail = '/listing/:id';
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

  // Private constructor to prevent instantiation
  AppConstants._();
}
