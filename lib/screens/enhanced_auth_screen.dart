import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/enhanced_auth_service.dart';
import '../services/data_management_service.dart';
import 'main_screen.dart';
import 'fix_auth_screen.dart';

class EnhancedAuthScreen extends StatefulWidget {
  const EnhancedAuthScreen({super.key});

  @override
  State<EnhancedAuthScreen> createState() => _EnhancedAuthScreenState();
}

class _EnhancedAuthScreenState extends State<EnhancedAuthScreen> {
  final EnhancedAuthService _authService = EnhancedAuthService();
  final DataManagementService _dataService = DataManagementService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _recoveryEmailController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3949AB), Color(0xFF2196F3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildLogo(),
                const SizedBox(height: 30),
                _buildTitle(),
                const SizedBox(height: 40),
                _buildLoginForm(),
                const SizedBox(height: 20),
                _buildActionButtons(),
                const SizedBox(height: 30),
                _buildSecurityFeatures(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(
        Icons.school,
        size: 50,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTitle() {
    return const Column(
      children: [
        Text(
          'Digital Grade Report Locker',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Enhanced Security & Data Management',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            obscureText: _obscurePassword,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showPasswordResetDialog,
              child: const Text('Forgot Password?'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3949AB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _showAccountRecoveryDialog,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Account Recovery',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _showDataManagementDialog,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Data Tools',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FixAuthScreen()),
            );
          },
          child: const Text(
            'Admin: Fix Student Auth',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityFeatures() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'Security Features',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSecurityFeature('Email Verification', Icons.verified_user),
              _buildSecurityFeature('Password Reset', Icons.lock_reset),
              _buildSecurityFeature('MFA Support', Icons.security),
              _buildSecurityFeature('Data Backup', Icons.backup),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFeature(String title, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _login() async {
    final input = _emailController.text.trim();
    final password = _passwordController.text;

    if (input.isEmpty || password.isEmpty) {
      _showError('Please enter email/student ID and password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Log login attempt
      await _authService.logSecurityEvent('login_attempt', {
        'email': input,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Login via AppProvider (which uses AuthService)
      // AuthService.login() handles both student_id and email lookup
      final provider = Provider.of<AppProvider>(context, listen: false);
      final success = await provider.login(input, password, false);

      if (success) {
        _showSuccess('Login successful!');

        // Navigate to main screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      } else {
        _showError('Invalid email/student ID or password');
      }
    } catch (e) {
      _showError('Login failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showPasswordResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email address to receive a password reset link.'),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _authService.sendPasswordResetEmail(_emailController.text);
              if (success) {
                _showSuccess('Password reset email sent!');
              } else {
                _showError('Failed to send password reset email');
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  void _showAccountRecoveryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Recovery'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email address to recover your account.'),
            const SizedBox(height: 16),
            TextField(
              controller: _recoveryEmailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _authService.initiateAccountRecovery(_recoveryEmailController.text);
              if (success) {
                _showSuccess('Recovery email sent!');
              } else {
                _showError('Failed to send recovery email');
              }
            },
            child: const Text('Recover Account'),
          ),
        ],
      ),
    );
  }

  void _showDataManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Management'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.cloud_upload, color: Colors.blue),
              title: const Text('Migrate to Firestore'),
              subtitle: const Text('Move local data to cloud'),
              onTap: () {
                Navigator.pop(context);
                _migrateToFirestore();
              },
            ),
            ListTile(
              leading: const Icon(Icons.backup, color: Colors.green),
              title: const Text('Create Backup'),
              subtitle: const Text('Backup all data'),
              onTap: () {
                Navigator.pop(context);
                _createBackup();
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download, color: Colors.orange),
              title: const Text('Export Data'),
              subtitle: const Text('Export in various formats'),
              onTap: () {
                Navigator.pop(context);
                _exportData();
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.purple),
              title: const Text('Validate Data'),
              subtitle: const Text('Check data integrity'),
              onTap: () {
                Navigator.pop(context);
                _validateData();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _migrateToFirestore() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Migrating data...'),
          ],
        ),
      ),
    );

    try {
      final result = await _dataService.migrateToFirestore();
      Navigator.pop(context); // Close loading dialog
      
      if (result['status'] == 'completed') {
        _showSuccess('Data migration completed successfully!');
      } else {
        _showError('Migration failed: ${result['error']}');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showError('Migration error: $e');
    }
  }

  Future<void> _createBackup() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Creating backup...'),
          ],
        ),
      ),
    );

    try {
      final result = await _dataService.createBackup();
      Navigator.pop(context); // Close loading dialog
      
      if (result['status'] == 'success') {
        _showSuccess('Backup created successfully!');
      } else {
        _showError('Backup failed: ${result['error']}');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showError('Backup error: $e');
    }
  }

  Future<void> _exportData() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('JSON Format'),
              subtitle: const Text('Structured data format'),
              onTap: () => _performExport('json'),
            ),
            ListTile(
              title: const Text('CSV Format'),
              subtitle: const Text('Spreadsheet compatible'),
              onTap: () => _performExport('csv'),
            ),
            ListTile(
              title: const Text('XML Format'),
              subtitle: const Text('Web-compatible format'),
              onTap: () => _performExport('xml'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _performExport(String format) async {
    Navigator.pop(context); // Close format selection dialog
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Exporting data...'),
          ],
        ),
      ),
    );

    try {
      final result = await _dataService.exportData(format: format);
      Navigator.pop(context); // Close loading dialog
      
      if (result['status'] == 'success') {
        _showSuccess('Data exported successfully as ${format.toUpperCase()}!');
      } else {
        _showError('Export failed: ${result['error']}');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showError('Export error: $e');
    }
  }

  Future<void> _validateData() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Validating data...'),
          ],
        ),
      ),
    );

    try {
      final result = await _dataService.validateData();
      Navigator.pop(context); // Close loading dialog
      
      if (result['status'] == 'completed') {
        _showValidationResults(result);
      } else {
        _showError('Validation failed: ${result['error']}');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showError('Validation error: $e');
    }
  }

  void _showValidationResults(Map<String, dynamic> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Validation Results'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildValidationSection('Students', results['students']),
              _buildValidationSection('Grades', results['grades']),
              _buildValidationSection('Courses', results['courses']),
              _buildValidationSection('Registrations', results['registrations']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationSection(String title, Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('Total: ${data['total'] ?? 0}'),
          Text('Valid: ${data['valid'] ?? 0}'),
          Text('Invalid: ${data['invalid'] ?? 0}'),
          if (data['errors'] != null && (data['errors'] as List).isNotEmpty)
            ...data['errors'].take(3).map<Widget>((error) => Text(
              '• $error',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            )),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
