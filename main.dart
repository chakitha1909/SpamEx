import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/inbox_screen.dart';
import 'screens/home_screen.dart';
import 'screens/main_screen.dart'; // Import MainScreen
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SpamEx',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isFirstLaunch = true;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print("Notification permission granted");
  } else {
    print("Notification permission denied");
  }
}


  Future<void> _checkFirstLaunch() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

  if (isFirstLaunch) {
    await prefs.setBool('isFirstLaunch', false);
  }

  await _requestNotificationPermission(); // Request notification permission

  FirebaseMessaging.onMessage.listen(_onMessageReceived); // Listen for messages

  setState(() {
    _isFirstLaunch = isFirstLaunch;
  });
}

  void _onMessageReceived(RemoteMessage message) {
  if (message.notification != null) {
    print('New Message: ${message.notification!.title} - ${message.notification!.body}');
    // You can show a snackbar or a local notification here
  }
}

  @override
  Widget build(BuildContext context) {
    if (_isFirstLaunch) {
      return const MainScreen(); // Show Get Started screen on first launch
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const InboxScreen();
        } else {
          return const HomeScreen();
        }
      },
    );
  }
}
