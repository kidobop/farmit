import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _authenticate() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (_isLogin) {
        // Login
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        // Signup
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (mounted) {
          // Redirect to onboarding after signup
          Navigator.of(context).pushReplacementNamed('/onboarding',
              arguments: userCredential.user!.uid);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? "An error occurred"),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with modern typography
                Text(
                  _isLogin ? "Welcome Back" : "Create Account",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isLogin
                      ? "Sign in to continue"
                      : "Create an account to get started",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.black54,
                      ),
                ),
                const SizedBox(height: 40),

                // Email Input with Material 3 style
                _buildTextField(
                  controller: _emailController,
                  label: "Email",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // Password Input with visibility toggle
                _buildTextField(
                  controller: _passwordController,
                  label: "Password",
                  icon: Icons.lock_outline,
                  obscureText: !_isPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Forgot Password (only for Login mode)
                if (_isLogin)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Implement forgot password functionality
                      },
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Submit Button with loading state
                SizedBox(
                  width: double.infinity,
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator.adaptive())
                      : FilledButton(
                          onPressed: _authenticate,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _isLogin ? "Login" : "Sign Up",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                ),
                const SizedBox(height: 24),

                // Toggle between Login and Signup
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                      });
                    },
                    child: Text(
                      _isLogin
                          ? "Don't have an account? Sign Up"
                          : "Already have an account? Login",
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                // Bottom Doodle Icons
                const SizedBox(height: 40),
                _buildBottomDoodles(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Bottom Doodle Icons
  Widget _buildBottomDoodles() {
    return SizedBox(
      width: double.infinity,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Farming Icons
          Positioned(
            left: 20,
            bottom: 0,
            child: _buildDoodleIcon(
              icon: Icons.agriculture_outlined,
              color: Colors.green.shade200,
              rotation: -0.2,
            ),
          ),
          Positioned(
            left: 80,
            bottom: 20,
            child: _buildDoodleIcon(
              icon: Icons.grass_outlined,
              color: Colors.green.shade300,
              rotation: 0.1,
            ),
          ),

          // E-commerce Icons
          Positioned(
            right: 20,
            bottom: 0,
            child: _buildDoodleIcon(
              icon: Icons.storefront_outlined,
              color: Colors.blue.shade200,
              rotation: 0.2,
            ),
          ),
          Positioned(
            right: 80,
            bottom: 20,
            child: _buildDoodleIcon(
              icon: Icons.shopping_cart_outlined,
              color: Colors.blue.shade300,
              rotation: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  // Doodle Icon Builder
  Widget _buildDoodleIcon({
    required IconData icon,
    required Color color,
    double rotation = 0,
  }) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Icon(
          icon,
          size: 40,
          color: color,
        ),
      ),
    );
  }

  // Custom text field with icon and Material 3 style
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        suffixIcon: suffixIcon,
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade500, width: 2),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
