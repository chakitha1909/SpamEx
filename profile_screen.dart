import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'faq.dart';
import 'settings.dart';
import 'home_screen.dart';
import 'manage_profiles.dart'; // New screen for managing multiple accounts

class ProfileScreen extends StatefulWidget {
  final VoidCallback onClose;
  final Function(bool) toggleTheme;

  const ProfileScreen({Key? key, required this.onClose, required this.toggleTheme}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _name = "User";
  String _email = "No email";
  String? _selectedProfilePic;

 @override
void initState() {
  super.initState();
  _loadUserData();
  _listenToUserUpdates();
}

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  _loadUserData(); 
  _listenToUserUpdates();// Reload when returning to the screen
}


Future<void> _loadUserData() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (userDoc.exists) {
      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
      setState(() {
        _selectedProfilePic = data['photoURL'] ?? ""; // Fetch the image URL
      });
    }
  }
}


void _listenToUserUpdates() {
  User? user = _auth.currentUser;
  if (user != null) {
    _firestore.collection('users').doc(user.uid).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

        print("🔄 Firestore Update Detected: $data"); // Debugging Log

        setState(() {
          _name = data['displayName'] ?? "User";
          _email = user.email ?? "No email";
          _selectedProfilePic = data['photoURL'] ?? ""; // Use _selectedProfilePic instead
        });
      }
    });
  }
}



  @override
  Widget build(BuildContext context) {
    String avatarLetter = _name.isNotEmpty ? _name[0].toUpperCase() : "?";

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onClose,
              ),
            ),

            // Updated Profile Picture
            CircleAvatar(
  radius: 50,
  backgroundColor: Colors.grey[300],
  backgroundImage: _selectedProfilePic != null && _selectedProfilePic!.isNotEmpty
      ? NetworkImage(_selectedProfilePic!) as ImageProvider
      : null,
  child: (_selectedProfilePic == null || _selectedProfilePic!.isEmpty)
      ? Text(
          avatarLetter,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        )
      : null,
),


            const SizedBox(height: 12),

            // Updated Name & Email
            Text(_name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(_email, style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 16),

            // Navigation options
           _buildOption(context, Icons.person_outline, "Manage Profiles", () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageProfilesScreen()),
              );
              _loadUserData(); // Reload after returning
            }),
            _buildOption(context, Icons.help_outline, "FAQ", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FAQScreen()));
            }),
            _buildOption(context, Icons.settings, "Settings", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage(toggleTheme: widget.toggleTheme)));
            }),

            const Divider(),

            _buildOption(context, Icons.logout, "Sign Out", () => _signOut(context), isSignOut: true),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, IconData icon, String text, VoidCallback onTap, {bool isSignOut = false}) {
    return ListTile(
      leading: Icon(icon, color: isSignOut ? Colors.red : Colors.black),
      title: Text(
        text,
        style: TextStyle(color: isSignOut ? Colors.red : Colors.black),
      ),
      onTap: onTap,
    );
  }

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }
}
