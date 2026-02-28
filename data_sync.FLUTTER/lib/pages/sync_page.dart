import 'package:flutter/material.dart';

class SyncPage extends StatelessWidget {
  const SyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 30),

          // Log-Textbox
          SizedBox(height: 15),
          Text('Log: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 15),  // ← Abstand zwischen Label und Box

          Expanded(
              child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,  // ← 80% der Bildschirmbreite
                  margin: EdgeInsets.all(10),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]  // Dunkler Modus: dunkelgrau
                        : Colors.grey[100] , // Heller Modus: sehr helles Grau
                  ),
                  child: SingleChildScrollView(
                      child: Text('Log content...')
                  )
              )
          ),

          // Syncaction Buttons
          Row(
              mainAxisAlignment: MainAxisAlignment.center,  // ← Zentriert die Buttons horizontal
              children: [
                ElevatedButton(onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(120, 40),  // ← width, height
                      backgroundColor: Theme.of(context).brightness == Brightness.dark
                          ? Color(0xff01696e)  // Dark Mode Farbe
                          : Color(0xffeff5f5), // Light Mode Farbe
                      foregroundColor: Theme.of(context).brightness == Brightness.dark
                          ? Color(0xff151c1d)  // Dark Mode Farbe
                          : Color(0xff01696e), // Light Mode Farbe
                    ),
                    child: Text('Download')),

                SizedBox(width: 15),  // ← Abstand zwischen Buttons

                ElevatedButton(onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(120, 40),  // ← width, height
                      backgroundColor: Theme.of(context).brightness == Brightness.dark
                          ? Color(0xff01696e)  // Dark Mode Farbe
                          : Color(0xffeff5f5), // Light Mode Farbe
                      foregroundColor: Theme.of(context).brightness == Brightness.dark
                          ? Color(0xff151c1d)  // Dark Mode Farbe
                          : Color(0xff01696e), // Light Mode Farbe
                    ),
                    child: Text('Upload')),

                SizedBox(width: 15),

                ElevatedButton(onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(120, 40),  // ← width, height
                      backgroundColor: Theme.of(context).brightness == Brightness.dark
                          ? Color(0xff01696e)  // Dark Mode Farbe
                          : Color(0xffeff5f5), // Light Mode Farbe
                      foregroundColor: Theme.of(context).brightness == Brightness.dark
                          ? Color(0xff151c1d)  // Dark Mode Farbe
                          : Color(0xff01696e), // Light Mode Farbe
                    ),
                    child: Text('Sync')),
              ]
          ),
          SizedBox(height: 60)
        ]
    );
  }
}
