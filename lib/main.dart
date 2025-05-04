import 'package:calculationcrypto/screens/calculator_screen.dart';
import 'package:calculationcrypto/screens/history_screen.dart';
import 'package:calculationcrypto/screens/notes_screen.dart';
import 'package:calculationcrypto/screens/splash_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ProfitCalculatorApp());
}

class ProfitCalculatorApp extends StatelessWidget {
  const ProfitCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.green[700],
        ),
      ),
      home: FutureBuilder(
        future: Future.delayed(const Duration(seconds: 2)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SplashScreen();
          } else {
            return MainScreen(); // Your existing main screen
          }
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    CalculatorScreen(),
    HistoryScreen(),
    NotesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'Calculator',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note),
            label: 'Notes',
          ),
        ],
        selectedItemColor: Colors.green[700],
      ),
    );
  }
}
