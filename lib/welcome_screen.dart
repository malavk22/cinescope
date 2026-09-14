import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  const WelcomeScreen({super.key, required this.toggleTheme});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  Future<void> login() async {
    final prefs = await SharedPreferences.getInstance();

    final username = userController.text.trim();
    final password = passController.text.trim();

    if (username.isEmpty || password.isEmpty) return;

    final savedPassword = prefs.getString("user_$username");

    if (savedPassword == password) {
      prefs.setString("currentUser", username);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(toggleTheme: widget.toggleTheme),
        ),
      );
    } else {
      showMessage("Invalid credentials");
    }
  }

  Future<void> register() async {
    final prefs = await SharedPreferences.getInstance();

    final username = userController.text.trim();
    final password = passController.text.trim();

    if (username.isEmpty || password.isEmpty) return;

    if (prefs.containsKey("user_$username")) {
      showMessage("User already exists");
      return;
    }

    prefs.setString("user_$username", password);
    showMessage("User registered! Now login");
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Movie Browser App"),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            tooltip: "Toggle Theme",
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 450, // 🔥 Keeps the card nicely centered & compact
            ),
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
                child: Column(
                  children: [
                    const Icon(
                      Icons.movie_creation_outlined,
                      size: 70,
                      color: Colors.white,
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Welcome",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 25),

                    TextField(
                      controller: userController,
                      decoration: InputDecoration(
                        labelText: "Username",
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: passController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Login"),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextButton(
                      onPressed: register,
                      child: const Text(
                        "New user? Register",
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
    );
  }
}
