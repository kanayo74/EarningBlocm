import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdPage extends StatefulWidget {
  final String userId;
  const AdPage({Key? key, required this.userId}) : super(key: key);

  @override
  _AdPageState createState() => _AdPageState();
}

class _AdPageState extends State<AdPage> {
  late RewardedAd _rewardedAd1;
  late RewardedAd _rewardedAd2;
  late RewardedAd _rewardedAd3;
  late RewardedAd _rewardedAd4;
  late RewardedAd _rewardedAd5;

  bool _isAd1Loaded = false;
  bool _isAd2Loaded = false;
  bool _isAd3Loaded = false;
  bool _isAd4Loaded = false;
  bool _isAd5Loaded = false;

  bool _hasEarned = false;
  double _earnings = 0.0;

  late String userId;
 @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser!.uid;
    _loadRewardedAd1();
    _loadRewardedAd2();
    _loadRewardedAd3();
    _loadRewardedAd4();
    _loadRewardedAd5();
    _fetchEarnings();
    _checkIfEarned();
  }
 void _loadRewardedAd1() {
    RewardedAd.load(
      adUnitId: 'YOUR_AD_UNIT_ID_1',
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedAd1 = ad;
            _isAd1Loaded = true;
          });
        },
        onAdFailedToLoad: (error) {
          print('Failed to load ad 1: $error');
        },
      ),
    );
  }
 void _loadRewardedAd2() {
    RewardedAd.load(
      adUnitId: 'YOUR_AD_UNIT_ID_2',
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedAd2 = ad;
            _isAd2Loaded = true;
          });
        },
        onAdFailedToLoad: (error) {
          print('Failed to load ad 2: $error');
        },
      ),
    );
  }
 void _loadRewardedAd3() {
    RewardedAd.load(
      adUnitId: 'YOUR_AD_UNIT_ID_3',
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedAd3 = ad;
            _isAd3Loaded = true;
          });
        },
        onAdFailedToLoad: (error) {
          print('Failed to load ad 3: $error');
        },
      ),
    );
  }
 void _loadRewardedAd4() {
    RewardedAd.load(
      adUnitId: 'YOUR_AD_UNIT_ID_4',
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedAd4 = ad;
            _isAd4Loaded = true;
          });
        },
        onAdFailedToLoad: (error) {
          print('Failed to load ad 4: $error');
        },
      ),
    );
  }

  void _loadRewardedAd5() {
    RewardedAd.load(
      adUnitId: 'YOUR_AD_UNIT_ID_5',
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedAd5 = ad;
            _isAd5Loaded = true;
          });
        },
        onAdFailedToLoad: (error) {
          print('Failed to load ad 5: $error');
        },
      ),
    );
  }
 void _fetchEarnings() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      setState(() {
        _earnings = (userDoc['earnings'] ?? 0.0) as double;
      });
    }
  }
 void _checkIfEarned() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      setState(() {
        _hasEarned = userDoc['hasEarned'] ?? false;
      });
    }
  }
 void _showRewardedAd(RewardedAd ad, bool isAdLoaded) {
    if (isAdLoaded && !_hasEarned) {
      ad.show(onUserEarnedReward: (ad, reward) {
        _updateUserEarnings();
      });
    } else {
      print('Ad is not loaded or user already earned');
    }
  }
 void _updateUserEarnings() async {
    try {
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
      await userDoc.update({
        'earnings': FieldValue.increment(0.02),
        'hasEarned': true,
      });
      setState(() {
        _earnings += 0.02;
        _hasEarned = true;
      });
      print("User earnings updated!");
    } catch (e) {
      print("Error updating earnings: $e");
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (_isAd1Loaded) _rewardedAd1.dispose();
    if (_isAd2Loaded) _rewardedAd2.dispose();
    if (_isAd3Loaded) _rewardedAd3.dispose();
    if (_isAd4Loaded) _rewardedAd4.dispose();
    if (_isAd5Loaded) _rewardedAd5.dispose();
  }
 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("AdPage"),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                "\$${_earnings.toStringAsFixed(2)}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _showRewardedAd(_rewardedAd1, _isAd1Loaded),
              child: Text("Watch Ad 1 and Earn"),
            ),
            ElevatedButton(
              onPressed: () => _showRewardedAd(_rewardedAd2, _isAd2Loaded),
              child: Text("Watch Ad 2 and Earn"),
            ),
            ElevatedButton(
              onPressed: () => _showRewardedAd(_rewardedAd3, _isAd3Loaded),
              child: Text("Watch Ad 3 and Earn"),
            ),
            ElevatedButton(
              onPressed: () => _showRewardedAd(_rewardedAd4, _isAd4Loaded),
              child: Text("Watch Ad 4 and Earn"),
            ),
            ElevatedButton(
              onPressed: () => _showRewardedAd(_rewardedAd5, _isAd5Loaded),
              child: Text("Watch Ad 5 and Earn"),
            ),
            if (!_isAd1Loaded || !_isAd2Loaded || !_isAd3Loaded || !_isAd4Loaded || !_isAd5Loaded)
              CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
