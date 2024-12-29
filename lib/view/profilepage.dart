import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String userId = '';
  String username = 'Unknown';
  String email = 'Loading...';
  String phoneNumber = 'Unknown';
  String accountNumber = '';
  String accountName = '';
  String cryptoWalletAddress = '';
  double walletBalance = 0.0;

  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _cryptoWalletController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initializeUser();
  }

  Future<void> initializeUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
      await fetchUserData();
    }
  }

  Future<void> fetchUserData() async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          setState(() {
            username = data['username'] ?? 'Unknown';
            email = data['email'] ?? 'Unknown';
            phoneNumber = data['phone'] ?? 'Unknown';
            accountNumber = data['accountNumber'] ?? '';
            accountName = data['accountName'] ?? '';
            cryptoWalletAddress = data['cryptoWalletAddress'] ?? '';
            walletBalance = (data['walletBalance'] ?? 0).toDouble();

            // Update text controllers
            _accountNumberController.text = accountNumber;
            _accountNameController.text = accountName;
            _phoneNumberController.text = phoneNumber;
            _cryptoWalletController.text = cryptoWalletAddress;
          });
        }
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile data: $error')),
      );
    }
  }

  Future<void> updateProfile() async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);

      if (_accountNumberController.text.length != 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account number must be 10 digits')),
        );
        return;
      }

      await userDoc.update({
        'accountNumber': _accountNumberController.text,
        'accountName': _accountNameController.text,
        'phone': _phoneNumberController.text,
      });

      setState(() {
        accountNumber = _accountNumberController.text;
        accountName = _accountNameController.text;
        phoneNumber = _phoneNumberController.text;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Box
            _buildInfoBox(
              title: 'User Information',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRow('Username:', username),
                  _buildRow('Email:', email),
                  _buildRow('Phone Number:', phoneNumber),
                  _buildRow('Account Number:', accountNumber),
                  _buildRow('Account Name:', accountName),
                  _buildRow('Wallet Balance:', '₦${walletBalance.toStringAsFixed(2)}'),
                  _buildRow('Crypto Wallet Address:', cryptoWalletAddress.isEmpty ? 'Not Set' : cryptoWalletAddress),
                ],
              ),
              color: Colors.blue.shade50,
            ),
            const SizedBox(height: 20),

            // Bank Details Section
            ExpansionTile(
              title: Text('Bank Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              children: [
                _buildEditableField('Account Number:', _accountNumberController),
                _buildEditableField('Account Name:', _accountNameController),
                _buildEditableField('Phone Number:', _phoneNumberController),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: updateProfile,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: Text('Update Profile'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox({
    required String title,
    required Widget content,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade400,
            offset: const Offset(2, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }

  Widget _buildRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            key,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
        ),
      ),
    );
  }
}
