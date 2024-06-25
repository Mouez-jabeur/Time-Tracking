import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:async';

import 'db_helper.dart';
import 'time_entry.dart';

void main() {
  runApp(TimeTrackingApp());
}

class TimeTrackingApp extends StatefulWidget {
  @override
  _TimeTrackingAppState createState() => _TimeTrackingAppState();
}

class _TimeTrackingAppState extends State<TimeTrackingApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  void _loadThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int themeIndex = prefs.getInt('themeMode') ?? 0;
    setState(() {
      _themeMode = ThemeMode.values[themeIndex];
    });
  }

  void _saveThemeMode(ThemeMode mode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('themeMode', mode.index);
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Tracking App',
      themeMode: _themeMode,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData.dark(),
      home: TimeTrackingHomePage(onThemeChanged: _saveThemeMode),
    );
  }
}

class TimeTrackingHomePage extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  TimeTrackingHomePage({required this.onThemeChanged});

  @override
  _TimeTrackingHomePageState createState() => _TimeTrackingHomePageState();
}

class _TimeTrackingHomePageState extends State<TimeTrackingHomePage> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final DBHelper dbHelper = DBHelper();
  DateTime? _startTime;
  DateTime? _endTime;
  Duration? _duration;
  Timer? _timer;
  TextEditingController _titleController = TextEditingController();
  List<TimeEntry> _timeEntries = [];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadTimeEntries();
  }

  void _initializeNotifications() async {
    final InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    //  iOS: IOSInitializationSettings(),
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _loadTimeEntries() async {
    final entries = await dbHelper.getTimeEntries();
    setState(() {
      _timeEntries = entries;
    });
  }

  void _startTracking() {
    if (_titleController.text.isEmpty || _duration == null) {
      _showErrorDialog('Please enter a valid title and duration.');
      return;
    }

    setState(() {
      _startTime = DateTime.now();
      _endTime = _startTime!.add(_duration!);
      _timeEntries.add(TimeEntry(title: _titleController.text, startTime: _startTime!, endTime: _endTime!, duration: _duration!));
      _timer = Timer(_duration!, _showAlarmDialog);
    });

    dbHelper.insertTimeEntry(TimeEntry(
      title: _titleController.text,
      startTime: _startTime!,
      endTime: _endTime!,
      duration: _duration!,
    ));
  }

  void _showAlarmDialog() {
    flutterLocalNotificationsPlugin.show(
      0,
      'Time\'s Up!',
      'The time for your activity has ended.',
      NotificationDetails(
        android: AndroidNotificationDetails('your channel id', 'your channel name', /*'your channel description'*/ importance: Importance.max, priority: Priority.high),
        //iOS: IOSNotificationDetails(),
      ),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Time\'s Up!'),
        content: Text('The time for your activity has ended.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _stopTracking() {
    if (_startTime != null) {
      setState(() {
        _timer?.cancel();
        _startTime = null;
        _endTime = null;
        _duration = null;
      });
    }
  }

  String _formatDuration(Duration duration) {
    return duration.toString().split('.').first;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDuration() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _duration = Duration(hours: picked.hour, minutes: picked.minute);
      });
    }
  }

  void _changeTheme(ThemeMode themeMode) {
    widget.onThemeChanged(themeMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Time Tracking App'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.light_mode),
              title: Text('Light Theme'),
              onTap: () {
                _changeTheme(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.dark_mode),
              title: Text('Dark Theme'),
              onTap: () {
                _changeTheme(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.system_update),
              title: Text('System Theme'),
              onTap: () {
                _changeTheme(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Activity Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _duration == null
                        ? 'No Duration Selected'
                        : 'Duration: ${_formatDuration(_duration!)}',
                  ),
                ),
                ElevatedButton(
                  onPressed: _pickDuration,
                  child: Text('Pick Duration'),
                ),
              ],
            ),
            SizedBox(height: 20),
            if (_startTime == null)
              ElevatedButton(
                onPressed: _startTracking,
                child: Text('Start Tracking'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            if (_startTime != null)
              ElevatedButton(
                onPressed: _stopTracking,
                child: Text('Stop Tracking'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            SizedBox(height: 20),
            Expanded(
              child: _timeEntries.isEmpty
                  ? Center(child: Text('No entries found.'))
                  : ListView.builder(
                      itemCount: _timeEntries.length,
                      itemBuilder: (context, index) {
                        final entry = _timeEntries[index];
                        return Card(
                          elevation: 4,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(
                              '${entry.title} - Started: ${entry.startTime}',
                              style: TextStyle(fontSize: 16),
                            ),
                            subtitle: Text(
                              'Ended: ${entry.endTime}\nDuration: ${_formatDuration(entry.duration)}',
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
