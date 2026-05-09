import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:vibration/vibration.dart';

class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  static const String _tapSoundAsset = 'assets/audio/tap.wav';
  static const Duration _maxTapSoundLength = Duration(milliseconds: 100);

  bool _isInitialized = false;
  bool _hasVibrator = false;

  final SoLoud _soloud = SoLoud.instance;
  AudioSource? _tapSound;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _hasVibrator = await Vibration.hasVibrator();
      await _soloud.init();
      _tapSound = await _soloud.loadAsset(
        _tapSoundAsset,
        mode: LoadMode.memory,
      );

      _isInitialized = true;
    } catch (e) {
      _hasVibrator = true;
      if (kDebugMode) debugPrint('FeedbackService init error: $e');
    }
  }

  void triggerTapFeedback() {
    try {
      if (_isInitialized && _tapSound != null) {
        final handle = _soloud.play(_tapSound!, volume:0.5);
        // _soloud.setRelativePlaySpeed(handle, 1.18);
        // _soloud.scheduleStop(handle, _maxTapSoundLength);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Tap sound error: $e');
    }

    _triggerHaptics();
  }

  void _triggerHaptics() {
    if (_hasVibrator) {
      Vibration.vibrate(duration: 40);
    } else {
      HapticFeedback.lightImpact();
    }

    // HapticFeedback.selectionClick();
  }

  Future<void> dispose() async {
    if (_tapSound != null) {
      await _soloud.disposeSource(_tapSound!);
      _tapSound = null;
    }
    _soloud.deinit();
    _isInitialized = false;
  }
}
