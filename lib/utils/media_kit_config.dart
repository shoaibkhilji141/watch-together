import 'package:media_kit/media_kit.dart';

/// Tuned for network MP4 (Firebase Storage, archive.org, direct links).
class MediaKitStreaming {
  static const int bufferBytes = 64 * 1024 * 1024;
  static const int maxRetryAttempts = 3;

  static Player createPlayer() {
    return Player(
      configuration: const PlayerConfiguration(
        bufferSize: bufferBytes,
        logLevel: MPVLogLevel.error,
      ),
    );
  }

  /// Apply libmpv cache settings before [Player.open] for smoother slow networks.
  static Future<void> applyNetworkOptimizations(Player player) async {
    if (player.platform is! NativePlayer) return;
    final native = player.platform as NativePlayer;
    await native.setProperty('cache', 'yes');
    await native.setProperty('cache-secs', '60');
    await native.setProperty('demuxer-readahead-secs', '20');
    await native.setProperty('network-timeout', '60');
  }
}
