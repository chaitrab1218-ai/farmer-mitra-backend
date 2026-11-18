import 'package:flutter/material.dart';
import 'admin_page.dart';
import 'auth_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Email Authentication Page — Login & Sign Up
// ─────────────────────────────────────────────────────────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isSignUp = false;
  bool _loading = false;
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();
  final _nameController     = TextEditingController();
  final _phoneController    = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final email    = _emailController.text.trim();
    final password = _passwordController.text;

    String? error;
    if (_isSignUp) {
      error = await NeonAuthService.registerWithEmail(
        email: email,
        password: password,
        displayName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
    } else {
      error = await NeonAuthService.loginWithEmail(
        email: email,
        password: password,
      );
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
    // On success, NeonAuthService notifies listeners and AuthGate automatically switches to MainShell!
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F3),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo & Header
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.eco, size: 70, color: Color(0xFF237A3B)),
                  ),
                ),
                    const SizedBox(height: 8),
                    const Text(
                      'Krushi Mitra',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF237A3B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Farmer Shopping & Price Comparison',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),

                    const SizedBox(height: 24),

                    // Card container
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Tab switch (Login / Sign Up)
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F4EF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(() => _isSignUp = false),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: !_isSignUp ? const Color(0xFF237A3B) : Colors.transparent,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            'Login',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: !_isSignUp ? Colors.white : Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(() => _isSignUp = true),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: _isSignUp ? const Color(0xFF237A3B) : Colors.transparent,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            'Sign Up',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: _isSignUp ? Colors.white : Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Name (Sign Up only)
                              if (_isSignUp) ...[
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Full Name',
                                    prefixIcon: const Icon(Icons.person_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    isDense: true,
                                  ),
                                  validator: (v) {
                                    if (_isSignUp && (v == null || v.trim().isEmpty)) {
                                      return 'Please enter your name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                // Phone (Sign Up only)
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                  decoration: InputDecoration(
                                    labelText: 'Mobile Number',
                                    prefixText: '+91 ',
                                    prefixIcon: const Icon(Icons.phone_android_outlined),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    counterText: '',
                                    isDense: true,
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],

                              // Email Input
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email Address',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  isDense: true,
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!v.contains('@') || !v.contains('.')) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 14),

                              // Password Input
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  isDense: true,
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (v.length < 4) {
                                    return 'Password must be at least 4 characters';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 22),

                              // Primary Submit Button
                              SizedBox(
                                height: 48,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF237A3B),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _loading ? null : _submit,
                                  child: _loading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          _isSignUp ? 'Create Account' : 'Log In',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Switch mode text link
                              Center(
                                child: TextButton(
                                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                                  child: Text(
                                    _isSignUp
                                        ? 'Already have an account? Log In'
                                        : "Don't have an account? Sign Up",
                                    style: const TextStyle(color: Color(0xFF237A3B), fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── Admin Login Ghost Button ──────────────────────────────
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black54,
                        side: BorderSide(color: Colors.grey.shade400, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminLoginPage()),
                      ),
                      child: const Text(
                        'Admin Login',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
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
