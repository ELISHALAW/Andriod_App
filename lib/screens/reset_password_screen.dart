import 'package:flutter/material.dart';
import '../services/database_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _isSubmitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      final token = args['token']?.toString() ?? '';
      if (token.isNotEmpty && _tokenCtrl.text.isEmpty) {
        _tokenCtrl.text = token;
      }
    }
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  String? _validateToken(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter reset token';
    if (value.trim().length < 20) return 'Token format is invalid';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter new password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Confirm your new password';
    if (value != _newPasswordCtrl.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final result = await DatabaseService.resetPassword(
      token: _tokenCtrl.text.trim(),
      newPassword: _newPasswordCtrl.text,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    final success = result['success'] == true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ?? 'Password reset failed.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (!success) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Enter the token and your new password.'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tokenCtrl,
                  decoration: const InputDecoration(labelText: 'Reset Token'),
                  validator: _validateToken,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newPasswordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New Password'),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                  ),
                  validator: _validateConfirmPassword,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: Text(
                    _isSubmitting ? 'Resetting...' : 'Set New Password',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
