import 'package:flutter/material.dart';
import 'screens/sync_page.dart';
import 'screens/settings_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Data Sync',
      theme: ThemeData(
        // ← Helles Design
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF19abb3)),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Color(0xffeff5f5),
          selectedItemColor: Color(0xff01696e),
        ),
      ),

      darkTheme: ThemeData(
        // ← Dunkles Design
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF19abb3), brightness: Brightness.dark),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Color(0xff151c1d),
          selectedItemColor: Color(0xff19abb3),
        ),
      ),
      themeMode: ThemeMode.system,
      // ← Eigene Property, NEBEN theme/darkTheme
      home: const MyHomePage(title: 'Data Sync'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.inversePrimary, title: Text(widget.title)),
      /*
       * IndexedStack zeigt immer nur die Seite an, deren Index mit _selectedIndex übereinstimmt.
       * Im Gegensatz zu einer if-Abfrage werden aber ALLE Seiten im Speicher gehalten –
       * auch die gerade nicht sichtbaren. Das hat einen wichtigen Vorteil:
       */
      body: IndexedStack(index: _selectedIndex, children: [SyncPage(), SettingsPage()]),
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          
          currentIndex: _selectedIndex, // Markiert den aktuell aktiven Tab
          onTap: (index) {
            // Wird aufgerufen wenn ein Tab angetippt wird
            setState(() {
              // Löst einen UI-Neuaufbau aus
              _selectedIndex = index; // Speichert welcher Tab aktiv ist
            });
          },
          items: const [
            // Liste der sichtbaren Tab-Einträge
            BottomNavigationBarItem(
              icon: Icon(Icons.sync), // Icon des ersten Tabs
              label: 'Sync', // Beschriftung des ersten Tabs
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings), // Icon des zweiten Tabs
              label: 'Einstellungen', // Beschriftung des zweiten Tabs
            ),
          ],
        ),
      ),
    );
  }
}
