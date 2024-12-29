import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class YouTubePage extends StatefulWidget {
  final String userId;
  const YouTubePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<YouTubePage> createState() => _YouTubePageState();
}

class _YouTubePageState extends State<YouTubePage> {
  late YoutubePlayerController _controller;
  double earnings = 0.0;
  double taskProgress = 0.0;
  bool hasWatched = false, hasCommented = false, hasSubscribed = false, earned = false;
  final String videoId = "aiOXdQINzqU";

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
    );
    _fetchRealTimeEarnings();
  }

  void _fetchRealTimeEarnings() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        setState(() {
          earnings = doc.data()?['earnings'] ?? 0.0;
          earned = (doc.data()?['linksWatched'] ?? []).contains(videoId);
        });
      }
    });
  }

  Future<void> _completeTask() async {
    if (hasWatched && hasCommented && hasSubscribed && !earned) {
      setState(() {
        earned = true;
        earnings += 0.02; // Earn 2 cents
        taskProgress = 1.0; // Task complete
      });

      try {
        await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
          'earnings': earnings,
          'linksWatched': FieldValue.arrayUnion([videoId]),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task completed! \$0.02 added to your earnings.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error completing task.')),
        );
      }
    } else if (earned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already earned from this video.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all tasks before earning.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('YouTube Tasks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () {
              // Navigate to Wallet Page
              Navigator.pushNamed(context, '/wallet', arguments: {'userId': widget.userId});
            },
          ),
          GestureDetector(
            onTap: () {
              // Navigate to detailed earnings
              Navigator.pushNamed(context, '/earnings', arguments: {'userId': widget.userId});
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  '\$${earnings.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF232526), Color(0xFF414345)], // AI-inspired gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: YoutubePlayer(
                  controller: _controller,
                  showVideoProgressIndicator: true,
                  onEnded: (_) => setState(() => hasWatched = true),
                ),
              ),
              const SizedBox(height: 20),
              _buildTaskButton('Comment on Facebook', hasCommented, () {
                setState(() => hasCommented = true);
                launch("https://facebook.com");
              }),
              _buildTaskButton('Subscribe to Channel', hasSubscribed, () => setState(() => hasSubscribed = true)),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: taskProgress,
                backgroundColor: Colors.grey[300],
                color: Colors.green,
                minHeight: 6,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _completeTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Complete Task & Earn',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskButton(String label, bool completed, VoidCallback onPressed) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: completed ? Colors.green[100] : Colors.grey[200],
      child: ListTile(
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: completed ? Colors.green : Colors.black87,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            completed ? Icons.check_circle : Icons.circle_outlined,
            color: completed ? Colors.green : Colors.grey,
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
