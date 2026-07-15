import 'package:audioplayers/audioplayers.dart';

class NotificationSoundService {
  static final NotificationSoundService _instance = NotificationSoundService._();
  factory NotificationSoundService() => _instance;
  NotificationSoundService._();

  final AudioPlayer _player = AudioPlayer();
  bool _enabled = true;

  bool get enabled => _enabled;

  void setEnabled(bool value) {
    _enabled = value;
  }

  Future<void> playNotificationSound() async {
    if (!_enabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/notification.mp3'));
    } catch (_) {
      // Sound file not available yet — silently ignore
    }
  }

  Future<void> playChatSound() async {
    if (!_enabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/chat.mp3'));
    } catch (_) {}
  }

  void dispose() {
    _player.dispose();
  }
}
