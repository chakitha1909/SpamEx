import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'inbox_screen.dart';
import 'home_screen.dart'; // ✅ Login screen
import 'package:spamex/services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  void _signUp() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showMessage("⚠️ All fields are required.");
      return;
    }

    if (password.length < 6) {
      _showMessage("⚠️ Password must be at least 6 characters long.");
      return;
    }

    if (password != confirmPassword) {
      _showMessage("⚠️ Passwords do not match.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = await _authService.signUpWithEmailAndPassword(email, password);

      if (user != null) {
        print("✅ Signup successful! Redirecting...");
        _showMessage("🎉 Signup successful!");

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => InboxScreen()), // ✅ Redirects to Inbox
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      print("🔥 Firebase Auth Error: ${e.code} - ${e.message}");

      if (e.code == 'email-already-in-use') {
        _showMessage("⚠️ This email is already registered. Try logging in.");
      } else if (e.code == 'weak-password') {
        _showMessage("⚠️ Password is too weak. Use a stronger one.");
      } else {
        _showMessage("⚠️ Signup failed: ${e.message}");
      }
    } catch (e) {
      print("🔥 Unexpected Error: $e");
      _showMessage("⚠️ An unexpected error occurred.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Create an Account",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                const SizedBox(height: 10),
                const Text("Sign up to get started", style: TextStyle(fontSize: 16)),
                const SizedBox(height: 30),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.orange)
                    : ElevatedButton(
                        onPressed: _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        ),
                        child: const Text("Sign Up", style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => HomeScreen()), // ✅ Redirects to Login
                        );
                      },
                      child: const Text("Sign In", style: TextStyle(color: Colors.orange)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
