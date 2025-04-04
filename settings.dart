import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(SpamExApp());
}

class SpamExApp extends StatefulWidget {
  @override
  _SpamExAppState createState() => _SpamExAppState();
}

class _SpamExAppState extends State<SpamExApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpamEx',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: SettingsPage(toggleTheme: _toggleTheme),
    );
  }
}

class SettingsPage extends StatefulWidget {
  final Function(bool) toggleTheme;
  SettingsPage({required this.toggleTheme});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  bool isDarkMode = false;
  String spamRingtone = "Default";
  String hamRingtone = "Default";
  String selectedLanguage = "English";
  List<String> ringtones = ["Default", "Ringtone 1", "Ringtone 2", "Ringtone 3"];
  List<String> languages = ["English", "Spanish", "French", "German"];

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() async {
    var androidSettings = const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initializationSettings);
  }

  void _requestPermissions() async {
    var status = await Permission.notification.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      openAppSettings();
    }
  }
  
  void _playRingtone(String ringtoneName) {
    FlutterRingtonePlayer flutterRingtonePlayer = FlutterRingtonePlayer();

    switch (ringtoneName) {
      case "Ringtone 1":
        flutterRingtonePlayer.play(fromAsset: "assets/ringtone1.mp3", looping: false, volume: 0.8);
        break;
      case "Ringtone 2":
        flutterRingtonePlayer.play(fromAsset: "assets/ringtone2.mp3", looping: false, volume: 0.8);
        break;
      case "Ringtone 3":
        flutterRingtonePlayer.play(fromAsset: "assets/ringtone3.mp3", looping: false, volume: 0.8);
        break;
      default:
        flutterRingtonePlayer.playNotification();
        break;
    }
  }

  void _selectRingtone(bool isSpam) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: ringtones.map((ringtone) {
          return ListTile(
            title: Text(ringtone),
            onTap: () {
              setState(() {
                if (isSpam) {
                  spamRingtone = ringtone;
                } else {
                  hamRingtone = ringtone;
                }
              });
              _playRingtone(ringtone);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: Text('Dark Mode'),
            value: isDarkMode,
            onChanged: (bool value) {
              setState(() {
                isDarkMode = value;
                widget.toggleTheme(isDarkMode);
              });
            },
          ),
          ExpansionTile(
            title: Text('Language'),
            children: languages.map((language) {
              return ListTile(
                title: Text(language),
                onTap: () {
                  setState(() {
                    selectedLanguage = language;
                  });
                },
              );
            }).toList(),
          ),
          SwitchListTile(
            title: Text('Allow Notifications'),
            value: notificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                notificationsEnabled = value;
                if (value) _requestPermissions();
              });
            },
          ),
          ListTile(
            title: Text('Spam Message Ringtone'),
            subtitle: Text(spamRingtone),
            onTap: () => _selectRingtone(true),
          ),
          ListTile(
            title: Text('Ham Message Ringtone'),
            subtitle: Text(hamRingtone),
            onTap: () => _selectRingtone(false),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        child: Icon(Icons.support_agent, color: Colors.white),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
            ),
            builder: (context) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Customer Support',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  ListTile(
                    leading: Icon(Icons.phone, color: Colors.green),
                    title: Text('Call Support'),
                    onTap: () {
                      launchUrl(Uri.parse("tel:7032226237"));
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.chat, color: Colors.blue),
                    title: Text('Chat Support'),
                    onTap: () {
                      launchUrl(Uri.parse("https://wa.me/7032226237"));
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.email, color: Colors.orange),
                    title: Text('Email Support'),
                    subtitle: Text('support@spamx.com'),
                    onTap: () {
                      launchUrl(Uri.parse("mailto:support@spamx.com"));
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
