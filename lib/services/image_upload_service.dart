import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // Upload image bytes (works on all platforms including web)
  Future<String?> uploadImageBytes({
    required Uint8List imageBytes,
    required String studentId,
    String folder = 'profile_pictures',
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${studentId}_$timestamp.jpg';
      final ref = _storage.ref().child('$folder/$fileName');
      final uploadTask = ref.putData(imageBytes);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Pick image from gallery (returns bytes for web compatibility)
  Future<Uint8List?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (image != null) {
        return await image.readAsBytes();
      }
      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  // Capture image from camera (returns bytes for web compatibility)
  Future<Uint8List?> captureImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (image != null) {
        return await image.readAsBytes();
      }
      return null;
    } catch (e) {
      print('Error capturing image from camera: $e');
      return null;
    }
  }

  // Delete image from Firebase Storage
  Future<bool> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  // Upload profile picture with validation
  Future<String?> uploadProfilePicture({
    required Uint8List imageBytes,
    required String studentId,
  }) async {
    try {
      final downloadUrl = await uploadImageBytes(
        imageBytes: imageBytes,
        studentId: studentId,
        folder: 'profile_pictures',
      );
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      rethrow;
    }
  }

  // Get profile image URL for student from Firestore (via photoUrl field)
  // The photoUrl is stored on the student document after upload

  // Update profile picture (delete old, upload new)
  Future<String?> updateProfilePicture({
    required Uint8List imageBytes,
    required String studentId,
    String? oldImageUrl,
  }) async {
    try {
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        await deleteImage(oldImageUrl);
      }
      return await uploadProfilePicture(
        imageBytes: imageBytes,
        studentId: studentId,
      );
    } catch (e) {
      print('Error updating profile picture: $e');
      rethrow;
    }
  }
}