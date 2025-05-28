// lib/widgets/image_input.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/constants.dart';

class ImageInput extends StatefulWidget {
  final Function(XFile) onImageSelected;

  const ImageInput({super.key, required this.onImageSelected});

  @override
  State<ImageInput> createState() => _ImageInputState();
}

class _ImageInputState extends State<ImageInput> {
  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Compress image slightly
        maxWidth: 1000, // Limit image width
      );
      if (image != null) {
        setState(() {
          _pickedImage = image;
        });
        widget.onImageSelected(image);
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kDefaultPadding)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Gallery'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: kPrimarySwatch.shade200, width: 1),
          ),
          child: _pickedImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(11.0), // slightly less than container
                  child: Image.file(
                    File(_pickedImage!.path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_outlined, size: 50, color: Colors.grey[500]),
                      const SizedBox(height: kSmallPadding),
                      Text('No image selected', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: kSmallPadding),
        ElevatedButton.icon(
          icon: const Icon(Icons.add_a_photo_outlined),
          label: const Text('Choose Image'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimarySwatch.shade100,
            foregroundColor: kPrimarySwatch.shade700,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          onPressed: () => _showImageSourceActionSheet(context),
        ),
      ],
    );
  }
}
