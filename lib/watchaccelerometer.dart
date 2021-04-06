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
  static const MAX_EVENTS = 10;
  static const STABILITY = 3;
  Queue<MyAccelerometerEvent> events = Queue();
  DateTime last90DegAt;

  void put(double x, double y, double z) {
    events.addLast(MyAccelerometerEvent(x, y, z, DateTime.now()));
    while (events.length > MAX_EVENTS) {
      events.removeFirst();
    }
  }

  bool got90deg() {
    if (events.length < MAX_EVENTS) {
      return false;
    }
    final first = events.first;
    final last = events.last;
    // debugPrint('angle ${first.angle(last)} ${DateTime.now()}');
    if (first.angle(last) < deg90min) {
      return false;
    }
    int unstableStart = 0;
    int unstableEnd = 0;
    DateTime when;
    for (int i = 1; i < STABILITY; i++) {
      final start = events.elementAt(i);
      if (start.angle(first) > deg0error) {
        unstableStart += 1;
      }
      final end = events.elementAt(MAX_EVENTS - 1 - i);
      if (end.angle(last) > deg0error) {
        unstableEnd += 1;
      } else {
        when = end.when;
      }
    }
    if (unstableEnd > 1 || unstableStart > 1) {
      return false;
    }
    this.events.clear();
    this.last90DegAt = when;
    return true;
  }
}