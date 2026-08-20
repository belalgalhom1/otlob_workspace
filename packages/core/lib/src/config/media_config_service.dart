class MediaConfigService {
  MediaConfigService();

  // Strict matches against otlob-backend media.config.ts
  static const int chatMediaLimitMB = 10;
  static const int genericMediaLimitMB = 5;

  /// Helper to validate file size before hitting the API
  bool validateFileSize(int bytes, String type) {
    final limitMB = type.toUpperCase() == 'CHAT' ? chatMediaLimitMB : genericMediaLimitMB;
    final sizeInMB = bytes / (1024 * 1024);
    return sizeInMB <= limitMB;
  }
}
