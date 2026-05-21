import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _titleController       = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController        = TextEditingController();
  final _timeController        = TextEditingController();
  final _dateController        = TextEditingController();
  final _priceController       = TextEditingController();
  final _locationController    = TextEditingController();
  final _conditionController   = TextEditingController();

  File? _pickedImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _timeController.dispose();
    _dateController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _conditionController.dispose();
    super.dispose();
  }
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1024,
    );
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  void _showImageSourceDialog() {
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
              leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF2B5BA8)),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF2B5BA8)),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _postListing() async {
    if (_titleController.text.trim().isEmpty) {
      _showSnack('Please enter a title for your listing.');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      await FirebaseFirestore.instance.collection('sales').add({
        'title':       _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'tags':        _tagsController.text.trim(),
        'datetime':    '${_dateController.text.trim()} ${_timeController.text.trim()}'.trim(),
        'address':     _locationController.text.trim(),
        'price':       _priceController.text.trim(),
        'condition':   _conditionController.text.trim(),
        'distance':    'Nearby',
        'sellerId':    uid,
        'hasImage':    _pickedImage != null,
        'createdAt':   FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnack('Failed to post listing. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.chevron_left, color: Colors.black54, size: 20),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Post your Yard sale item',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF2B5BA8),
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Create a Listing',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormLabel(label: 'Title'),
                    _BlueBorderField(controller: _titleController),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(child: _BlueBorderField(hint: 'Time',    suffixIcon: Icons.hourglass_empty_outlined,   controller: _timeController)),
                        const SizedBox(width: 8),
                        Expanded(child: _BlueBorderField(hint: 'Date',    suffixIcon: Icons.calendar_month_outlined,    controller: _dateController)),
                        const SizedBox(width: 8),
                        Expanded(child: _BlueBorderField(hint: '\$ Price',                                              controller: _priceController, keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(flex: 3, child: _BlueBorderField(hint: 'Location',  suffixIcon: Icons.location_on_outlined, controller: _locationController)),
                        const SizedBox(width: 8),
                        Expanded(flex: 2, child: _BlueBorderField(hint: 'Condition',                                        controller: _conditionController)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Image upload — integrated with image_picker
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        width: double.infinity,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _pickedImage != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.file(_pickedImage!, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _pickedImage = null),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey.shade500),
                                  const SizedBox(height: 8),
                                  Text('Tap to add photo', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                                  Text('Camera or Gallery', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _FormLabel(label: 'Description'),
                    _BlueBorderField(controller: _descriptionController, maxLines: 4),
                    const SizedBox(height: 18),
                    _FormLabel(label: 'Tags'),
                    _BlueBorderField(controller: _tagsController, hint: 'e.g. furniture, electronics'),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Submit button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _postListing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8843A),
                    disabledBackgroundColor: const Color(0xFFE8843A).withOpacity(0.6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Post Listing',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String label;
  const _FormLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
    );
  }
}

class _BlueBorderField extends StatelessWidget {
  final String? hint;
  final TextEditingController controller;
  final int maxLines;
  final IconData? suffixIcon;
  final TextInputType keyboardType;

  const _BlueBorderField({
    this.hint,
    required this.controller,
    this.maxLines = 1,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF2B5BA8), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF2B5BA8), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF2B5BA8), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, color: const Color(0xFF2B5BA8), size: 18)
            : null,
      ),
    );
  }
}
