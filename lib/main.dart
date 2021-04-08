import 'dart:async';

import 'package:buzzer/buzzerstatemachine.dart';
import 'package:buzzer/watchaccelerometer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';
import 'package:wakelock/wakelock.dart';
import 'package:sensors/sensors.dart';
import 'package:vibration/vibration.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark(),//(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
      //   brightness: ThemeData.dark(),
      //   primarySwatch: Colors.blue,
      //   canvasColor: Colors.black,
      // ),
      home: MyHomePage(title: 'Buzzer'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _milliseconds = 0;
  int _events = 0;
  bool _isCommitted = false;
  WatchAccelerometer _watchAccelerometer = WatchAccelerometer();
  BuzzerStateMachine _stateMachine = BuzzerStateMachine();
  List<StreamSubscription<dynamic>> _streamSubscriptions =
  <StreamSubscription<dynamic>>[];

  Soundpool _soundPool = Soundpool(streamType: StreamType.music);
  Future<int> _beepSoundId;
  Future<int> _silenceSoundId;

  void _loadSound() async {
    var asset = await rootBundle.load("sounds/beep.wav");
    _beepSoundId = _soundPool.load(asset);
    var asset2 = await rootBundle.load("sounds/silence.wav");
    _silenceSoundId = _soundPool.load(asset2);
  }

  Future<void> _playSound() async {
    var soundId = await _beepSoundId;
    await _soundPool.play(soundId);
  }
  Future<void> _playSilenceToWarmUpAudioLatency() async {
    var soundId = await _silenceSoundId;
    await _soundPool.play(soundId);
  }

  // void countTime(Duration deduct) async {
  //   final sleepTime = Duration(microseconds:(Duration(seconds: 34).inMicroseconds - deduct.inMicroseconds));
  //   new Future.delayed(Duration(seconds:30), (){
  //     _playSilenceToWarmUp();
  //   });
  //   await new Future.delayed(sleepTime, (){
  //     Vibration.vibrate(duration: 1000);
  //     _playSound();
  //   });
  // }

  @override
  void initState() {
    super.initState();
    _loadSound();
    _stateMachine.onStart = () {
      Vibration.vibrate(duration: 1000);
    };
    _stateMachine.onRestart = () {
      Vibration.vibrate(duration: 1000);
    };
    _stateMachine.onPrepAudio = () {
      _playSilenceToWarmUpAudioLatency();
    };
    _stateMachine.onTimer = () {
      Vibration.vibrate(duration: 1000);
      _playSound();
    };
    _stateMachine.updateDisplay = (Duration passed) {
      setState(() {
        _milliseconds = passed.inMilliseconds;
      });
    };
    SystemChrome.setEnabledSystemUIOverlays([]);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => Wakelock.enable());
    _streamSubscriptions
       .add(accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        _watchAccelerometer.put(event.x, event.y, event.z);
        if (_watchAccelerometer.got90deg()) {
          final eventLatency = DateTime.now().difference(_watchAccelerometer.last90DegAt);
          _stateMachine.on90Deg(eventLatency);
        }
        _isCommitted = _watchAccelerometer.isCommitted();
        _events += 1;
      });
    }));
  }

  @override
  void dispose() {
    super.dispose();
    for (StreamSubscription<dynamic> subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }

  // void _incrementCounter() {
  //   Vibration.vibrate(duration: 1000);
  //   setState(() {
  //     // This call to setState tells the Flutter framework that something has
  //     // changed in this State, which causes it to rerun the build method below
  //     // so that the display can reflect the updated values. If we changed
  //     // _counter without calling setState(), then the build method would not be
  //     // called again, and so nothing would appear to happen.
  //     _counter++;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '$_events ${_isCommitted ? "Y" : "N"}',
              // _accelerometerValues.length > 0 ? (
              // '$_accelerometerValues') : ("No data")
            ),
            Text(
              '${(_milliseconds / 1000.0).toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: Icon(Icons.add),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
