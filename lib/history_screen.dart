import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_button.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<String> history = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() async {
    final prefs = await SharedPreferences.getInstance();
    String user = prefs.getString("currentUser")!;
    history = prefs.getStringList("${user}_history") ?? [];
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search History"),
        actions: const [HomeButton()],
      ),
      body: ListView.builder(
        itemCount: history.length,
        itemBuilder: (_, i) {
          return ListTile(
            title: Text(history[i]),
            trailing: const Icon(Icons.search),
            onTap: () {
              Navigator.pop(context, history[i]);
            },
          );
        },
      ),
    );
  }
}
