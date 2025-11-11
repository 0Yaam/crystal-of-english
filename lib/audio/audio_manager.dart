import 'package:flame_audio/flame_audio.dart';

class AudioManager {
  AudioManager._();
  static final AudioManager instance = AudioManager._();

  bool _bgmEnabled = true;
  bool _sfxEnabled = true;
  double _bgmVolume = 0.5;
  double _sfxVolume = 0.8;
  String? _currentBgm;

  Future<void> init() async {
    await FlameAudio.bgm.initialize();
  }




  Future<void> playBgm(String asset, {double? volume, bool loop = true}) async {
    if (!_bgmEnabled) return;
    _currentBgm = asset;
    if (volume != null) {
      _bgmVolume = volume.clamp(0.0, 1.0).toDouble();
    }
    await FlameAudio.bgm.stop();
    await FlameAudio.bgm.play(asset, volume: _bgmVolume);
  }

  Future<void> stopBgm() async {
    _currentBgm = null;
    await FlameAudio.bgm.stop();
  }

  Future<void> pauseBgm() async {
    await FlameAudio.bgm.pause();
  }

  Future<void> resumeBgm() async {
    if (!_bgmEnabled) return;
    await FlameAudio.bgm.resume();
  }

  void setBgmEnabled(bool enabled) {
    _bgmEnabled = enabled;
    if (!enabled) {
      FlameAudio.bgm.pause();
    } else {

      FlameAudio.bgm.resume();
    }
  }

  void setBgmVolume(double v) {
    _bgmVolume = v.clamp(0.0, 1.0).toDouble();
    FlameAudio.bgm.audioPlayer.setVolume(_bgmVolume);
  }

  String? get currentBgm => _currentBgm;
  bool get bgmEnabled => _bgmEnabled;
  double get bgmVolume => _bgmVolume;


  Future<void> playSfx(String asset, {double? volume}) async {
    if (!_sfxEnabled) return;
    final vol = (volume ?? _sfxVolume).clamp(0.0, 1.0).toDouble();
    await FlameAudio.play(asset, volume: vol);
  }

  void setSfxEnabled(bool enabled) {
    _sfxEnabled = enabled;
  }

  void setSfxVolume(double v) {
    _sfxVolume = v.clamp(0.0, 1.0).toDouble();
  }

  bool get sfxEnabled => _sfxEnabled;
  double get sfxVolume => _sfxVolume;
}
