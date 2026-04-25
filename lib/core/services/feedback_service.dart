// import 'dart:async';
//
// import 'package:audioplayers/audioplayers.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/services.dart';
// import 'package:vibration/vibration.dart';
//
// class FeedbackService {
//   static final FeedbackService _instance = FeedbackService._internal();
//   factory FeedbackService() => _instance;
//   FeedbackService._internal();
//
//   static const String _tapSoundAsset = 'audio/tap_sound.mp3';
//
//   bool _isInitialized = false;
//   bool _hasVibrator = false;
//
//   AudioPool? _tapSoundPool;
//
//   Future<void> init() async {
//     if (_isInitialized) return;
//
//     try {
//       _hasVibrator = await Vibration.hasVibrator();
//       _tapSoundPool = await AudioPool.createFromAsset(
//         path: _tapSoundAsset,
//         minPlayers: 4,
//         maxPlayers: 8,
//         playerMode: PlayerMode.lowLatency,
//       );
//
//       _isInitialized = true;
//     } catch (e) {
//       _hasVibrator = true;
//       if (kDebugMode) {
//         debugPrint('FeedbackService initialization error: $e');
//       }
//     }
//   }
//
//   void triggerTapFeedback() {
//     unawaited(_playTapSound());
//     _triggerHaptics();
//   }
//
//   Future<void> _playTapSound() async {
//     try {
//       final stop = await _tapSoundPool?.start(volume: 1.0);
//       Future.delayed(const Duration(milliseconds: 200), () {
//         unawaited(stop?.call());
//       });
//     } catch (e) {
//       if (kDebugMode) {
//         debugPrint('Audio error: $e');
//       }
//     }
//   }
//
//   void _triggerHaptics() {
//     if (_hasVibrator) {
//       Vibration.vibrate(duration: 40);
//     } else {
//       HapticFeedback.lightImpact();
//     }
//
//     HapticFeedback.selectionClick();
//   }
//
//   Future<void> dispose() async {
//     await _tapSoundPool?.dispose();
//     _tapSoundPool = null;
//     _isInitialized = false;
//   }
// }


import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:vibration/vibration.dart';

class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  bool _isInitialized = false;
  bool _hasVibrator = false;

  final SoLoud _soloud = SoLoud.instance;
  AudioSource? _tapSound;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _hasVibrator = await Vibration.hasVibrator() ?? false;

      // SoLoud initialize করো
      await _soloud.init();

      // Sound memory-তে load করো
      _tapSound = await _soloud.loadAsset('assets/audio/tap_sound.mp3');

      _isInitialized = true;
    } catch (e) {
      _hasVibrator = true;
      if (kDebugMode) debugPrint('FeedbackService init error: $e');
    }
  }

  void triggerTapFeedback() {
    if (_tapSound != null) {
      _soloud.play(_tapSound!, volume: 0.3); // 0.1 - 0.5 এর মধ্যে adjust করো
    }
    _triggerHaptics();
  }

  void _triggerHaptics() {
    if (_hasVibrator) {
      Vibration.vibrate(duration: 40);
    } else {
      HapticFeedback.lightImpact();
    }
    HapticFeedback.selectionClick();
  }

  Future<void> dispose() async {
    if (_tapSound != null) {
      _soloud.disposeSource(_tapSound!);
    }
    _soloud.deinit(); // await সরাও
    _isInitialized = false;
  }
}