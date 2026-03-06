import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Application-wide structured logger.
///
/// Use [AppLogger.d]/[AppLogger.i]/[AppLogger.e] throughout the app.
/// In release builds, only errors and warnings are logged.
final class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
    level: kReleaseMode ? Level.warning : Level.trace,
  );

  /// Debug log — verbose, only in debug mode.
  static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.d(message, error: error, stackTrace: stackTrace);

  /// Info log.
  static void i(dynamic message) => _logger.i(message);

  /// Warning log.
  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.w(message, error: error, stackTrace: stackTrace);

  /// Error log — always logged, even in release.
  static void e(
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
