import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'Native_splash/SplashScreen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  MobileAds.instance.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationManager()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CombinedSplashScreen(),
    );
  }
}

class NotificationManager with ChangeNotifier {
  int _notificationCount = 0;

  int get notificationCount => _notificationCount;

  Future<void> fetchNotifications() async {
    final snapshot = await FirebaseFirestore.instance.collection('notifications').get();
    _notificationCount = snapshot.docs.length;
    notifyListeners();
  }
}
