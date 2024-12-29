  import 'package:earnblock/view/walletpage.dart';
  import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:google_mobile_ads/google_mobile_ads.dart';
  import 'package:provider/provider.dart';
  import '../main.dart';
  import 'adpage.dart';
  import 'youtube.dart';
  import 'facebookpage.dart';
  import 'profilepage.dart';
  import 'historyscreen.dart';
  import 'LeaderboardScreen.dart';

  class HomePage extends StatefulWidget {
    const HomePage({Key? key}) : super(key: key);

    @override
    _HomePageState createState() => _HomePageState();
  }

  class _HomePageState extends State<HomePage> {
    int _currentIndex = 0;
    String? username;
    double earnings = 0.0;
    BannerAd? _bannerAd;
    bool _isAdLoaded = false;

    @override
    void initState() {
      super.initState();
      context.read<NotificationManager>().fetchNotifications();
      fetchUserData();
      initializeBannerAd();
    }

    Future<void> fetchUserData() async {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          print('No user is currently logged in.');
          return;
        }

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            username = userDoc.data()?['username'] ?? 'User';
            earnings = userDoc.data()?['earnings']?.toDouble() ?? 0.0;
          });
        } else {
          print('User document does not exist in Firestore.');
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }

    void initializeBannerAd() {
      _bannerAd = BannerAd(
        adUnitId: 'ca-app-pub-6155738035406540/2423774970', // Replace with your AdMob ad unit ID
        size: AdSize.banner,
        request: AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            setState(() => _isAdLoaded = true);
          },
          onAdFailedToLoad: (ad, error) {
            print('Ad failed to load: $error');
            ad.dispose();
          },
        ),
      )..load();
    }

    @override
    void dispose() {
      _bannerAd?.dispose();
      super.dispose();
    }

    String getCurrentTime() {
      return DateTime.now().toIso8601String().split('T').first;
    }

    Future<void> handleDailyClaim() async {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userDocRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

      try {
        final userDoc = await userDocRef.get();
        final lastClaimTimestamp = userDoc.data()?['lastClaim']?.toDate();
        final currentTime = DateTime.now();

        if (lastClaimTimestamp != null && currentTime.difference(lastClaimTimestamp).inHours < 24) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("You can claim again after 24 hours.")),
          );
          return;
        }

        // Update earnings and last claim time
        await userDocRef.update({
          'earnings': FieldValue.increment(0.05),
          'lastClaim': currentTime,
        });

        setState(() {
          earnings += 0.05;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You claimed \$0.05!")),
        );
      } catch (e) {
        print("Error handling daily claim: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred. Please try again later.")),
        );
      }
    }

    @override
    Widget build(BuildContext context) {
      final notificationManager = context.watch<NotificationManager>();

      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          elevation: 3,
          title: Row(
            children: [
              Icon(Icons.home, color: Colors.white),
              SizedBox(width: 8),
              Text(
                "Home",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications, color: Colors.white),
                  onPressed: () {},
                ),
                if (notificationManager.notificationCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${notificationManager.notificationCount}',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.deepPurple, Colors.purpleAccent]),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hi, ${username ?? 'Loading...'}!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Today's: ${getCurrentTime()}",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Earnings: \$${earnings.toStringAsFixed(2)}",
                    style: TextStyle(color: Colors.lightGreenAccent, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  homeTaskItem(
                    icon: Icons.play_circle_fill,
                    title: "Ads Page",
                    description: "Earn rewards by watching ads.",
                    onTap: () => navigateTo(AdPage(userId: FirebaseAuth.instance.currentUser!.uid)),
                  ),
                  homeTaskItem(
                    icon: Icons.video_library,
                    title: "Watch YouTube",
                    description: "Earn by watching YouTube videos.",
                    onTap: () => navigateTo(YouTubePage(userId: FirebaseAuth.instance.currentUser!.uid)),
                  ),
                  homeTaskItem(
                    icon: Icons.facebook,
                    title: "Watch Facebook Video",
                    description: "Earn by watching Facebook videos.",
                    onTap: () => navigateTo(FacebookVideoPage(userId: FirebaseAuth.instance.currentUser!.uid)),
                  ),
                  homeTaskItem(
                    icon: Icons.attach_money,
                    title: "Daily Claims",
                    description: "Claim your daily rewards here.",
                    onTap: handleDailyClaim,
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isAdLoaded)
              Container(
                height: _bannerAd!.size.height.toDouble(),
                width: MediaQuery.of(context).size.width, // Make it span the screen width
                child: AdWidget(ad: _bannerAd!),
              )
            else
              Container(
                height: 50, // Placeholder height for ads
                alignment: Alignment.center,
                child: Text(
                  "Loading Ad...",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex,
              backgroundColor: Colors.deepPurple,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white70,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
                BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Wallet"),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
                BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
                BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: "Leaderboard"),
              ],
              onTap: (index) {
                setState(() => _currentIndex = index);
                switch (index) {
                  case 1:
                    navigateTo(WalletPage(userId: 'userId: FirebaseAuth.instance.currentUser!.uid',));
                    break;
                  case 2:
                    navigateTo(ProfilePage());
                    break;
                  case 3:
                    navigateTo(HistoryPage());
                    break;
                  case 4:
                    navigateTo(LeaderboardScreen());
                    break;
                }
              },
            ),
          ],
        ),

      );
    }

    void navigateTo(Widget page) {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => page));
    }

    Widget homeTaskItem({IconData? icon, required String title, required String description, required VoidCallback onTap}) {
      return GestureDetector(
        onTap: onTap,
        child: Card(
          color: Colors.white,
          margin: EdgeInsets.symmetric(vertical: 8),
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.deepPurple, size: 32),
            ),
            title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(description),
            trailing: Icon(Icons.arrow_forward_ios, size: 20, color: Colors.grey),
          ),
        ),
      );
    }
  }
