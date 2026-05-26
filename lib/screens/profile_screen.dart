import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_provider.dart';
import '../constants/theme_constants.dart';
import '../services/image_upload_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  String? _selectedSex;
  String? _photoUrl;
  Uint8List? _profileImageBytes;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _isChangingPassword = false;
  final _picker = ImagePicker();
  final _imageUploadService = ImageUploadService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _loadData() {
    final s = Provider.of<AppProvider>(context, listen: false).currentStudent;
    if (s != null) {
      _nameController.text = s.fullName;
      _phoneController.text = s.phone ?? '';
      _ageController.text = s.age?.toString() ?? '';
      _selectedSex = s.sex;
      _photoUrl = s.photoUrl;
    }
  }

  Future<void> _takeCameraPhoto() async {
    try {
      final img = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (img != null) {
        final bytes = await img.readAsBytes();
        setState(() => _profileImageBytes = bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera is not available. Try the gallery instead.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final img = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (img != null) {
        final bytes = await img.readAsBytes();
        setState(() => _profileImageBytes = bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to open gallery. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Change Photo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppColors.info),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Uses device camera'),
                onTap: () {
                  Navigator.pop(context);
                  _takeCameraPhoto();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: AppColors.success),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Browse photo library'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final p = Provider.of<AppProvider>(context, listen: false);
      final studentId = p.currentStudent?.studentId;
      String? finalPhotoUrl = _photoUrl;

        // Step 1: Upload new image if one was picked
        if (_profileImageBytes != null && studentId != null) {
          final uploadedUrl = await _imageUploadService.uploadImageBytes(
            imageBytes: _profileImageBytes!,
            studentId: studentId,
          );
          if (uploadedUrl == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Image upload failed. Please try again.'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            setState(() => _isSaving = false);
            return;
          }
          finalPhotoUrl = uploadedUrl;
          // Update local state so the UI reflects the new photo immediately
          _photoUrl = uploadedUrl;
        }

        // Step 2: Save profile data to Firestore
        await p.updateStudentProfile(
          fullName: _nameController.text.trim(),
          sex: _selectedSex,
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          age: _ageController.text.trim().isEmpty
              ? null
              : int.tryParse(_ageController.text.trim()),
          photoUrl: finalPhotoUrl,
        );

        // Step 3: Clear local state on success
        _profileImageBytes = null;
        if (!mounted) return;
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    final current = _currentPasswordController.text.trim();
    final newPw = _newPasswordController.text.trim();
    if (current.isEmpty || newPw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both password fields'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    if (newPw.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password must be at least 6 characters'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    setState(() => _isChangingPassword = true);
    try {
      final p = Provider.of<AppProvider>(context, listen: false);
      final ok = await p.authService.changePassword(current, newPw);
      if (!mounted) return;
      if (ok) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Current password is incorrect'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password change failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final student = provider.currentStudent;
        return Container(
          color: AppColors.background,
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: AppColors.primary,
                child: Row(
                  children: [
                    const Icon(Icons.person_rounded,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Student Profile',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (!_isEditing)
                      GestureDetector(
                        onTap: () => setState(() => _isEditing = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_rounded,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text('Edit',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: AppTheme.whiteCard,
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: _isEditing ? _showPicker : null,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey.shade100,
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: 3,
                                    ),
                                  ),
                                  child: _profileImageBytes != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(50),
                                          child: Image.memory(
                                            _profileImageBytes!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                const Icon(Icons.person,
                                                    size: 40,
                                                    color: Colors.grey),
                                          ),
                                        )
                                      : _photoUrl != null &&
                                              _photoUrl!.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                              child: Image.network(
                                                _photoUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) =>
                                                    const Icon(Icons.person,
                                                        size: 40,
                                                        color: Colors.grey),
                                              ),
                                            )
                                          : const Icon(Icons.person_rounded,
                                              size: 44, color: Colors.grey),
                                ),
                              ),
                              if (_isEditing)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 8),
                                  child: Text('Tap to change photo',
                                      style: AppTextStyles.caption),
                                ),
                              const SizedBox(height: 16),
                              if (!_isEditing) ...[
                                Text(
                                  student?.fullName ?? 'Student Name',
                                  style: AppTextStyles.h2,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ID: ${student?.studentId ?? 'N/A'}',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                              if (_isEditing)
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Full Name',
                                    prefixIcon: const Icon(
                                        Icons.person_outline,
                                        color: AppColors.primary),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Required'
                                          : null,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: AppTheme.whiteCard,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Academic Information',
                                  style: AppTextStyles.h3),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _academicItem('GPA',
                                      provider.selectedGPA.toStringAsFixed(2),
                                      Icons.grade_rounded, AppColors.success),
                                  const SizedBox(width: 10),
                                  _academicItem(
                                      'CGPA',
                                      provider.cgpa.toStringAsFixed(2),
                                      Icons.school_rounded,
                                      AppColors.info),
                                  const SizedBox(width: 10),
                                  _academicItem(
                                      'Courses',
                                      '${provider.grades.length}',
                                      Icons.book_rounded,
                                      AppColors.warning),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded,
                                        color: AppColors.primary, size: 20),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Current Semester',
                                            style: AppTextStyles.caption),
                                        Text(
                                          provider.selectedSemester
                                                  .isNotEmpty
                                              ? provider.selectedSemester
                                              : 'Not Selected',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: AppTheme.whiteCard,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Personal Information',
                                  style: AppTextStyles.h3),
                              const SizedBox(height: 16),
                              if (!_isEditing) ...[
                                _infoRow('Phone',
                                    student?.phone ?? 'Not provided'),
                                _infoRow(
                                    'Age', student?.age?.toString() ?? '-'),
                                _infoRow(
                                    'Gender', student?.sex ?? 'Not provided'),
                              ],
                              if (_isEditing) ...[
                                TextFormField(
                                  controller: _phoneController,
                                  decoration: InputDecoration(
                                    labelText: 'Phone',
                                    prefixIcon: const Icon(Icons.phone_rounded,
                                        color: AppColors.primary),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _ageController,
                                  decoration: InputDecoration(
                                    labelText: 'Age',
                                    prefixIcon: const Icon(Icons.cake_rounded,
                                        color: AppColors.primary),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 14),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedSex,
                                  decoration: InputDecoration(
                                    labelText: 'Gender',
                                    prefixIcon: const Icon(
                                        Icons.person_outline_rounded,
                                        color: AppColors.primary),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  items: ['Male', 'Female', 'Other']
                                      .map((g) => DropdownMenuItem(
                                          value: g, child: Text(g)))
                                      .toList(),
                                  onChanged:
                                      (v) => setState(() => _selectedSex = v),
                                ),
                                const SizedBox(height: 20),
                                const Divider(),
                                const SizedBox(height: 8),
                                const Text('Change Password',
                                    style: AppTextStyles.h3),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _currentPasswordController,
                                  obscureText: _obscureCurrent,
                                  decoration: InputDecoration(
                                    labelText: 'Current Password',
                                    prefixIcon: const Icon(Icons.lock_outline,
                                        color: AppColors.primary),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscureCurrent
                                          ? Icons.visibility_off
                                          : Icons.visibility),
                                      onPressed: () => setState(
                                          () => _obscureCurrent = !_obscureCurrent),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _newPasswordController,
                                  obscureText: _obscureNew,
                                  decoration: InputDecoration(
                                    labelText: 'New Password',
                                    prefixIcon: const Icon(Icons.lock_rounded,
                                        color: AppColors.primary),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscureNew
                                          ? Icons.visibility_off
                                          : Icons.visibility),
                                      onPressed: () => setState(
                                          () => _obscureNew = !_obscureNew),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                ),
                                if (_isChangingPassword)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: _changePassword,
                                        icon: const Icon(Icons.key_rounded,
                                            size: 18),
                                        label:
                                            const Text('Update Password'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          setState(() => _isEditing = false);
                                          _loadData();
                                        },
                                        style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 16),
                                          side: const BorderSide(
                                              color: AppColors.primary),
                                        ),
                                        child: const Text('Cancel',
                                            style: TextStyle(
                                                color: AppColors.primary)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _isSaving ? null : _save,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 16),
                                          elevation: 0,
                                        ),
                                        child: _isSaving
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Text('Save Updates'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _academicItem(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(title,
                style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
