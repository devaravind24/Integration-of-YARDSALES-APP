import 'package:flutter/material.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_textfield.dart';

class CreateListingScreen extends StatelessWidget {
  const CreateListingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Listing'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: const [
            CustomTextField(hint: 'Title'),
            SizedBox(height: 15),
            CustomTextField(hint: 'Date & Time'),
            SizedBox(height: 15),
            CustomTextField(hint: 'Price'),
            SizedBox(height: 15),
            CustomTextField(hint: 'Location'),
            SizedBox(height: 15),
            CustomTextField(hint: 'Condition'),
            SizedBox(height: 15),
            CustomTextField(hint: 'Description'),
            SizedBox(height: 15),
            CustomTextField(hint: 'Tags'),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: CustomButton(
          title: 'Post Listing',
          onTap: () {},
        ),
      ),
    );
  }
}