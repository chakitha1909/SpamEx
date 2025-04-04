import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ManageProfilesScreen extends StatefulWidget {
  const ManageProfilesScreen({Key? key}) : super(key: key);

  @override
  _ManageProfilesScreenState createState() => _ManageProfilesScreenState();
}

class _ManageProfilesScreenState extends State<ManageProfilesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? _selectedProfilePic;
  File? _selectedImageFile;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _altEmailController = TextEditingController();

  bool _isEditingName = false;
  bool _isEditingPhone = false;
  bool _isEditingEmail = false;

  @override
  void initState() {
    super.initState();
    createUserDocumentIfNotExists();
    _loadUserData();
  }

  Future<void> createUserDocumentIfNotExists() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentReference userRef = _firestore.collection('users').doc(user.uid);
      DocumentSnapshot userDoc = await userRef.get();
      if (!userDoc.exists) {
        await userRef.set({
          'displayName': user.displayName ?? '',
          'phone': '',
          'altEmail': '',
          'photoURL': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  Future<void> _changeProfilePic(BuildContext context) async {
    final ImagePicker _picker = ImagePicker();
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Uploading..."),
          ],
        ),
      ),
    );

    try {
      String fileName = "${_auth.currentUser!.uid}_profile.jpg";
      Reference ref = _storage.ref().child('profile_pics/$fileName');

      // Compress Image Before Uploading
      final File? compressedImage = await _compressImage(imageFile);
      if (compressedImage != null) {
        imageFile = compressedImage;
      }

      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      // Get Download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Update Firestore with new photo URL
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'photoURL': downloadUrl,
      });

      setState(() {
        _selectedProfilePic = downloadUrl;
        _selectedImageFile = imageFile;
      });

      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profile picture updated successfully!")),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if error occurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading image: ${e.toString()}")),
      );
    }
  }

  Future<File?> _compressImage(File file) async {
    final String targetPath = file.path + "_compressed.jpg";
    final XFile? result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 60, // Adjust quality (60% reduces file size while keeping good quality)
    );
    return result != null ? File(result.path) : null;
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _nameController.text = data['displayName'] ?? user.displayName ?? "User";
            _phoneController.text = data['phone'] ?? "";
            _altEmailController.text = data['altEmail'] ?? "";
            _selectedProfilePic = data['photoURL'] ?? "";
          });
        }
      } catch (e) {
        print("Error loading user data: $e");
      }
    }
  }

  Future<void> _saveProfileChanges() async {
    User? user = _auth.currentUser;
    if (user != null) {
      Map<String, dynamic> updatedData = {};

      if (_nameController.text.trim().isNotEmpty) {
        updatedData['displayName'] = _nameController.text.trim();
      }
      if (_phoneController.text.trim().isNotEmpty) {
        updatedData['phone'] = _phoneController.text.trim();
      }
      if (_altEmailController.text.trim().isNotEmpty) {
        updatedData['altEmail'] = _altEmailController.text.trim();
      }

      if (updatedData.isNotEmpty) {
        try {
          await _firestore.collection('users').doc(user.uid).update(updatedData);
          await _loadUserData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile updated successfully")),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to update profile: $e")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No changes detected")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _changeProfilePic(context),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _selectedImageFile != null
                        ? FileImage(_selectedImageFile!)
                        : (_selectedProfilePic != null && _selectedProfilePic!.isNotEmpty
                            ? NetworkImage(_selectedProfilePic!)
                            : null) as ImageProvider<Object>?,
                    child: (_selectedProfilePic == null || _selectedProfilePic!.isEmpty) &&
                            _selectedImageFile == null
                        ? const Icon(Icons.camera_alt, size: 40, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildEditableField("Name", _nameController, _isEditingName, () {
              setState(() => _isEditingName = !_isEditingName);
            }),
            _buildEditableField("Phone Number", _phoneController, _isEditingPhone, () {
              setState(() => _isEditingPhone = !_isEditingPhone);
            }),
            _buildEditableField("Alternative Email", _altEmailController, _isEditingEmail, () {
              setState(() => _isEditingEmail = !_isEditingEmail);
            }),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveProfileChanges, child: const Text("Save Changes")),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, bool isEditing, VoidCallback toggleEditing) {
    return TextField(controller: controller, decoration: InputDecoration(labelText: label));
  }
}
