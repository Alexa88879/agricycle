// lib/services/storage_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadWasteImage(XFile imageFile, String userId) async {
    try {
      // Create a unique file name using timestamp
      String fileName = 'waste_images/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child(fileName);

      // Upload the file
      UploadTask uploadTask = ref.putFile(File(imageFile.path));

      // Get the download URL
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading waste image: $e');
      return null;
    }
  }
}
