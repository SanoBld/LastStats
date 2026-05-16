import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/setup_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs    = await SharedPreferences.getInstance();
  final username = prefs.getString('ls_username') ?? '';
  final apiKey   = prefs.getString('ls_apikey')   ?? '';

  runApp(LastStatsApp(
    username: username,
    apiKey:   apiKey,
  ));
}

class LastStatsApp extends StatelessWidget {
  final String username;
  final String apiKey;

  const LastStatsApp({
    super.key,
    required this.username,
    required this.apiKey,
  });

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF7C3AED);

    return MaterialApp(
      title: 'LastStats',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: (username.isNotEmpty && apiKey.isNotEmpty)
          ? HomeScreen(username: username, apiKey: apiKey)
          : const SetupScreen(),
    );
  }
}
