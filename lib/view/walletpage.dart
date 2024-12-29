import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WalletPage(userId: 'mockUserId123'), // Replace with a real user ID
    );
  }
}

class WalletPage extends StatelessWidget {
  final String userId;

  WalletPage({required this.userId});

  final TextEditingController amountController = TextEditingController();
  final TextEditingController pinController = TextEditingController();

  Future<void> handleWithdraw(BuildContext context) async {
    double withdrawAmount = double.tryParse(amountController.text) ?? 0.0;

    // Fetch user data from Firestore
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final userData = userDoc.data();
    if (userData == null) return;

    double currentBalance = userData['walletBalance'] ?? 0.0;

    // Check for sufficient balance
    if (withdrawAmount <= 0 || withdrawAmount > currentBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Insufficient balance or invalid amount')),
      );
      return;
    }

    // Show PIN prompt
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter PIN'),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'PIN'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (pinController.text == userData['pin']) {
                // Update Firestore
                await FirebaseFirestore.instance.collection('users').doc(userId).update({
                  'walletBalance': currentBalance - withdrawAmount,
                });

                // Log transaction
                await FirebaseFirestore.instance.collection('transactions').add({
                  'userId': userId,
                  'type': 'Withdraw',
                  'amount': withdrawAmount,
                  'timestamp': FieldValue.serverTimestamp(),
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Withdrawal successful')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Invalid PIN')),
                );
              }
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text('Wallet'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          if (userData == null) return Center(child: Text('No data available'));

          double walletBalance = userData['walletBalance'] ?? 0.0;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                Text(
                  userData['name'] ?? '',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Text(
                  'Available Balance',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                Text(
                  '\$${walletBalance.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () => handleWithdraw(context),
                  icon: Icon(Icons.money, color: Colors.white),
                  label: Text('Withdraw'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  ),
                ),
                SizedBox(height: 30),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('transactions')
                        .where('userId', isEqualTo: userId)
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, transactionSnapshot) {
                      if (!transactionSnapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final transactions = transactionSnapshot.data!.docs;

                      return ListView.builder(
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index].data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text(transaction['type']),
                            subtitle: Text('\$${transaction['amount']}'),
                            trailing: Text(transaction['timestamp']?.toDate().toString() ?? ''),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
