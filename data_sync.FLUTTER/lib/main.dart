import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Data_Sync',
        theme: ThemeData(           // ← Helles Design
          colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF19abb3)),
        ),

        darkTheme: ThemeData(       // ← Dunkles Design
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color(0xFF19abb3),
            brightness: Brightness.dark,
          ),
        ),
        themeMode: ThemeMode.system,  // ← Eigene Property, NEBEN theme/darkTheme
      home: const MyHomePage(title: 'Data_Sync'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Button zum setzen des Sync-Verzeichnis
            ElevatedButton(onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Color(0xff01696e)  // Dark Mode Farbe
                      : Color(0xffeff5f5), // Light Mode Farbe
                  foregroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Color(0xff2b2929)  // Dark Mode Farbe
                      : Color(0xff01696e), // Light Mode Farbe
                ),
                child: Text('Sync-Verzeichnis auswählen')),

            // Log-Textbox
            Expanded(child: Text('Log')),

            // Syncaction Buttons
            ElevatedButton(onPressed: () {}, child: Text('Download')),
            ElevatedButton(onPressed: () {}, child: Text('Upload')),
            ElevatedButton(onPressed: () {}, child: Text('Sync')),

          ]
      ),
    );
  }
}
