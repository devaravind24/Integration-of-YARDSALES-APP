import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_textfield.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _conditionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _conditionController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _postListing() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title'),
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('User not logged in');
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final sellerName =
          userDoc.data()?['displayName'] ??
          user.displayName ??
          user.email ??
          'Seller';

      final saleRef =
          FirebaseFirestore.instance.collection('sales').doc();

      await saleRef.set({
        'saleId': saleRef.id,

        'title': _titleController.text.trim(),
        'datetime': _dateController.text.trim(),
        'price': _priceController.text.trim(),
        'address': _locationController.text.trim(),
        'condition': _conditionController.text.trim(),
        'description': _descriptionController.text.trim(),
        'tags': _tagsController.text.trim(),

        // Chat-related fields
        'sellerId': user.uid,
        'sellerName': sellerName,

        'createdAt': FieldValue.serverTimestamp(),
      });

      _titleController.clear();
      _dateController.clear();
      _priceController.clear();
      _locationController.clear();
      _conditionController.clear();
      _descriptionController.clear();
      _tagsController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing posted successfully'),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post listing: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _spacing() => const SizedBox(height: 15);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Listing'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CustomTextField(
              hint: 'Title',
              controller: _titleController,
            ),

            _spacing(),

            CustomTextField(
              hint: 'Date & Time',
              controller: _dateController,
            ),

            _spacing(),

            CustomTextField(
              hint: 'Price',
              controller: _priceController,
            ),

            _spacing(),

            CustomTextField(
              hint: 'Location',
              controller: _locationController,
            ),

            _spacing(),

            CustomTextField(
              hint: 'Condition',
              controller: _conditionController,
            ),

            _spacing(),

            CustomTextField(
              hint: 'Description',
              controller: _descriptionController,
            ),

            _spacing(),

            CustomTextField(
              hint: 'Tags',
              controller: _tagsController,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : CustomButton(
                title: 'Post Listing',
                onTap: _postListing,
              ),
      ),
    );
  }
}