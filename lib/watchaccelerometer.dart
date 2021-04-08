import 'dart:collection';
import 'dart:developer';
import 'dart:math' hide log;

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';

class MyAccelerometerEvent {
  MyAccelerometerEvent(double x, double y, double z, this.when) :
      vector = Vector3(x, y, z);

  final Vector3 vector;
  final DateTime when;

  double angle(MyAccelerometerEvent other) {
    return vector.angleTo(other.vector);
  }

  int deltaUS(MyAccelerometerEvent other) {
    return when.difference(other.when).inMicroseconds;
  }

  @override
  String toString() => '[MyAccelerometerEvent (x: ${vector.x}, y: ${vector.y}, z: ${vector.z})]';
}

const double deg0error = pi * 15 / 180;
const double deg90min = pi * 75 / 180;

class WatchAccelerometer {
  static const STABLE_EVENTS = 4;
  static const HISTORY = 40;
  Queue<MyAccelerometerEvent> _history = Queue();
  Vector3 _comitted;
  bool _isCommited = false;
  DateTime last90DegAt;

  bool isCommitted() {
    return _isCommited;
  }

  void put(double x, double y, double z) {
    _history.addLast(MyAccelerometerEvent(x, y, z, DateTime.now()));
    while (_history.length > HISTORY) {
      _history.removeFirst();
    }
  }
  
  bool _isStable() { //is last STABLE_EVENTS within a deg0error cone
    final last = _history.last;
    bool isStable = true;
    for (int i = 2; i <= STABLE_EVENTS; i++) {
      if (_history.elementAt(_history.length - i).angle(last) > deg0error) {
        isStable = false;
      }
    }
    return isStable;
  }
  
  Vector3 _stableAverage() { //just sum the stables, as length doesn't matter
    Vector3 result = Vector3(0, 0, 0);
    for (int i = 1; i <= STABLE_EVENTS; i++) {
      final part = _history.elementAt(_history.length - i);
      result += part.vector;
    }
    return result;
  }

  bool got90deg() {
    if (_history.length < STABLE_EVENTS) {
      return false;
    }
    if (!_isStable()) {
      return false;
    }
    final average = _stableAverage();
    if (!_isCommited) {
      _isCommited = true;
      _comitted = average;
      return false;
    }
    if (average.angleTo(_comitted) < deg90min) {
      return false;
    }

    this.last90DegAt = _history.first.when;
    for (int i = 1; i <= _history.length; i++) {
      final element = _history.elementAt(_history.length - i);
      if (element.vector.angleTo(_comitted) < deg0error) {
        this.last90DegAt = element.when;
        break;
      }
    }
    _isCommited = false;
    _history.clear();
    return true;
  }
}