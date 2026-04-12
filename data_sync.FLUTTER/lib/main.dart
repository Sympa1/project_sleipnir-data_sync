import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/sync_page.dart';
import 'screens/settings_page.dart';
import 'theme/app_colors.dart';


/// Einstiegspunkt der App
void main() {
  runApp(const MyApp());
}

/// Die Haupt-Applikation
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Data Sync',

      // Helles Design mit Inter-Schrift
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        textTheme: GoogleFonts.interTextTheme(),
        useMaterial3: true,
      ),

      // Dunkles Design mit Inter-Schrift
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        useMaterial3: true,
      ),

      themeMode: ThemeMode.system,
      home: const MyHomePage(),
    );
  }
}

/// Haupt-Navigation der App mit Bottom-Bar
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  // Titel-Texte passend zum aktiven Tab
  static const _titles = ['Sync', 'Einstellungen'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        centerTitle: false,
      ),

      /*
       * IndexedStack zeigt immer nur die Seite an, deren Index mit _selectedIndex übereinstimmt.
       * Im Gegensatz zu einer if-Abfrage werden aber ALLE Seiten im Speicher gehalten –
       * auch die gerade nicht sichtbaren. Das verhindert, dass der State verloren geht.
       */
      body: IndexedStack(
        index: _selectedIndex,
        children: const [SyncPage(), SettingsPage()],
      ),

      // NavigationBar ist der moderne M3-Ersatz für BottomNavigationBar
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sync_outlined),
            selectedIcon: Icon(Icons.sync),
            label: 'Sync',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Einstellungen',
          ),
        ],
      ),
    );
  }
}
