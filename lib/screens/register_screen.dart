import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // GlobalKey tracks the overall state of the form fields
  final _formKey = GlobalKey<FormState>();

  // Controllers capture text input and store them in memory
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    // Crucial step: Freeing memory controllers when the user leaves the screen
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    // Intercepts the submit action.
    // It loops through all validators below. If any return text, it blocks processing.
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registering profile...')));

      // Navigate to your landing page or homepage route here
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter name';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter email';

    final trimmed = value.trim();

    // Checks if '@' is present, and ensures it's not the first or last character
    if (!trimmed.contains('@')) {
      return 'Email must contain @';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Enter a valid email';
    }
    return null; // Returning null flags the field as clean and valid
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF8FAFC,
      ), // Modern slate-50 background tint
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey, // Binds this widget group to our validation key
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateName,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType
                      .emailAddress, // Brings up an optimized email keyboard layout
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true, // Conceals password typing fields securely
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF6366F1,
                    ), // Modern indigo accent
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Create account',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text(
                    'Already have an account? Login',
                    style: TextStyle(color: Color(0xFF6366F1)),
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
