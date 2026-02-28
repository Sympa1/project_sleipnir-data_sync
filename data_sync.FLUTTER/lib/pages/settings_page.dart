import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 30),
          // Button zum setzen des Sync-Verzeichnis
          ElevatedButton(onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme
                    .of(context)
                    .brightness == Brightness.dark
                    ? Color(0xff01696e) // Dark Mode Farbe
                    : Color(0xffeff5f5), // Light Mode Farbe
                foregroundColor: Theme
                    .of(context)
                    .brightness == Brightness.dark
                    ? Color(0xff151c1d) // Dark Mode Farbe
                    : Color(0xff01696e), // Light Mode Farbe
              ),
              child: Text('Sync-Verzeichnis auswählen')),

          ElevatedButton(onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme
                    .of(context)
                    .brightness == Brightness.dark
                    ? Color(0xff01696e) // Dark Mode Farbe
                    : Color(0xffeff5f5), // Light Mode Farbe
                foregroundColor: Theme
                    .of(context)
                    .brightness == Brightness.dark
                    ? Color(0xff151c1d) // Dark Mode Farbe
                    : Color(0xff01696e), // Light Mode Farbe
              ),
              child: Text('API-URL eingeben')),
          SizedBox(height: 60)
        ]
    );
  }
}