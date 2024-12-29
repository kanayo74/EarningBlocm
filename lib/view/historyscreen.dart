import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Activity History'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc('user_id') // Replace with current user ID
              .collection('activities')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error loading data'));
            }

            var activities = snapshot.data!.docs;

            return ListView.builder(
              itemCount: activities.length,
              itemBuilder: (context, index) {
                var activity = activities[index];
                String activityType = activity['activity_type'];
                String status = activity['status'];
                double amount = activity['amount'];
                String timestamp = activity['timestamp'];
                String description = activity['description'];
                String transactionId = activity['transaction_id'];

                // Format date
                var formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(
                    DateTime.parse(timestamp));

                return ListTile(
                  leading: Icon(
                    activityType == 'Withdrawal'
                        ? Icons.account_balance_wallet
                        : activityType == 'Order'
                        ? Icons.shopping_cart
                        : activityType == 'Payment'
                        ? Icons.payment
                        : Icons.history,
                    color: activityType == 'Withdrawal'
                        ? Colors.blue
                        : activityType == 'Order'
                        ? Colors.green
                        : activityType == 'Payment'
                        ? Colors.orange
                        : Colors.grey,
                  ),
                  title: Text(
                    '$activityType - \$${amount.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: $status'),
                      Text('Date: $formattedDate'),
                      if (description.isNotEmpty)
                        Text('Description: $description'),
                    ],
                  ),
                  trailing: Icon(
                    status == 'Pending' ? Icons.pending : Icons.check_circle,
                    color: status == 'Pending' ? Colors.orange : Colors.green,
                  ),
                  onTap: () {
                    // Handle item tap if needed (e.g., navigate to a detail screen)
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
