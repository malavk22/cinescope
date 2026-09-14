import 'package:flutter/material.dart';

// App bar button that jumps straight back to the home screen from anywhere.
class HomeButton extends StatelessWidget {
  const HomeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.home),
      tooltip: "Home",
      onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
    );
  }
}
