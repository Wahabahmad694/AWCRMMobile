class AppConstants {
  AppConstants._();

  static const String appName = 'AWC';
  static const String appTagline = 'Built for your next chapter';
  static const String workspaceSubtitle = 'Business workspace';
  static const String currencyCode = 'PKR';
  static const String currencySymbol = 'Rs';

  // API timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Pagination defaults
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Responsive breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;
}
