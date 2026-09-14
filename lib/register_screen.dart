import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();
  final userController = TextEditingController();
  final passController = TextEditingController();
  final confirmController = TextEditingController();
  bool hidePassword = true;

  @override
  void dispose() {
    userController.dispose();
    passController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final username = userController.text.trim();

    if (prefs.containsKey("user_$username")) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("That username is already taken")),
      );
      return;
    }

    await prefs.setString(
      "user_$username",
      hashPassword(username, passController.text.trim()),
    );
    if (!mounted) return;
    Navigator.pop(context, username);
  }

  InputDecoration field(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create account")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Card(
              color: Colors.black.withOpacity(0.8),
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 30,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.person_add_alt_1,
                        size: 64,
                        color: Colors.white,
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "Join CineScope",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 25),

                      TextFormField(
                        controller: userController,
                        decoration: field("Username", Icons.person),
                        style: const TextStyle(color: Colors.white),
                        validator: (v) => (v == null || v.trim().length < 3)
                            ? "Username must be at least 3 characters"
                            : null,
                      ),

                      const SizedBox(height: 15),

                      TextFormField(
                        controller: passController,
                        obscureText: hidePassword,
                        decoration: field("Password", Icons.lock).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              hidePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white70,
                            ),
                            onPressed: () =>
                                setState(() => hidePassword = !hidePassword),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (v) => (v == null || v.trim().length < 6)
                            ? "Password must be at least 6 characters"
                            : null,
                      ),

                      const SizedBox(height: 15),

                      TextFormField(
                        controller: confirmController,
                        obscureText: hidePassword,
                        decoration: field("Confirm password", Icons.lock_outline),
                        style: const TextStyle(color: Colors.white),
                        validator: (v) =>
                            (v ?? "").trim() != passController.text.trim()
                                ? "Passwords don't match"
                                : null,
                      ),

                      const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: register,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Create account"),
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Already have an account? Log in",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
