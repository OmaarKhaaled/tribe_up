import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class VideoCacheManager {
  static const String videoCacheKey = 'video_cache_key';
  static CacheManager cacheManager = CacheManager(
    Config(
      videoCacheKey,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 10,
    ),
  );
}
