import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'dart:math' hide log;

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';

const Duration TIMER = Duration(seconds: 35);

class BuzzerStateMachine {
  FutureOr<Null> Function() onStart;
  FutureOr<Null> Function() onRestart;
  FutureOr<Null> Function() onTimer;
  FutureOr<Null> Function() onPrepAudio;
  FutureOr<Null> Function(Duration time) updateDisplay;
  DateTime _start;
  Timer _timer;

  void on90Deg(Duration deduct) {
    _start = DateTime.now().add(-deduct);
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
      if (onRestart != null) {
        onRestart();
      }
    } else {
      if (onStart != null) {
        onStart();
      }
    }
    var oneTimeAudioPrep = false;
    _timer = new Timer.periodic(Duration(milliseconds: 50), (timer) {
      final passed = DateTime.now().difference(_start);
      if (passed >= TIMER) {
        _timer.cancel();
        _timer = null;
        if (onTimer != null) {
          onTimer();
        }
        return;
      }
      if (!oneTimeAudioPrep && passed >= TIMER - Duration(seconds: 3)) {
        oneTimeAudioPrep = true;
        if (onPrepAudio != null) {
          onPrepAudio();
        }
      }
      if (updateDisplay != null) {
        updateDisplay(passed);
      }
    });
  }
}