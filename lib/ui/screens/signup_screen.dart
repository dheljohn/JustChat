import 'package:flutter/material.dart';
import 'package:messenger_app/services/auth_services.dart';
import 'package:messenger_app/ui/screens/home_sreen.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;

  void _signUpWithEmail() async {
    setState(() => _loading = true);
    final user = await _authService.signUpWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _nameController.text.trim(),
    );
    setState(() => _loading = false);

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Sign-Up failed")));
    }
  }

  void _signUpWithGoogle() async {
    setState(() => _loading = true);
    final user = await _authService.signUpWithGoogle();
    setState(() => _loading = false);

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Google Sign-Up failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Acc")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child:
            _loading
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(labelText: "Full Name"),
                      ),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(labelText: "Email"),
                      ),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(labelText: "Passw"),
                        obscureText: true,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _signUpWithEmail,
                        child: Text("Sign Up with Email"),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _signUpWithGoogle,
                        child: Text("Sign Up with Google"),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
