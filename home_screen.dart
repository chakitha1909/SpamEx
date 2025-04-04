import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spamex/services/auth_service.dart';
import 'inbox_screen.dart';
import 'signup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Listen to authentication state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const InboxScreen()),
        );
      }
    });
  }

  void _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage("⚠️ Please enter both email and password");
      return;
    }

    try {
      User? user = await _authService.signInWithEmailAndPassword(email, password);

      if (user != null) {
        print("✅ Login Successful: ${user.email}");
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const InboxScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      print("🔥 Firebase Auth Error: ${e.code} - ${e.message}");

      if (e.code == 'user-not-found') {
        _showRegisterAlert();
      } else if (e.code == 'wrong-password') {
        _showMessage("⚠️ Incorrect password. Please try again.");
      } else {
        _showMessage("⚠️ ${e.message}");
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showRegisterAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("User Not Found"),
        content: const Text("This email is not registered. Would you like to sign up?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SignupScreen()),
              );
            },
            child: const Text("Sign Up"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Welcome Back!",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orange),
              ),
              const SizedBox(height: 10),
              const Text("Sign in to your account", style: TextStyle(fontSize: 16)),
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
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text("Forgot Password?", style: TextStyle(color: Colors.orange)),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: const Text("Login", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              const SizedBox(height: 10),
              TextButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SignupScreen()),
    );
  },
  child: RichText(
    text: TextSpan(
      text: "Don't have an account? ",
      style: TextStyle(color: Colors.black), // "Don't have an account?" in black
      children: [
        TextSpan(
          text: "Register",
          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold), // "Register" in orange
        ),
      ],
    ),
  ),
),

            ],
          ),
        ),
      ),
    );
  }
}
