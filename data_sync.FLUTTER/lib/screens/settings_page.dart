import 'package:flutter/material.dart';


/// Die Settings-Seite der App
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 30),
        Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('📁 Sync-Verzeichnis'),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                            ? Color(0xff01696e)
                            : Color(0xffeff5f5),
                        foregroundColor: Theme.of(context).brightness == Brightness.dark
                            ? Color(0xff151c1d)
                            : Color(0xff01696e),
                      ),
                      child: Text('Ändern'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 30),
        Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('🌐 API-URL'),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                            ? Color(0xff01696e)
                            : Color(0xffeff5f5),
                        foregroundColor: Theme.of(context).brightness == Brightness.dark
                            ? Color(0xff151c1d)
                            : Color(0xff01696e),
                      ),
                      child: Text('Ändern'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 60),
      ],
    );
  }
}
