import 'package:logger/logger.dart' as external_logger;

class Logger {
  static final external_logger.Logger _logger = external_logger.Logger(
    printer: external_logger.PrettyPrinter(
      dateTimeFormat: external_logger.DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static void d(String message) => _logger.d(message);
  static void i(String message) => _logger.i(message);
  static void w(String message) => _logger.w(message);
  static void e(String message, {dynamic error, StackTrace? stackTrace}) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
  static void v(String message) => _logger.t(message);
}
