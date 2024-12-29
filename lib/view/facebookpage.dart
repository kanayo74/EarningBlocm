import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class FacebookVideoPage extends StatefulWidget {
  final String userId;

  const FacebookVideoPage({Key? key, required this.userId}) : super(key: key);

  @override
  _FacebookVideoPageState createState() => _FacebookVideoPageState();
}

class _FacebookVideoPageState extends State<FacebookVideoPage> {
  final String facebookLink = "https://www.facebook.com/share/r/15TrWeiBSg/?mibextid=2Xzr3SNpE5dFVwDb";
  final String facebookPageLink = "https://www.facebook.com/yourPage"; // Link to your Facebook page
  double userEarnings = 0.0;
  bool hasEarned = false;
  bool hasFollowed = false;
  bool hasCommented = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchUserEarnings(); // Fetch the user's earnings when the page loads
    _checkIfUserHasEarned(); // Check if the user has already earned
  }

  Future<void> _fetchUserEarnings() async {
    try {
      final userDoc = await _firestore.collection('users').doc(widget.userId).get();
      final currentEarnings = userDoc.data()?['earnings'] ?? 0.0;

      setState(() {
        userEarnings = currentEarnings;
      });
    } catch (e) {
      print("Error fetching user earnings: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error fetching your earnings.")),
      );
    }
  }

  Future<void> _checkIfUserHasEarned() async {
    try {
      final querySnapshot = await _firestore
          .collection("userActivities")
          .where("userId", isEqualTo: widget.userId)
          .where("facebookLink", isEqualTo: facebookLink)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          hasEarned = true;
        });
      }
    } catch (e) {
      print("Error checking earnings: $e");
    }
  }

  Future<void> _earnReward() async {
    if (hasEarned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You have already earned from this video.")),
      );
      return;
    }

    if (!hasFollowed || !hasCommented) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please follow the Facebook page and comment first.")),
      );
      return;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(widget.userId).get();
      final currentEarnings = userDoc.data()?['earnings'] ?? 0.0;

      await _firestore.collection('users').doc(widget.userId).update({
        'earnings': currentEarnings + 0.02,
      });

      await _firestore.collection("userActivities").add({
        "userId": widget.userId,
        "facebookLink": facebookLink,
        "earned": 0.02,
        "timestamp": FieldValue.serverTimestamp(),
      });

      setState(() {
        userEarnings = currentEarnings + 0.02;
        hasEarned = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You've earned 2 cents!")),
      );
    } catch (e) {
      print("Error updating earnings: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error updating earnings.")),
      );
    }
  }

  Future<void> _launchFacebookLink() async {
    if (await canLaunch(facebookLink)) {
      await launch(facebookLink);
    } else {
      throw 'Could not launch $facebookLink';
    }
  }

  Future<void> _launchFacebookPage() async {
    if (await canLaunch(facebookPageLink)) {
      await launch(facebookPageLink);
    } else {
      throw 'Could not launch $facebookPageLink';
    }
  }

  Widget _buildTaskButton(String title, bool isComplete, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: isComplete ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isComplete ? Colors.grey : Colors.green,
      ),
      child: Text(isComplete ? "Completed" : title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Facebook Earn"),
        backgroundColor: Colors.indigo,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Wallet Section
            Container(
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 6,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    "Your Wallet",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "\$${userEarnings.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Facebook Video Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 6,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    "Watch & Earn!",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _launchFacebookLink,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: const Text("Watch Video"),
                  ),
                  const SizedBox(height: 20),
                  // Button to follow the Facebook page
                  _buildTaskButton("Follow on Facebook", hasFollowed, () {
                    setState(() {
                      hasFollowed = true;
                    });
                    _launchFacebookPage();
                  }),
                  const SizedBox(height: 20),
                  // Button to comment on the video
                  _buildTaskButton("Comment on Facebook", hasCommented, () {
                    setState(() {
                      hasCommented = true;
                    });
                    launch("https://facebook.com"); // Open Facebook comment section
                  }),
                  const SizedBox(height: 20),
                  _buildTaskButton("Earn Reward", hasEarned, _earnReward),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: hasEarned ? 1.0 : 0.0,
                    backgroundColor: Colors.grey[300],
                    color: Colors.green,
                    minHeight: 6,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
