import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // Upload image to Firebase Storage
  Future<String?> uploadImage({
    required File imageFile,
    required String studentId,
    String folder = 'student_profiles',
  }) async {
    try {
      // Create a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${studentId}_$timestamp.jpg';
      
      // Create reference to the file location
      final ref = _storage.ref().child('$folder/$fileName');
      
      // Upload the file
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      
      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  // Capture image from camera
  Future<File?> captureImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (image != null) {
        return File(image.path);
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
      // Extract the file path from the URL
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  // Get image size in MB
  double getImageSizeInMB(File imageFile) {
    final sizeInBytes = imageFile.lengthSync();
    return sizeInBytes / (1024 * 1024);
  }

  // Check if image size is within limits (max 5MB)
  bool isImageSizeValid(File imageFile, {double maxSizeMB = 5.0}) {
    return getImageSizeInMB(imageFile) <= maxSizeMB;
  }

  // Compress image if needed
  Future<File?> compressImageIfNeeded(File imageFile) async {
    final sizeMB = getImageSizeInMB(imageFile);
    
    if (sizeMB <= 2.0) {
      // Image is already small enough
      return imageFile;
    }
    
    // For simplicity, we'll just return the original file
    // In a real app, you would use an image compression library
    print('Image size: ${sizeMB.toStringAsFixed(2)} MB - consider compressing');
    return imageFile;
  }

  // Upload profile picture with validation
  Future<String?> uploadProfilePicture({
    required File imageFile,
    required String studentId,
  }) async {
    try {
      // Validate image size
      if (!isImageSizeValid(imageFile)) {
        throw Exception('Image size exceeds 5MB limit');
      }
      
      // Compress if needed
      final compressedImage = await compressImageIfNeeded(imageFile);
      if (compressedImage == null) {
        throw Exception('Failed to process image');
      }
      
      // Upload to Firebase Storage
      final downloadUrl = await uploadImage(
        imageFile: compressedImage,
        studentId: studentId,
        folder: 'profile_pictures',
      );
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      rethrow;
    }
  }

  // Get image URL for student
  Future<String?> getStudentProfileImage(String studentId) async {
    try {
      // List files in the student's profile folder
      final listResult = await _storage
          .ref()
          .child('profile_pictures')
          .listAll();

      // Find the most recent image for this student
      for (final ref in listResult.items) {
        if (ref.name.contains(studentId)) {
          return await ref.getDownloadURL();
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting student profile image: $e');
      return null;
    }
  }

  // Update profile picture (delete old, upload new)
  Future<String?> updateProfilePicture({
    required File newImageFile,
    required String studentId,
    String? oldImageUrl,
  }) async {
    try {
      // Delete old image if exists
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        await deleteImage(oldImageUrl);
      }
      
      // Upload new image
      return await uploadProfilePicture(
        imageFile: newImageFile,
        studentId: studentId,
      );
    } catch (e) {
      print('Error updating profile picture: $e');
      rethrow;
    }
  }
}