import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController  = TextEditingController();
  final _emailController = TextEditingController();

  File?   _pickedImage;
  String? _currentPhotoUrl;
  bool    _loading = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController.text  = user?.displayName ?? '';
    _emailController.text = user?.email ?? '';
    _currentPhotoUrl      = user?.photoURL;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showImageSourceSheet() {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: Color(0xFF2B5BA8)),
              title: const Text('Take a Photo'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 75,
                  maxWidth: 512,
                );
                if (picked != null && mounted) {
                  setState(() => _pickedImage = File(picked.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: Color(0xFF2B5BA8)),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 75,
                  maxWidth: 512,
                );
                if (picked != null && mounted) {
                  setState(() => _pickedImage = File(picked.path));
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadPhoto(String uid) async {
    if (_pickedImage == null) return _currentPhotoUrl;
    final ref = FirebaseStorage.instance.ref('profile_images/$uid.jpg');
    final task = await ref.putFile(
      _pickedImage!,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return task.ref.getDownloadURL();
  }

  Future<void> _saveProfile() async {
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final photoUrl = await _uploadPhoto(user.uid);
        await user.updateDisplayName(_nameController.text.trim());
        if (photoUrl != null) await user.updatePhotoURL(photoUrl);
        await user.reload();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'displayName': _nameController.text.trim(),
          if (photoUrl != null) 'photoUrl': photoUrl,
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildAvatar(String initials) {
    Widget inner;
    if (_pickedImage != null) {
      inner = ClipOval(
        child: Image.file(_pickedImage!,
            width: 110, height: 110, fit: BoxFit.cover),
      );
    } else if (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty) {
      inner = ClipOval(
        child: CachedNetworkImage(
          imageUrl: _currentPhotoUrl!,
          width: 110,
          height: 110,
          fit: BoxFit.cover,
          placeholder: (_, __) => _initialsCircle(initials),
          errorWidget: (_, __, ___) => _initialsCircle(initials),
        ),
      );
    } else {
      inner = _initialsCircle(initials);
    }

    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE8843A),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: inner,
          ),
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF4CAF50),
            ),
            child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _initialsCircle(String initials) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 40,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initials = _nameController.text.isNotEmpty
        ? _nameController.text[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              /// Header
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Icon(Icons.chevron_left,
                          size: 20, color: Colors.black54),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'EDIT PROFILE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),

              const SizedBox(height: 30),

              _buildAvatar(initials),

              const SizedBox(height: 8),
              const Text(
                'Tap photo to change',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),

              const SizedBox(height: 24),

              /// Name Field
              TextField(
                controller: _nameController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle:
                      const TextStyle(color: Color(0xFF1A1A2E)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  prefixIcon: const Icon(Icons.person_outline,
                      color: Color(0xFFE8843A)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              /// Email Field (read-only)
              TextField(
                controller: _emailController,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: Color(0xFFE8843A)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              /// Save Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8843A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
