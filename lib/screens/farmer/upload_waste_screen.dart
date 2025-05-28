// lib/screens/farmer/upload_waste_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/waste_item_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/image_input.dart';
import '../../utils/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp
import '../../models/user_model.dart' as AppUserModel;


class UploadWasteScreen extends StatefulWidget {
  const UploadWasteScreen({super.key});

  @override
  State<UploadWasteScreen> createState() => _UploadWasteScreenState();
}

class _UploadWasteScreenState extends State<UploadWasteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cropTypeController = TextEditingController();
  final _wasteTypeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  String? _selectedCropType;
  String? _selectedWasteType;
  String? _selectedUnit;
  XFile? _selectedImage;
  bool _isLoading = false;

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  AppUserModel.AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    _currentUser = await _authService.getCurrentAppUser();
    if (mounted) {
      setState(() {});
    }
  }


  void _handleImageSelected(XFile image) {
    setState(() {
      _selectedImage = image;
    });
  }

  Future<void> _submitWasteItem() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image for the waste item.')),
        );
        return;
      }
      if (_currentUser == null) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in. Please restart the app.')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        // 1. Upload image to Firebase Storage
        String? imageUrl = await _storageService.uploadWasteImage(_selectedImage!, _currentUser!.uid);
        if (imageUrl == null) {
          throw Exception('Image upload failed.');
        }

        // 2. Create WasteItem object
        final wasteItem = WasteItem(
          farmerId: _currentUser!.uid,
          farmerName: _currentUser!.name ?? 'Unknown Farmer',
          cropType: _selectedCropType ?? _cropTypeController.text.trim(),
          wasteType: _selectedWasteType ?? _wasteTypeController.text.trim(),
          quantity: double.parse(_quantityController.text.trim()),
          unit: _selectedUnit!,
          address: _addressController.text.trim(),
          latitude: double.tryParse(_latitudeController.text.trim()) ?? 0.0, // Default if parse fails
          longitude: double.tryParse(_longitudeController.text.trim()) ?? 0.0, // Default if parse fails
          imageUrl: imageUrl,
          postedAt: Timestamp.now(),
          status: 'available',
        );

        // 3. Add WasteItem to Firestore
        await _firestoreService.addWasteItem(wasteItem);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Waste item listed successfully!')),
          );
          Navigator.pop(context); // Go back after successful submission
        }
      } catch (e) {
        print('Error submitting waste item: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to list waste item: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List Agricultural Waste'),
        backgroundColor: kPrimarySwatch.shade500,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Describe Your Waste Item', style: kHeadlineStyle.copyWith(fontSize: 20)),
              const SizedBox(height: kMediumPadding),

              // Crop Type Dropdown or Text Field
              _buildDropdownFormField(
                value: _selectedCropType,
                items: kCommonCropTypes,
                onChanged: (value) => setState(() => _selectedCropType = value),
                labelText: 'Crop Type',
                hintText: 'Select Crop Type',
                controllerForOther: _cropTypeController,
                otherOptionLabel: 'Other Crop Type',
              ),
              const SizedBox(height: kDefaultPadding),

              // Waste Type Dropdown or Text Field
              _buildDropdownFormField(
                value: _selectedWasteType,
                items: kCommonWasteTypes,
                onChanged: (value) => setState(() => _selectedWasteType = value),
                labelText: 'Waste Type',
                hintText: 'Select Waste Type',
                controllerForOther: _wasteTypeController,
                otherOptionLabel: 'Other Waste Type',
              ),
              const SizedBox(height: kDefaultPadding),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      controller: _quantityController,
                      labelText: 'Quantity',
                      hintText: 'e.g., 10, 2.5',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Enter quantity';
                        if (double.tryParse(value) == null) return 'Enter a valid number';
                        if (double.parse(value) <= 0) return 'Quantity must be positive';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: kSmallPadding),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      hint: const Text('Select Unit'),
                      items: kQuantityUnits.map((String unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedUnit = value),
                      validator: (value) => value == null ? 'Select unit' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: kDefaultPadding),

              CustomTextField(
                controller: _addressController,
                labelText: 'Full Address / Landmark',
                hintText: 'Enter detailed address or nearest landmark',
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter address';
                  return null;
                },
              ),
              const SizedBox(height: kDefaultPadding),

              // Row(
              //   children: [
              //     Expanded(
              //       child: CustomTextField(
              //         controller: _latitudeController,
              //         labelText: 'Latitude (Optional)',
              //         hintText: 'e.g., 28.6139',
              //         keyboardType: TextInputType.number,
              //       ),
              //     ),
              //     const SizedBox(width: kSmallPadding),
              //     Expanded(
              //       child: CustomTextField(
              //         controller: _longitudeController,
              //         labelText: 'Longitude (Optional)',
              //         hintText: 'e.g., 77.2090',
              //         keyboardType: TextInputType.number,
              //       ),
              //     ),
              //   ],
              // ),
              // const SizedBox(height: kDefaultPadding),

              Text('Upload Image of Waste', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: kSmallPadding),
              ImageInput(onImageSelected: _handleImageSelected),
              const SizedBox(height: kMediumPadding),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(
                      text: 'List My Waste',
                      icon: Icons.cloud_upload_outlined,
                      onPressed: _submitWasteItem,
                    ),
              const SizedBox(height: kMediumPadding),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownFormField({
      String? value,
      required List<String> items,
      required ValueChanged<String?> onChanged,
      required String labelText,
      required String hintText,
      required TextEditingController controllerForOther,
      required String otherOptionLabel,
    }) {
      bool isOtherSelected = value == 'Other';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: items.contains(value) ? value : null, // Ensure value is in items or null
            decoration: InputDecoration(
              labelText: labelText,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
              fillColor: Colors.white,
              filled: true,
            ),
            hint: Text(hintText),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: (val) {
               onChanged(val);
               if (val != 'Other') {
                 controllerForOther.clear(); // Clear "Other" text field if a predefined option is chosen
               }
            },
            validator: (val) {
              if (val == null) return 'Please select or specify $labelText';
              if (val == 'Other' && controllerForOther.text.trim().isEmpty) {
                return 'Please specify the $otherOptionLabel';
              }
              return null;
            },
          ),
          if (isOtherSelected) ...[
            const SizedBox(height: kSmallPadding),
            CustomTextField(
              controller: controllerForOther,
              labelText: otherOptionLabel,
              hintText: 'Specify $otherOptionLabel',
              validator: (val) {
                if (isOtherSelected && (val == null || val.isEmpty)) {
                  return 'Please specify the $otherOptionLabel';
                }
                return null;
              },
            ),
          ],
        ],
      );
    }


}
