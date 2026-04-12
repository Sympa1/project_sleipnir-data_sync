import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sync-Seite mit Download-, Upload- und Sync-Aktionen
class SyncPage extends StatelessWidget {
  const SyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Log-Bereich Überschrift
          Row(
            children: [
              Icon(Icons.terminal_outlined, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Log',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Log-Ausgabebereich
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Text(
                  'Bereit.',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Aktions-Buttons
          Row(
            children: [
              // FilledButton.tonal = weniger betont (sekundäre Aktion)
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () {},
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.download_outlined, size: 18),
                      SizedBox(width: 6),
                      Text('Download'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () {},
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_outlined, size: 18),
                      SizedBox(width: 6),
                      Text('Upload'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // FilledButton = primäre Aktion (stärker hervorgehoben)
              Expanded(
                child: FilledButton(
                  onPressed: () {},
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sync, size: 18),
                      SizedBox(width: 6),
                      Text('Sync'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
