import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
    [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HSI Assignment 2 Sensor Recorder',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color.fromARGB(222, 255, 9, 214),
      ),
      home: const MyHomePage(title: 'Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  UserAccelerometerEvent? _userAccelerometerEvent;
  GyroscopeEvent? _gyroscopeEvent;

  final _streamSubscriptions = <StreamSubscription<dynamic>>[];

  Duration sensorInterval = SensorInterval.normalInterval;

  bool _isStarted = false;
  List<List<String>> _accelerometerData = [["Time", "Accelerometer_X", " Accelerometer_Y", "Accelerometer_Z"]];
  List<List<String>> _gyroscopeData = [["Time", "Gyroscope_X", "Gyroscope_Y", "Gyroscope_Z"]];

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 20));
    return Scaffold(
      appBar: AppBar(
        title: const Text('HSI Assignment 2 Sensor Recorder'),
        elevation: 4,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(4),
                4: FlexColumnWidth(2),
              },
              children: [
                const TableRow(
                  children: [
                    SizedBox.shrink(),
                    Text('X'),
                    Text('Y'),
                    Text('Z'),
                  ],
                ),
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('User Accelerometer'),
                    ),
                    Text(_userAccelerometerEvent?.x.toStringAsFixed(3) ?? '?'),
                    Text(_userAccelerometerEvent?.y.toStringAsFixed(3) ?? '?'),
                    Text(_userAccelerometerEvent?.z.toStringAsFixed(3) ?? '?'),
                  ],
                ),
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Gyroscope'),
                    ),
                    Text(_gyroscopeEvent?.x.toStringAsFixed(3) ?? '?'),
                    Text(_gyroscopeEvent?.y.toStringAsFixed(3) ?? '?'),
                    Text(_gyroscopeEvent?.z.toStringAsFixed(3) ?? '?'),
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton(
                segments: [
                  ButtonSegment(
                    value: SensorInterval.gameInterval,
                    label: Text('${SensorInterval.gameInterval.inMilliseconds} ms'),
                  ),
                  ButtonSegment(
                    value: SensorInterval.uiInterval,
                    label: Text('${SensorInterval.uiInterval.inMilliseconds} ms'),
                  ),
                  ButtonSegment(
                    value: SensorInterval.normalInterval,
                    label: Text('${SensorInterval.normalInterval.inMilliseconds} ms'),
                  ),
                  const ButtonSegment(
                    value: Duration(milliseconds: 500),
                    label: Text('500 ms'),
                  ),
                  const ButtonSegment(
                    value: Duration(seconds: 1),
                    label: Text('1 s'),
                  ),
                ],
                selected: {sensorInterval},
                showSelectedIcon: false,
                onSelectionChanged: (value) {
                  setState(() {
                    sensorInterval = value.first;
                    userAccelerometerEventStream(
                        samplingPeriod: sensorInterval);
                    gyroscopeEventStream(samplingPeriod: sensorInterval);
                  });
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: style, 
                child: Text(_isStarted ? "Stop" : "Start"),
                onPressed: _isStarted ? () async {save(); setState(() {_isStarted = false;});} 
                : () async {setState(() {_isStarted = true;});},
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }

  @override
  void initState() {
    super.initState();
    _streamSubscriptions.add(
      userAccelerometerEventStream(samplingPeriod: sensorInterval).listen(
        (UserAccelerometerEvent event) {
          final now = DateTime.now();
          setState(() {
            _userAccelerometerEvent = event;
          });
          if (_isStarted) {
            _accelerometerData.add([DateFormat('HH:mm:ss:SS').format(now), _userAccelerometerEvent?.x.toStringAsFixed(5) ?? '?', _userAccelerometerEvent?.y.toStringAsFixed(5) ?? '?', _userAccelerometerEvent?.z.toStringAsFixed(5) ?? '?']);
          }
        },
        onError: (e) {
          showDialog(
              context: context,
              builder: (context) {
                return const AlertDialog(
                  title: Text("Sensor Not Found"),
                  content: Text(
                      "It seems that your device doesn't support User Accelerometer Sensor"),
                );
              });
        },
        cancelOnError: true,
      ),
    );
    _streamSubscriptions.add(
      gyroscopeEventStream(samplingPeriod: sensorInterval).listen(
        (GyroscopeEvent event) {
          final now = DateTime.now();
          setState(() {
            _gyroscopeEvent = event;
          });
          if (_isStarted) {
            _gyroscopeData.add([DateFormat('HH:mm:ss:SS').format(now), _gyroscopeEvent?.x.toStringAsFixed(5) ?? '?', _gyroscopeEvent?.y.toStringAsFixed(5) ?? '?', _gyroscopeEvent?.z.toStringAsFixed(5) ?? '?']);
          }
        },
        onError: (e) {
          showDialog(
              context: context,
              builder: (context) {
                return const AlertDialog(
                  title: Text("Sensor Not Found"),
                  content: Text(
                      "It seems that your device doesn't support Gyroscope Sensor"),
                );
              });
        },
        cancelOnError: true,
      ),
    );
  }
  
  void save() async {
    final String directory = (await getApplicationDocumentsDirectory()).path;
    final accelerometerPath = "$directory/accelerometer.csv";
    String csvAccelerometerData = ListToCsvConverter().convert(_accelerometerData);
    final File accelerometerFile = File(accelerometerPath);
    await accelerometerFile.writeAsString(csvAccelerometerData);
    final gyroscopePath = "$directory/gyroscope.csv";
    String csvGyroscopeData = ListToCsvConverter().convert(_gyroscopeData);
    final File gyroscopeFile = File(gyroscopePath);
    await gyroscopeFile.writeAsString(csvGyroscopeData);
  }
}